import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:nadz/nadz.dart';

import '../dht/node_id.dart';

/// Wire protocol message types for the mesh network.
enum MessageType {
  /// Kademlia DHT messages
  ping,
  pong,
  findNode,
  findNodeResponse,
  findValue,
  findValueResponse,
  store,

  /// Session establishment (X3DH)
  preKeyBundle,
  sessionInit,
  sessionAck,

  /// Encrypted chat messages (Double Ratchet)
  chat,

  /// Store-and-forward
  storeForward,
  storeForwardAck,

  /// Identity
  identityAnnounce,
  identityQuery,
  identityResponse,
}

/// Wire protocol envelope wrapping all message types.
typedef WireMessage = ({
  String id,
  MessageType type,
  NodeId sender,
  NodeId? recipient,
  Map<String, Object?> payload,
  DateTime timestamp,
  int ttl,
});

/// Creates a new wire message with a unique ID.
WireMessage createWireMessage({
  required MessageType type,
  required NodeId sender,
  NodeId? recipient,
  required Map<String, Object?> payload,
  int ttl = 7,
}) => (
  id: _generateMessageId(),
  type: type,
  sender: sender,
  recipient: recipient,
  payload: payload,
  timestamp: DateTime.now(),
  ttl: ttl,
);

/// Serializes a WireMessage to bytes.
Uint8List serializeWireMessage(WireMessage message) {
  final map = <String, Object?>{
    'id': message.id,
    'type': message.type.name,
    'sender': nodeIdToHex(message.sender),
    'recipient':
        message.recipient != null ? nodeIdToHex(message.recipient!) : null,
    'payload': message.payload,
    'timestamp': message.timestamp.toIso8601String(),
    'ttl': message.ttl,
  };
  return Uint8List.fromList(utf8.encode(jsonEncode(map)));
}

/// Deserializes bytes to a WireMessage.
Result<WireMessage, String> deserializeWireMessage(Uint8List data) {
  try {
    final str = utf8.decode(data);
    final map = jsonDecode(str);
    if (map is! Map<String, Object?>) {
      return Error('Expected JSON object');
    }

    final typeStr = map['type'];
    if (typeStr is! String) return Error('Missing message type');

    final type = MessageType.values.where((t) => t.name == typeStr);
    if (type.isEmpty) return Error('Unknown message type: $typeStr');

    final senderHex = map['sender'];
    if (senderHex is! String) return Error('Missing sender');
    final senderResult = nodeIdFromBytes(_hexToBytes(senderHex));
    if (senderResult case Error(:final error)) return Error(error);

    NodeId? recipient;
    if (map['recipient'] is String) {
      final recResult =
          nodeIdFromBytes(_hexToBytes(map['recipient'] as String));
      if (recResult case Success(:final value)) recipient = value;
    }

    final payload = map['payload'];
    if (payload is! Map<String, Object?>) return Error('Missing payload');

    return Success((
      id: map['id'] as String? ?? _generateMessageId(),
      type: type.first,
      sender: (senderResult as Success<NodeId, String>).value,
      recipient: recipient,
      payload: payload,
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
              DateTime.now(),
      ttl: map['ttl'] as int? ?? 7,
    ));
  } on Object catch (e) {
    return Error('Failed to deserialize wire message: $e');
  }
}

String _generateMessageId() {
  final rng = Random.secure();
  final bytes = List.generate(16, (_) => rng.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

Uint8List _hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}
