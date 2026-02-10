import 'package:cryptography/cryptography.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

import 'package:signal_mesh/signal_mesh.dart';

void main() {
  test('createPeerIdentity derives NodeId from public key', () async {
    final kp = await X25519().newKeyPair();
    final pub = await kp.extractPublicKey();

    final result = await createPeerIdentity(identityKey: pub);
    switch (result) {
      case Success(:final value):
        expect(value.nodeId.bytes.length, equals(32));
        expect(value.identityKey.bytes, equals(pub.bytes));
        expect(value.phoneNumber, isNull);
      case Error(:final error):
        fail(error);
    }
  });

  test('createPeerIdentity stores phone number', () async {
    final kp = await X25519().newKeyPair();
    final pub = await kp.extractPublicKey();

    final result = await createPeerIdentity(
      identityKey: pub,
      phoneNumber: '+61412345678',
    );
    switch (result) {
      case Success(:final value):
        expect(value.phoneNumber, equals('+61412345678'));
      case Error(:final error):
        fail(error);
    }
  });

  test('verifyIdentity confirms matching key and NodeId', () async {
    final kp = await X25519().newKeyPair();
    final pub = await kp.extractPublicKey();

    final result = await createPeerIdentity(identityKey: pub);
    switch (result) {
      case Success(:final value):
        final verified = await verifyIdentity(value);
        expect(verified, isTrue);
      case Error(:final error):
        fail(error);
    }
  });

  test('serializeIdentity and deserializeIdentity roundtrip', () async {
    final kp = await X25519().newKeyPair();
    final pub = await kp.extractPublicKey();

    final createResult = await createPeerIdentity(
      identityKey: pub,
      phoneNumber: '+1234567890',
    );
    final identity = switch (createResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    final serialized = serializeIdentity(identity);
    final deserialized = deserializeIdentity(serialized);

    switch (deserialized) {
      case Success(:final value):
        expect(
          nodeIdToHex(value.nodeId),
          equals(nodeIdToHex(identity.nodeId)),
        );
        expect(value.phoneNumber, equals('+1234567890'));
      case Error(:final error):
        fail(error);
    }
  });

  test('deserializeIdentity fails on missing fields', () {
    final result = deserializeIdentity({'foo': 'bar'});
    expect(result, isA<Error<PeerIdentity, String>>());
  });
}
