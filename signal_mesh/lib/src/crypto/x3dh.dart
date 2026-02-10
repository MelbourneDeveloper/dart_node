import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nadz/nadz.dart';

import 'key_pair.dart';

/// Result of an X3DH key agreement - a shared secret for initializing
/// the Double Ratchet.
typedef X3dhResult = ({
  Uint8List sharedSecret,
  SimplePublicKey ephemeralPublic,
});

/// Pre-key bundle published to the DHT by a peer so others can initiate
/// sessions without the peer being online (though in P2P the first exchange
/// typically requires both parties online).
typedef PreKeyBundle = ({
  SimplePublicKey identityKey,
  SimplePublicKey signedPreKey,
  Uint8List signedPreKeySignature,
  SimplePublicKey? oneTimePreKey,
});

/// Performs the initiator side of X3DH key agreement.
///
/// Alice (initiator) computes a shared secret from:
///   DH1 = DH(IK_A, SPK_B)
///   DH2 = DH(EK_A, IK_B)
///   DH3 = DH(EK_A, SPK_B)
///   DH4 = DH(EK_A, OPK_B)  -- if one-time pre-key available
///
/// The shared secret is KDF(DH1 || DH2 || DH3 [|| DH4]).
Future<Result<X3dhResult, String>> x3dhInitiate({
  required SimpleKeyPair identityKeyPair,
  required PreKeyBundle remoteBundle,
}) async {
  try {
    final x25519 = X25519();

    // Generate ephemeral key pair
    final ephemeralKp = await x25519.newKeyPair();
    final ephemeralPub = await ephemeralKp.extractPublicKey();

    // DH1: our identity key x their signed pre-key
    final dh1 = await x25519.sharedSecretKey(
      keyPair: identityKeyPair,
      remotePublicKey: remoteBundle.signedPreKey,
    );

    // DH2: our ephemeral key x their identity key
    final dh2 = await x25519.sharedSecretKey(
      keyPair: ephemeralKp,
      remotePublicKey: remoteBundle.identityKey,
    );

    // DH3: our ephemeral key x their signed pre-key
    final dh3 = await x25519.sharedSecretKey(
      keyPair: ephemeralKp,
      remotePublicKey: remoteBundle.signedPreKey,
    );

    final dhResults = [
      await dh1.extractBytes(),
      await dh2.extractBytes(),
      await dh3.extractBytes(),
    ];

    // DH4: our ephemeral key x their one-time pre-key (if available)
    if (remoteBundle.oneTimePreKey case final otpk?) {
      final dh4 = await x25519.sharedSecretKey(
        keyPair: ephemeralKp,
        remotePublicKey: otpk,
      );
      dhResults.add(await dh4.extractBytes());
    }

    // Concatenate all DH results
    final combined =
        dhResults.fold<List<int>>([], (acc, bytes) => acc..addAll(bytes));

    // KDF to derive shared secret
    final hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 32);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(combined),
      nonce: Uint8List(32), // all zeros for X3DH
      info: 'SignalMeshX3DH'.codeUnits,
    );

    return Success((
      sharedSecret: Uint8List.fromList(await derived.extractBytes()),
      ephemeralPublic: ephemeralPub,
    ));
  } on Object catch (e) {
    return Error('X3DH initiation failed: $e');
  }
}

/// Performs the responder side of X3DH key agreement.
///
/// Bob (responder) computes the same shared secret using the received
/// ephemeral public key from Alice.
Future<Result<Uint8List, String>> x3dhRespond({
  required KeyPairBundle localBundle,
  required SimplePublicKey remoteIdentityKey,
  required SimplePublicKey remoteEphemeralKey,
  int? oneTimePreKeyIndex,
}) async {
  try {
    final x25519 = X25519();

    // DH1: their identity key x our signed pre-key
    final dh1 = await x25519.sharedSecretKey(
      keyPair: localBundle.signedPreKeyPair,
      remotePublicKey: remoteIdentityKey,
    );

    // DH2: their ephemeral key x our identity key
    final dh2 = await x25519.sharedSecretKey(
      keyPair: localBundle.identityKeyPair,
      remotePublicKey: remoteEphemeralKey,
    );

    // DH3: their ephemeral key x our signed pre-key
    final dh3 = await x25519.sharedSecretKey(
      keyPair: localBundle.signedPreKeyPair,
      remotePublicKey: remoteEphemeralKey,
    );

    final dhResults = [
      await dh1.extractBytes(),
      await dh2.extractBytes(),
      await dh3.extractBytes(),
    ];

    // DH4: if one-time pre-key was used
    if (oneTimePreKeyIndex case final idx?
        when idx < localBundle.oneTimePreKeys.length) {
      final otpkKp = localBundle.oneTimePreKeys[idx].keyPair;
      final dh4 = await x25519.sharedSecretKey(
        keyPair: otpkKp,
        remotePublicKey: remoteEphemeralKey,
      );
      dhResults.add(await dh4.extractBytes());
    }

    final combined =
        dhResults.fold<List<int>>([], (acc, bytes) => acc..addAll(bytes));

    final hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 32);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(combined),
      nonce: Uint8List(32),
      info: 'SignalMeshX3DH'.codeUnits,
    );

    return Success(Uint8List.fromList(await derived.extractBytes()));
  } on Object catch (e) {
    return Error('X3DH response failed: $e');
  }
}
