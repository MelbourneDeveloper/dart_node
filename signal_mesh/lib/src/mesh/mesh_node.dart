import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nadz/nadz.dart';

import '../crypto/key_pair.dart';
import '../dht/kademlia.dart';
import '../dht/node_id.dart';
import '../dht/routing_table.dart';
import '../identity/peer_identity.dart';
import '../protocol/message.dart';
import '../protocol/session.dart';
import '../transport/peer_connection.dart';
import '../transport/transport.dart';
import 'store_forward.dart';

/// Complete state of a mesh node.
typedef MeshNodeState = ({
  PeerIdentity identity,
  KeyPairBundle keyBundle,
  KademliaState dht,
  SessionStore sessions,
  MessageQueue messageQueue,
  Set<String> seenMessageIds,
});

/// Configuration for creating a mesh node.
typedef MeshNodeConfig = ({
  String? phoneNumber,
  int dhtK,
  int maxQueueSize,
  int maxTtlSeconds,
  List<PeerAddress> bootstrapPeers,
});

/// Default mesh node configuration.
MeshNodeConfig defaultConfig({
  String? phoneNumber,
  List<PeerAddress> bootstrapPeers = const [],
}) => (
  phoneNumber: phoneNumber,
  dhtK: defaultK,
  maxQueueSize: 1000,
  maxTtlSeconds: 86400 * 7,
  bootstrapPeers: bootstrapPeers,
);

/// A mesh node combining DHT, sessions, transport, and store-forward.
typedef MeshNode = ({
  MeshNodeState state,
  Transport transport,
  PeerAddress localAddress,
  Result<void, String> Function(PeerAddress address) connectToPeer,
  Future<Result<void, String>> Function(
    NodeId recipient,
    Uint8List plaintext,
  ) sendMessage,
  void Function(
    void Function(NodeId sender, Uint8List plaintext) handler,
  ) onMessage,
  Result<void, String> Function() shutdown,
  MeshNodeState Function() getState,
});

/// Creates and initializes a new mesh node.
Future<Result<MeshNode, String>> createMeshNode({
  required PeerAddress localAddress,
  required Transport transport,
  MeshNodeConfig? config,
}) async {
  final cfg = config ?? defaultConfig();

  // Generate key bundle
  final bundleResult = await generateKeyBundle();
  if (bundleResult case Error(:final error)) return Error(error);
  final keyBundle = (bundleResult as Success<KeyPairBundle, String>).value;

  // Create identity
  final identityResult = await createPeerIdentity(
    identityKey: keyBundle.identityPublic,
    phoneNumber: cfg.phoneNumber,
  );
  if (identityResult case Error(:final error)) return Error(error);
  final identity = (identityResult as Success<PeerIdentity, String>).value;

  // Initialize state
  var state = (
    identity: identity,
    keyBundle: keyBundle,
    dht: createKademliaState(identity.nodeId, k: cfg.dhtK),
    sessions: createSessionStore(),
    messageQueue: createMessageQueue(
      maxQueueSize: cfg.maxQueueSize,
      maxTtlSeconds: cfg.maxTtlSeconds,
    ),
    seenMessageIds: <String>{},
  );

  final messageHandlers = <void Function(NodeId, Uint8List)>[];

  // Handle incoming transport events
  transport.onEvent((event) {
    switch (event.event) {
      case TransportEvent.message:
        if (event.data == null) return;
        _handleIncomingMessage(state, event, messageHandlers);
      case TransportEvent.connected:
      case TransportEvent.disconnected:
      case TransportEvent.error:
        break;
    }
  });

  MeshNodeState getState() => state;

  Result<void, String> connectToPeer(PeerAddress address) {
    final connectResult = transport.connect(address);
    // Since connect returns a Future, we handle it synchronously here
    // by just initiating the connection
    return Success(null);
  }

  Future<Result<void, String>> sendMessage(
    NodeId recipient,
    Uint8List plaintext,
  ) async {
    // Find the recipient in the DHT
    final closest = findClosest(state.dht.routingTable, recipient);
    if (closest.isEmpty) {
      // Queue for store-and-forward
      final wireMsg = createWireMessage(
        type: MessageType.chat,
        sender: state.identity.nodeId,
        recipient: recipient,
        payload: {'data': plaintext.toList()},
      );
      final queueResult =
          enqueueMessage(state.messageQueue, recipient, wireMsg);
      if (queueResult case Success(:final value)) {
        state = (
          identity: state.identity,
          keyBundle: state.keyBundle,
          dht: state.dht,
          sessions: state.sessions,
          messageQueue: value,
          seenMessageIds: state.seenMessageIds,
        );
      }
      return Error('Peer not found, message queued for delivery');
    }

    // Check if we have an active session
    final session = getSession(state.sessions, recipient);
    if (session == null) {
      // Queue message until session is established
      final wireMsg = createWireMessage(
        type: MessageType.chat,
        sender: state.identity.nodeId,
        recipient: recipient,
        payload: {'data': plaintext.toList()},
      );
      final queueResult =
          enqueueMessage(state.messageQueue, recipient, wireMsg);
      if (queueResult case Success(:final value)) {
        state = (
          identity: state.identity,
          keyBundle: state.keyBundle,
          dht: state.dht,
          sessions: state.sessions,
          messageQueue: value,
          seenMessageIds: state.seenMessageIds,
        );
      }
      return Error('No session, message queued');
    }

    // Encrypt and send
    final encryptResult = await encryptSessionMessage(session, plaintext);
    if (encryptResult case Error(:final error)) return Error(error);
    final (updatedSession, ratchetMsg) =
        (encryptResult as Success).value as (Session, dynamic);

    final wireMsg = createWireMessage(
      type: MessageType.chat,
      sender: state.identity.nodeId,
      recipient: recipient,
      payload: {
        'dhPublic': ratchetMsg.dhPublic.bytes.toList(),
        'messageNumber': ratchetMsg.messageNumber,
        'previousChainLength': ratchetMsg.previousChainLength,
        'ciphertext': ratchetMsg.ciphertext.toList(),
        'nonce': ratchetMsg.nonce.toList(),
      },
    );

    final data = serializeWireMessage(wireMsg);

    // Send to the closest known peer (direct or via relay)
    final target = closest.first;
    final sendResult = await transport.send(
      (host: target.address, port: target.port),
      data,
    );

    return sendResult;
  }

  void onMessage(void Function(NodeId sender, Uint8List plaintext) handler) {
    messageHandlers.add(handler);
  }

  Result<void, String> shutdown() {
    transport.close();
    return Success(null);
  }

  return Success((
    state: state,
    transport: transport,
    localAddress: localAddress,
    connectToPeer: connectToPeer,
    sendMessage: sendMessage,
    onMessage: onMessage,
    shutdown: shutdown,
    getState: getState,
  ));
}

void _handleIncomingMessage(
  MeshNodeState state,
  TransportEventData event,
  List<void Function(NodeId, Uint8List)> handlers,
) {
  final parseResult = deserializeWireMessage(event.data ?? Uint8List(0));
  if (parseResult case Error()) return;

  final wireMsg = (parseResult as Success<WireMessage, String>).value;

  // Deduplicate
  if (state.seenMessageIds.contains(wireMsg.id)) return;
  state.seenMessageIds.add(wireMsg.id);

  // Cap seen IDs set size
  if (state.seenMessageIds.length > 10000) {
    final toRemove =
        state.seenMessageIds.take(state.seenMessageIds.length - 5000);
    state.seenMessageIds.removeAll(toRemove);
  }

  switch (wireMsg.type) {
    case MessageType.chat:
      final data = wireMsg.payload['data'];
      if (data is List) {
        final bytes = Uint8List.fromList(data.cast<int>());
        for (final handler in handlers) {
          handler(wireMsg.sender, bytes);
        }
      }

    case MessageType.findNode:
      final request = (
        sender: wireMsg.sender,
        target: wireMsg.sender, // simplified
        senderAddress: event.peer.host,
        senderPort: event.peer.port,
      );
      handleFindNode(state.dht, request);

    case MessageType.ping:
    case MessageType.pong:
    case MessageType.findNodeResponse:
    case MessageType.findValue:
    case MessageType.findValueResponse:
    case MessageType.store:
    case MessageType.preKeyBundle:
    case MessageType.sessionInit:
    case MessageType.sessionAck:
    case MessageType.storeForward:
    case MessageType.storeForwardAck:
    case MessageType.identityAnnounce:
    case MessageType.identityQuery:
    case MessageType.identityResponse:
      break; // TODO: implement remaining handlers
  }
}

/// Bootstraps a mesh node by connecting to known peers and performing
/// initial DHT lookups to populate the routing table.
Future<Result<void, String>> bootstrap(
  MeshNode node,
  List<PeerAddress> bootstrapPeers,
) async {
  for (final peer in bootstrapPeers) {
    node.connectToPeer(peer);
  }

  // Perform a self-lookup to populate nearby buckets
  final state = node.getState();
  await iterativeFindNode(
    state.dht,
    state.identity.nodeId,
    sendFindNode: (target, request) async {
      final wireMsg = createWireMessage(
        type: MessageType.findNode,
        sender: request.sender,
        payload: {'target': nodeIdToHex(request.target)},
      );
      final data = serializeWireMessage(wireMsg);
      await node.transport.send(
        (host: target.address, port: target.port),
        data,
      );
      // In a real implementation, we'd wait for the response
      return null;
    },
  );

  return Success(null);
}
