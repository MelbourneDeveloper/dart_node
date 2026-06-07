import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nadz/nadz.dart';

/// 256-bit node identifier for Kademlia DHT.
/// Derived from SHA-256 hash of the peer's public identity key.
typedef NodeId = ({Uint8List bytes});

/// Creates a NodeId from raw bytes. Must be exactly 32 bytes.
Result<NodeId, String> nodeIdFromBytes(Uint8List bytes) =>
    bytes.length == 32
        ? Success((bytes: bytes))
        : Error('NodeId must be 32 bytes, got ${bytes.length}');

/// Derives a NodeId from a public key by hashing it with SHA-256.
Future<Result<NodeId, String>> nodeIdFromPublicKey(
  SimplePublicKey publicKey,
) async {
  try {
    final hash = await Sha256().hash(publicKey.bytes);
    return Success((bytes: Uint8List.fromList(hash.bytes)));
  } on Object catch (e) {
    return Error('Failed to derive NodeId: $e');
  }
}

/// Generates a random NodeId (for testing or bootstrap).
Result<NodeId, String> nodeIdRandom() {
  final rng = Random.secure();
  final bytes = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    bytes[i] = rng.nextInt(256);
  }
  return Success((bytes: bytes));
}

/// XOR distance between two NodeIds (Kademlia distance metric).
Uint8List xorDistance(NodeId a, NodeId b) {
  final result = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    result[i] = a.bytes[i] ^ b.bytes[i];
  }
  return result;
}

/// Returns the index of the most significant bit in the XOR distance.
/// This determines which k-bucket a node belongs to.
/// Returns -1 if the nodes are identical.
int bucketIndex(NodeId a, NodeId b) {
  final dist = xorDistance(a, b);
  for (var i = 0; i < 32; i++) {
    if (dist[i] != 0) {
      // Find the highest set bit in this byte
      var byte = dist[i];
      var bit = 7;
      while (byte & 0x80 == 0) {
        byte <<= 1;
        bit--;
      }
      return (31 - i) * 8 + bit;
    }
  }
  return -1; // identical nodes
}

/// Compares distances: returns true if a is closer to target than b.
bool isCloser(NodeId target, NodeId a, NodeId b) {
  final distA = xorDistance(target, a);
  final distB = xorDistance(target, b);
  for (var i = 0; i < 32; i++) {
    if (distA[i] < distB[i]) return true;
    if (distA[i] > distB[i]) return false;
  }
  return false; // equal distance
}

/// Hex string representation of a NodeId (for debugging/display).
String nodeIdToHex(NodeId id) =>
    id.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Short hex representation (first 8 chars).
String nodeIdShort(NodeId id) => nodeIdToHex(id).substring(0, 8);
