import 'package:nadz/nadz.dart';

import 'node_id.dart';
import 'routing_table.dart';

/// Kademlia RPC message types.
enum KademliaRpc { ping, findNode, findValue, store }

/// A Kademlia lookup request sent to a peer.
typedef FindNodeRequest = ({
  NodeId sender,
  NodeId target,
  String senderAddress,
  int senderPort,
});

/// Response to a FindNode request: the k closest known contacts.
typedef FindNodeResponse = ({
  NodeId sender,
  List<PeerContact> closestNodes,
});

/// Store request: ask a peer to store a key-value pair.
typedef StoreRequest = ({
  NodeId sender,
  NodeId key,
  List<int> value,
  int ttlSeconds,
  String senderAddress,
  int senderPort,
});

/// Value lookup response.
typedef FindValueResponse = ({
  List<int>? value,
  List<PeerContact>? closestNodes,
});

/// DHT storage entry with TTL.
typedef DhtEntry = ({
  List<int> value,
  DateTime storedAt,
  int ttlSeconds,
});

/// State of a Kademlia DHT node.
typedef KademliaState = ({
  RoutingTable routingTable,
  Map<String, DhtEntry> storage,
});

/// Creates initial Kademlia state.
KademliaState createKademliaState(NodeId localId, {int k = defaultK}) => (
  routingTable: createRoutingTable(localId, k: k),
  storage: <String, DhtEntry>{},
);

/// Handles an incoming FIND_NODE request.
/// Returns the k closest contacts we know to the target.
Result<(KademliaState, FindNodeResponse), String> handleFindNode(
  KademliaState state,
  FindNodeRequest request,
) {
  // Add the sender to our routing table (they're alive)
  final contact = (
    nodeId: request.sender,
    address: request.senderAddress,
    port: request.senderPort,
    lastSeen: DateTime.now(),
  );

  final (updatedTable, _) =
      switch (addContact(state.routingTable, contact)) {
    Success(:final value) => value,
    Error() => (state.routingTable, false),
  };

  final closest = findClosest(
    updatedTable,
    request.target,
  );

  final response = (
    sender: state.routingTable.localId,
    closestNodes: closest,
  );

  return Success((
    (routingTable: updatedTable, storage: state.storage),
    response,
  ));
}

/// Handles an incoming STORE request.
Result<KademliaState, String> handleStore(
  KademliaState state,
  StoreRequest request,
) {
  final key = nodeIdToHex(request.key);

  // Add sender to routing table
  final contact = (
    nodeId: request.sender,
    address: request.senderAddress,
    port: request.senderPort,
    lastSeen: DateTime.now(),
  );

  final (updatedTable, _) =
      switch (addContact(state.routingTable, contact)) {
    Success(:final value) => value,
    Error() => (state.routingTable, false),
  };

  final updatedStorage = Map<String, DhtEntry>.from(state.storage);
  updatedStorage[key] = (
    value: request.value,
    storedAt: DateTime.now(),
    ttlSeconds: request.ttlSeconds,
  );

  return Success((routingTable: updatedTable, storage: updatedStorage));
}

/// Handles an incoming FIND_VALUE request.
/// Returns the value if we have it, otherwise closest contacts.
Result<(KademliaState, FindValueResponse), String> handleFindValue(
  KademliaState state,
  NodeId key,
  FindNodeRequest request,
) {
  // Add sender to routing table
  final contact = (
    nodeId: request.sender,
    address: request.senderAddress,
    port: request.senderPort,
    lastSeen: DateTime.now(),
  );

  final (updatedTable, _) =
      switch (addContact(state.routingTable, contact)) {
    Success(:final value) => value,
    Error() => (state.routingTable, false),
  };

  final hexKey = nodeIdToHex(key);
  final entry = state.storage[hexKey];

  // Check TTL
  if (entry != null) {
    final age = DateTime.now().difference(entry.storedAt).inSeconds;
    if (age < entry.ttlSeconds) {
      return Success((
        (routingTable: updatedTable, storage: state.storage),
        (value: entry.value, closestNodes: null),
      ));
    }

    // Expired - remove it
    final updatedStorage = Map<String, DhtEntry>.from(state.storage)
      ..remove(hexKey);
    final closest = findClosest(updatedTable, key);
    return Success((
      (routingTable: updatedTable, storage: updatedStorage),
      (value: null, closestNodes: closest),
    ));
  }

  final closest = findClosest(updatedTable, key);
  return Success((
    (routingTable: updatedTable, storage: state.storage),
    (value: null, closestNodes: closest),
  ));
}

/// Performs an iterative node lookup (the core Kademlia algorithm).
/// Returns the k closest nodes to the target found during the lookup.
///
/// This is the client-side algorithm - it sends FIND_NODE RPCs to
/// progressively closer nodes until no closer nodes are found.
typedef SendFindNode = Future<FindNodeResponse?> Function(
  PeerContact target,
  FindNodeRequest request,
);

Future<List<PeerContact>> iterativeFindNode(
  KademliaState state,
  NodeId target, {
  required SendFindNode sendFindNode,
  int alpha = defaultAlpha,
}) async {
  final localId = state.routingTable.localId;
  final closest = findClosest(state.routingTable, target);

  if (closest.isEmpty) return [];

  // Track queried and seen nodes
  final queried = <String>{};
  var shortlist = List<PeerContact>.from(closest);

  // Iterative lookup: query alpha closest unqueried nodes at a time
  var improved = true;
  while (improved) {
    improved = false;
    final toQuery = shortlist
        .where((c) => !queried.contains(nodeIdToHex(c.nodeId)))
        .take(alpha)
        .toList();

    if (toQuery.isEmpty) break;

    final responses = await Future.wait(
      toQuery.map((contact) async {
        queried.add(nodeIdToHex(contact.nodeId));
        final request = (
          sender: localId,
          target: target,
          senderAddress: '',
          senderPort: 0,
        );
        return sendFindNode(contact, request);
      }),
    );

    for (final response in responses) {
      if (response == null) continue;
      for (final contact in response.closestNodes) {
        final hex = nodeIdToHex(contact.nodeId);
        if (hex == nodeIdToHex(localId)) continue;
        if (!shortlist.any((c) => nodeIdToHex(c.nodeId) == hex)) {
          shortlist.add(contact);
          improved = true;
        }
      }
    }

    // Sort by distance to target
    shortlist.sort((a, b) {
      final dA = xorDistance(target, a.nodeId);
      final dB = xorDistance(target, b.nodeId);
      for (var i = 0; i < 32; i++) {
        if (dA[i] < dB[i]) return -1;
        if (dA[i] > dB[i]) return 1;
      }
      return 0;
    });

    // Keep only the k closest
    if (shortlist.length > state.routingTable.k) {
      shortlist = shortlist.sublist(0, state.routingTable.k);
    }
  }

  return shortlist;
}

/// Cleans expired entries from DHT storage.
KademliaState cleanExpired(KademliaState state) {
  final now = DateTime.now();
  final cleaned = Map<String, DhtEntry>.from(state.storage)
    ..removeWhere((_, entry) {
      final age = now.difference(entry.storedAt).inSeconds;
      return age >= entry.ttlSeconds;
    });

  return (routingTable: state.routingTable, storage: cleaned);
}
