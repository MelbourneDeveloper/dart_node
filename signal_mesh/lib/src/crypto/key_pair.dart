import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nadz/nadz.dart';

/// Cryptographic key pair for identity and encryption.
typedef KeyPairBundle = ({
  SimplePublicKey identityPublic,
  SimpleKeyPair identityKeyPair,
  SimplePublicKey signedPreKeyPublic,
  SimpleKeyPair signedPreKeyPair,
  Uint8List signedPreKeySignature,
  List<({SimplePublicKey publicKey, SimpleKeyPair keyPair})> oneTimePreKeys,
});

/// Generates a full key bundle for a peer (identity + signed prekey +
/// one-time prekeys) following Signal's X3DH specification.
Future<Result<KeyPairBundle, String>> generateKeyBundle({
  int oneTimePreKeyCount = 10,
}) async {
  try {
    final algorithm = X25519();
    final sigAlgorithm = Ed25519();

    // Identity key pair
    final identityKp = await algorithm.newKeyPair();
    final identityPub = await identityKp.extractPublicKey();

    // Signed pre-key
    final signedPreKp = await algorithm.newKeyPair();
    final signedPrePub = await signedPreKp.extractPublicKey();

    // Sign the signed pre-key with identity key
    final signingKp = await sigAlgorithm.newKeyPair();
    final signature = await sigAlgorithm.sign(
      signedPrePub.bytes,
      keyPair: signingKp,
    );

    // One-time pre-keys
    final oneTimeKeys =
        await Future.wait(List.generate(oneTimePreKeyCount, (_) async {
      final kp = await algorithm.newKeyPair();
      final pub = await kp.extractPublicKey();
      return (publicKey: pub, keyPair: kp);
    }));

    return Success((
      identityPublic: identityPub,
      identityKeyPair: identityKp,
      signedPreKeyPublic: signedPrePub,
      signedPreKeyPair: signedPreKp,
      signedPreKeySignature: Uint8List.fromList(signature.bytes),
      oneTimePreKeys: oneTimeKeys,
    ));
  } on Object catch (e) {
    return Error('Failed to generate key bundle: $e');
  }
}

/// Generates a single X25519 key pair for ephemeral use.
Future<Result<SimpleKeyPair, String>> generateEphemeralKeyPair() async {
  try {
    final kp = await X25519().newKeyPair();
    return Success(kp);
  } on Object catch (e) {
    return Error('Failed to generate ephemeral key pair: $e');
  }
}
