import 'dart:typed_data';

import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

import 'package:signal_mesh/signal_mesh.dart';

void main() {
  test('generateKeyBundle creates full bundle', () async {
    final result = await generateKeyBundle(oneTimePreKeyCount: 3);
    switch (result) {
      case Success(:final value):
        expect(value.identityPublic.bytes.length, equals(32));
        expect(value.signedPreKeyPublic.bytes.length, equals(32));
        expect(value.signedPreKeySignature, isNotEmpty);
        expect(value.oneTimePreKeys.length, equals(3));
      case Error(:final error):
        fail(error);
    }
  });

  test('generateEphemeralKeyPair creates a key pair', () async {
    final result = await generateEphemeralKeyPair();
    switch (result) {
      case Success(:final value):
        final pub = await value.extractPublicKey();
        expect(pub.bytes.length, equals(32));
      case Error(:final error):
        fail(error);
    }
  });

  test('X3DH initiator and responder derive same shared secret', () async {
    // Generate bundles for Alice and Bob
    final aliceBundleResult = await generateKeyBundle(oneTimePreKeyCount: 1);
    final bobBundleResult = await generateKeyBundle(oneTimePreKeyCount: 1);

    final aliceBundle = switch (aliceBundleResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    final bobBundle = switch (bobBundleResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    // Alice initiates X3DH with Bob's pre-key bundle
    final preKeyBundle = (
      identityKey: bobBundle.identityPublic,
      signedPreKey: bobBundle.signedPreKeyPublic,
      signedPreKeySignature: bobBundle.signedPreKeySignature,
      oneTimePreKey: bobBundle.oneTimePreKeys.isNotEmpty
          ? bobBundle.oneTimePreKeys.first.publicKey
          : null,
    );

    final initiateResult = await x3dhInitiate(
      identityKeyPair: aliceBundle.identityKeyPair,
      remoteBundle: preKeyBundle,
    );

    final x3dhResult = switch (initiateResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    // Bob responds
    final respondResult = await x3dhRespond(
      localBundle: bobBundle,
      remoteIdentityKey: aliceBundle.identityPublic,
      remoteEphemeralKey: x3dhResult.ephemeralPublic,
      oneTimePreKeyIndex: 0,
    );

    final bobSecret = switch (respondResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    // Both should have the same shared secret
    expect(x3dhResult.sharedSecret.length, equals(32));
    expect(bobSecret.length, equals(32));
    expect(x3dhResult.sharedSecret, equals(bobSecret));
  });

  test('Double Ratchet encrypt then decrypt roundtrip', () async {
    // Simulate X3DH shared secret
    final sharedSecret = Uint8List(32)
      ..[0] = 42
      ..[15] = 99;

    final bobBundleResult = await generateKeyBundle(oneTimePreKeyCount: 0);
    final bobBundle = switch (bobBundleResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    // Alice initializes ratchet as initiator
    final aliceResult = await initRatchetInitiator(
      sharedSecret: sharedSecret,
      remotePublicKey: bobBundle.signedPreKeyPublic,
    );
    var aliceState = switch (aliceResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    // Bob initializes ratchet as responder
    final bobResult = await initRatchetResponder(
      sharedSecret: sharedSecret,
      dhKeyPair: bobBundle.signedPreKeyPair,
    );
    var bobState = switch (bobResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    // Alice encrypts a message
    final plaintext = Uint8List.fromList('Hello Bob from the mesh!'.codeUnits);
    final encryptResult = await ratchetEncrypt(aliceState, plaintext);

    switch (encryptResult) {
      case Success(:final value):
        aliceState = value.$1;
        final ratchetMsg = value.$2;

        // Bob decrypts
        final decryptResult = await ratchetDecrypt(bobState, ratchetMsg);
        switch (decryptResult) {
          case Success(:final value):
            bobState = value.$1;
            expect(String.fromCharCodes(value.$2), equals('Hello Bob from the mesh!'));
          case Error(:final error):
            fail('Decrypt failed: $error');
        }
      case Error(:final error):
        fail('Encrypt failed: $error');
    }
  });

  test('Ratchet message numbers increment', () async {
    final sharedSecret = Uint8List(32)..[0] = 1;
    final bobBundleResult = await generateKeyBundle(oneTimePreKeyCount: 0);
    final bobBundle = switch (bobBundleResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    final aliceResult = await initRatchetInitiator(
      sharedSecret: sharedSecret,
      remotePublicKey: bobBundle.signedPreKeyPublic,
    );
    var aliceState = switch (aliceResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    for (var i = 0; i < 5; i++) {
      final result = await ratchetEncrypt(
        aliceState,
        Uint8List.fromList([i]),
      );
      switch (result) {
        case Success(:final value):
          aliceState = value.$1;
          expect(value.$2.messageNumber, equals(i));
        case Error(:final error):
          fail(error);
      }
    }

    expect(aliceState.sendMessageNumber, equals(5));
  });
}
