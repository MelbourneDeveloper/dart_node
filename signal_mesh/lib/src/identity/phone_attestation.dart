import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nadz/nadz.dart';

/// A phone number attestation signed by an attestation node.
///
/// Attestation nodes are lightweight, stateless services that verify
/// phone numbers via SMS and sign credentials. They don't participate
/// in message routing or storage. Anyone can run one.
///
/// The attestation proves: "Phone +X is controlled by public key Y
/// as verified by attestation node Z at time T."
typedef PhoneAttestation = ({
  String phoneNumber,
  SimplePublicKey identityKey,
  SimplePublicKey attestorKey,
  Uint8List signature,
  DateTime attestedAt,
  int ttlSeconds,
});

/// Data that gets signed by the attestation node.
typedef AttestationPayload = ({
  String phoneNumber,
  List<int> identityKeyBytes,
  String attestedAt,
  int ttlSeconds,
});

/// Creates the canonical bytes for an attestation payload (for signing).
Uint8List encodeAttestationPayload(AttestationPayload payload) {
  final parts = [
    'phone:${payload.phoneNumber}',
    'key:${payload.identityKeyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
    'at:${payload.attestedAt}',
    'ttl:${payload.ttlSeconds}',
  ];
  return Uint8List.fromList(parts.join('|').codeUnits);
}

/// Creates a phone attestation (attestation node side).
///
/// The attestation node calls this after verifying the phone number
/// via SMS code.
Future<Result<PhoneAttestation, String>> createAttestation({
  required String phoneNumber,
  required SimplePublicKey identityKey,
  required SimpleKeyPair attestorKeyPair,
  int ttlSeconds = 86400 * 30, // 30 days default
}) async {
  try {
    final ed25519 = Ed25519();
    final now = DateTime.now();

    final payload = (
      phoneNumber: phoneNumber,
      identityKeyBytes: identityKey.bytes,
      attestedAt: now.toIso8601String(),
      ttlSeconds: ttlSeconds,
    );

    final payloadBytes = encodeAttestationPayload(payload);
    final signature = await ed25519.sign(
      payloadBytes,
      keyPair: attestorKeyPair,
    );

    final attestorPublic = await attestorKeyPair.extractPublicKey();

    return Success((
      phoneNumber: phoneNumber,
      identityKey: identityKey,
      attestorKey: attestorPublic,
      signature: Uint8List.fromList(signature.bytes),
      attestedAt: now,
      ttlSeconds: ttlSeconds,
    ));
  } on Object catch (e) {
    return Error('Failed to create attestation: $e');
  }
}

/// Verifies a phone attestation (peer side).
///
/// Checks that:
/// 1. The signature is valid against the attestor's public key
/// 2. The attestation hasn't expired
/// 3. The attestor key is in our trusted set
Future<Result<bool, String>> verifyAttestation({
  required PhoneAttestation attestation,
  required Set<SimplePublicKey> trustedAttestors,
}) async {
  try {
    // Check if attestor is trusted
    final isTrusted = trustedAttestors.any(
      (k) => _keysEqual(k, attestation.attestorKey),
    );
    if (!isTrusted) return Success(false);

    // Check TTL
    final age =
        DateTime.now().difference(attestation.attestedAt).inSeconds;
    if (age > attestation.ttlSeconds) return Success(false);

    // Verify signature
    final ed25519 = Ed25519();
    final payload = (
      phoneNumber: attestation.phoneNumber,
      identityKeyBytes: attestation.identityKey.bytes,
      attestedAt: attestation.attestedAt.toIso8601String(),
      ttlSeconds: attestation.ttlSeconds,
    );
    final payloadBytes = encodeAttestationPayload(payload);

    final sig = Signature(
      attestation.signature,
      publicKey: attestation.attestorKey,
    );

    final isValid = await ed25519.verify(payloadBytes, signature: sig);

    return Success(isValid);
  } on Object catch (e) {
    return Error('Failed to verify attestation: $e');
  }
}

bool _keysEqual(SimplePublicKey a, SimplePublicKey b) {
  if (a.bytes.length != b.bytes.length) return false;
  for (var i = 0; i < a.bytes.length; i++) {
    if (a.bytes[i] != b.bytes[i]) return false;
  }
  return true;
}
