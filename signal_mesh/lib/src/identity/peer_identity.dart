import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nadz/nadz.dart';

import '../dht/node_id.dart';

/// A peer's public identity in the mesh network.
typedef PeerIdentity = ({
  NodeId nodeId,
  SimplePublicKey identityKey,
  String? phoneNumber,
  Uint8List? phoneAttestation,
  DateTime createdAt,
});

/// Creates a PeerIdentity from a public key.
Future<Result<PeerIdentity, String>> createPeerIdentity({
  required SimplePublicKey identityKey,
  String? phoneNumber,
  Uint8List? phoneAttestation,
}) async {
  final nodeIdResult = await nodeIdFromPublicKey(identityKey);
  return switch (nodeIdResult) {
    Success(:final value) => Success((
        nodeId: value,
        identityKey: identityKey,
        phoneNumber: phoneNumber,
        phoneAttestation: phoneAttestation,
        createdAt: DateTime.now(),
      )),
    Error(:final error) => Error(error),
  };
}

/// Verifies that a NodeId matches the claimed identity key.
Future<bool> verifyIdentity(PeerIdentity identity) async {
  final derivedResult = await nodeIdFromPublicKey(identity.identityKey);
  return switch (derivedResult) {
    Success(:final value) => _nodeIdsEqual(value, identity.nodeId),
    Error() => false,
  };
}

/// Serializes a PeerIdentity to a map for DHT storage or transport.
Map<String, Object?> serializeIdentity(PeerIdentity identity) => {
  'nodeId': nodeIdToHex(identity.nodeId),
  'identityKey': identity.identityKey.bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(),
  'phoneNumber': identity.phoneNumber,
  'phoneAttestation': identity.phoneAttestation != null
      ? identity.phoneAttestation!
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
      : null,
  'createdAt': identity.createdAt.toIso8601String(),
};

/// Deserializes a PeerIdentity from a map.
Result<PeerIdentity, String> deserializeIdentity(Map<String, Object?> data) {
  try {
    final nodeIdHex = data['nodeId'];
    final identityKeyHex = data['identityKey'];

    if (nodeIdHex is! String || identityKeyHex is! String) {
      return Error('Missing required identity fields');
    }

    final nodeIdBytes = _hexToBytes(nodeIdHex);
    final identityKeyBytes = _hexToBytes(identityKeyHex);

    final nodeIdResult = nodeIdFromBytes(nodeIdBytes);
    if (nodeIdResult case Error(:final error)) return Error(error);

    final phoneNumber = data['phoneNumber'];
    final phoneAttHex = data['phoneAttestation'];

    return Success((
      nodeId: (nodeIdResult as Success<NodeId, String>).value,
      identityKey: SimplePublicKey(
        identityKeyBytes,
        type: KeyPairType.x25519,
      ),
      phoneNumber: phoneNumber is String ? phoneNumber : null,
      phoneAttestation:
          phoneAttHex is String ? _hexToBytes(phoneAttHex) : null,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
    ));
  } on Object catch (e) {
    return Error('Failed to deserialize identity: $e');
  }
}

Uint8List _hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

bool _nodeIdsEqual(NodeId a, NodeId b) {
  for (var i = 0; i < 32; i++) {
    if (a.bytes[i] != b.bytes[i]) return false;
  }
  return true;
}
