import 'dart:convert';
import 'dart:typed_data';

import 'package:nadz/nadz.dart';

import 'transport.dart';

/// A WebSocket-based transport implementation for P2P connections.
/// Uses ws (Node.js WebSocket) under the hood via dart_node_ws.
///
/// Each peer runs a WebSocket server and connects to other peers'
/// servers. Messages are length-prefixed binary frames.

/// In-memory transport for testing and local development.
/// Simulates network connections between peers in the same process.
typedef InMemoryTransportState = ({
  PeerAddress localAddress,
  Map<String, List<void Function(TransportEventData)>> eventHandlers,
  Set<String> connected,
});

String _addressKey(PeerAddress addr) => '${addr.host}:${addr.port}';

/// Registry of in-memory transports for local peer simulation.
final Map<String, InMemoryTransportState> _registry = {};

/// Creates an in-memory transport (for testing).
Transport createInMemoryTransport(PeerAddress localAddress) {
  final state = (
    localAddress: localAddress,
    eventHandlers: <String, List<void Function(TransportEventData)>>{},
    connected: <String>{},
  );
  _registry[_addressKey(localAddress)] = state;

  return (
    connect: (address) async => _imConnect(state, address),
    send: (address, data) async => _imSend(state, address, data),
    disconnect: (address) => _imDisconnect(state, address),
    onEvent: (handler) => _imOnEvent(state, handler),
    close: () => _imClose(state),
    isConnected: (address) => state.connected.contains(_addressKey(address)),
    connectedPeers: () => _imConnectedPeers(state),
  );
}

Result<void, String> _imConnect(
  InMemoryTransportState state,
  PeerAddress address,
) {
  final key = _addressKey(address);
  final remote = _registry[key];
  if (remote == null) return Error('No peer at $key');

  state.connected.add(key);

  // Notify remote of our connection
  final localKey = _addressKey(state.localAddress);
  remote.connected.add(localKey);

  _emitEvent(state, (
    event: TransportEvent.connected,
    peer: address,
    data: null,
    error: null,
  ));
  _emitEvent(remote, (
    event: TransportEvent.connected,
    peer: state.localAddress,
    data: null,
    error: null,
  ));

  return Success(null);
}

Result<void, String> _imSend(
  InMemoryTransportState state,
  PeerAddress address,
  Uint8List data,
) {
  final key = _addressKey(address);
  if (!state.connected.contains(key)) return Error('Not connected to $key');

  final remote = _registry[key];
  if (remote == null) return Error('Peer $key no longer available');

  _emitEvent(remote, (
    event: TransportEvent.message,
    peer: state.localAddress,
    data: data,
    error: null,
  ));

  return Success(null);
}

Result<void, String> _imDisconnect(
  InMemoryTransportState state,
  PeerAddress address,
) {
  final key = _addressKey(address);
  state.connected.remove(key);

  final remote = _registry[key];
  if (remote != null) {
    remote.connected.remove(_addressKey(state.localAddress));
    _emitEvent(remote, (
      event: TransportEvent.disconnected,
      peer: state.localAddress,
      data: null,
      error: null,
    ));
  }

  _emitEvent(state, (
    event: TransportEvent.disconnected,
    peer: address,
    data: null,
    error: null,
  ));

  return Success(null);
}

void _imOnEvent(
  InMemoryTransportState state,
  void Function(TransportEventData) handler,
) {
  final key = _addressKey(state.localAddress);
  state.eventHandlers.putIfAbsent(key, () => []);
  state.eventHandlers[key]?.add(handler);
}

Result<void, String> _imClose(InMemoryTransportState state) {
  final localKey = _addressKey(state.localAddress);

  // Disconnect all peers
  for (final peerKey in state.connected.toList()) {
    final parts = peerKey.split(':');
    if (parts.length == 2) {
      _imDisconnect(
        state,
        (host: parts[0], port: int.tryParse(parts[1]) ?? 0),
      );
    }
  }

  _registry.remove(localKey);
  return Success(null);
}

List<PeerAddress> _imConnectedPeers(InMemoryTransportState state) =>
    state.connected.map((key) {
      final parts = key.split(':');
      return (host: parts[0], port: int.tryParse(parts[1]) ?? 0);
    }).toList();

void _emitEvent(InMemoryTransportState state, TransportEventData event) {
  final key = _addressKey(state.localAddress);
  final handlers = state.eventHandlers[key];
  if (handlers != null) {
    for (final handler in handlers) {
      handler(event);
    }
  }
}

/// Serializes a message map to bytes for transport.
Uint8List encodeMessage(Map<String, Object?> message) =>
    Uint8List.fromList(utf8.encode(jsonEncode(message)));

/// Deserializes bytes back to a message map.
Result<Map<String, Object?>, String> decodeMessage(Uint8List data) {
  try {
    final str = utf8.decode(data);
    final decoded = jsonDecode(str);
    return switch (decoded) {
      final Map<String, Object?> m => Success(m),
      _ => Error('Expected JSON object, got ${decoded.runtimeType}'),
    };
  } on Object catch (e) {
    return Error('Failed to decode message: $e');
  }
}

/// Clears the in-memory transport registry (for test cleanup).
void clearInMemoryRegistry() => _registry.clear();
