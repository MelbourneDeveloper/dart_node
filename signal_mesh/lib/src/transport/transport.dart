import 'dart:typed_data';

import 'package:nadz/nadz.dart';

/// Network address of a peer.
typedef PeerAddress = ({String host, int port});

/// A raw network message with sender info.
typedef RawMessage = ({
  PeerAddress from,
  Uint8List data,
});

/// Transport event types.
enum TransportEvent { connected, disconnected, message, error }

/// Transport event carrying data about a peer connection event.
typedef TransportEventData = ({
  TransportEvent event,
  PeerAddress peer,
  Uint8List? data,
  String? error,
});

/// Abstract transport interface. Implemented by TCP, WebSocket, WebRTC, etc.
/// Uses typedef records with function fields (no classes/interfaces).
typedef Transport = ({
  Future<Result<void, String>> Function(PeerAddress address) connect,
  Future<Result<void, String>> Function(
    PeerAddress address,
    Uint8List data,
  ) send,
  Result<void, String> Function(PeerAddress address) disconnect,
  void Function(void Function(TransportEventData event) handler) onEvent,
  Result<void, String> Function() close,
  bool Function(PeerAddress address) isConnected,
  List<PeerAddress> Function() connectedPeers,
});
