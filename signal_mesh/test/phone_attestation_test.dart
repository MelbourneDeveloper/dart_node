import 'package:cryptography/cryptography.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

import 'package:signal_mesh/signal_mesh.dart';

void main() {
  test('createAttestation produces valid attestation', () async {
    final identityKp = await X25519().newKeyPair();
    final identityPub = await identityKp.extractPublicKey();
    final attestorKp = await Ed25519().newKeyPair();

    final result = await createAttestation(
      phoneNumber: '+61412345678',
      identityKey: identityPub,
      attestorKeyPair: attestorKp,
    );

    switch (result) {
      case Success(:final value):
        expect(value.phoneNumber, equals('+61412345678'));
        expect(value.signature, isNotEmpty);
        expect(value.ttlSeconds, equals(86400 * 30));
      case Error(:final error):
        fail(error);
    }
  });

  test('verifyAttestation succeeds with trusted attestor', () async {
    final identityKp = await X25519().newKeyPair();
    final identityPub = await identityKp.extractPublicKey();
    final attestorKp = await Ed25519().newKeyPair();
    final attestorPub = await attestorKp.extractPublicKey();

    final createResult = await createAttestation(
      phoneNumber: '+61412345678',
      identityKey: identityPub,
      attestorKeyPair: attestorKp,
    );
    final attestation = switch (createResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    final verifyResult = await verifyAttestation(
      attestation: attestation,
      trustedAttestors: {attestorPub},
    );

    switch (verifyResult) {
      case Success(:final value):
        expect(value, isTrue);
      case Error(:final error):
        fail(error);
    }
  });

  test('verifyAttestation fails with untrusted attestor', () async {
    final identityKp = await X25519().newKeyPair();
    final identityPub = await identityKp.extractPublicKey();
    final attestorKp = await Ed25519().newKeyPair();
    final otherKp = await Ed25519().newKeyPair();
    final otherPub = await otherKp.extractPublicKey();

    final createResult = await createAttestation(
      phoneNumber: '+61412345678',
      identityKey: identityPub,
      attestorKeyPair: attestorKp,
    );
    final attestation = switch (createResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    final verifyResult = await verifyAttestation(
      attestation: attestation,
      trustedAttestors: {otherPub}, // not the actual attestor
    );

    switch (verifyResult) {
      case Success(:final value):
        expect(value, isFalse);
      case Error(:final error):
        fail(error);
    }
  });

  test('verifyAttestation fails when expired', () async {
    final identityKp = await X25519().newKeyPair();
    final identityPub = await identityKp.extractPublicKey();
    final attestorKp = await Ed25519().newKeyPair();
    final attestorPub = await attestorKp.extractPublicKey();

    final createResult = await createAttestation(
      phoneNumber: '+61412345678',
      identityKey: identityPub,
      attestorKeyPair: attestorKp,
      ttlSeconds: 0, // instant expiry
    );
    final attestation = switch (createResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    final verifyResult = await verifyAttestation(
      attestation: attestation,
      trustedAttestors: {attestorPub},
    );

    switch (verifyResult) {
      case Success(:final value):
        expect(value, isFalse);
      case Error(:final error):
        fail(error);
    }
  });

  test('encodeAttestationPayload produces deterministic output', () async {
    final identityKp = await X25519().newKeyPair();
    final identityPub = await identityKp.extractPublicKey();

    final payload = (
      phoneNumber: '+1234567890',
      identityKeyBytes: identityPub.bytes,
      attestedAt: '2025-01-01T00:00:00.000Z',
      ttlSeconds: 3600,
    );

    final encoded1 = encodeAttestationPayload(payload);
    final encoded2 = encodeAttestationPayload(payload);

    expect(encoded1, equals(encoded2));
  });
}
