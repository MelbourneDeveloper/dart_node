import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nadz/nadz.dart';

/// State of a Double Ratchet session between two peers.
///
/// The Double Ratchet provides forward secrecy and break-in recovery
/// by ratcheting keys with each message exchange.
typedef RatchetState = ({
  SimpleKeyPair dhKeyPair,
  SimplePublicKey? remoteDhPublic,
  Uint8List rootKey,
  Uint8List sendChainKey,
  Uint8List receiveChainKey,
  int sendMessageNumber,
  int receiveMessageNumber,
  int previousChainLength,
  Map<int, Uint8List> skippedMessageKeys,
});

/// Encrypted message output from the Double Ratchet.
typedef RatchetMessage = ({
  SimplePublicKey dhPublic,
  int messageNumber,
  int previousChainLength,
  Uint8List ciphertext,
  Uint8List nonce,
});

/// Creates a new ratchet state for the initiator (Alice) after X3DH.
Future<Result<RatchetState, String>> initRatchetInitiator({
  required Uint8List sharedSecret,
  required SimplePublicKey remotePublicKey,
}) async {
  try {
    final x25519 = X25519();
    final dhKp = await x25519.newKeyPair();

    // Perform initial DH ratchet step
    final dhResult = await x25519.sharedSecretKey(
      keyPair: dhKp,
      remotePublicKey: remotePublicKey,
    );
    final dhBytes = await dhResult.extractBytes();

    // KDF to split root key and send chain key
    final (rootKey, chainKey) = await _kdfRootKey(sharedSecret, dhBytes);

    return Success((
      dhKeyPair: dhKp,
      remoteDhPublic: remotePublicKey,
      rootKey: rootKey,
      sendChainKey: chainKey,
      receiveChainKey: Uint8List(32), // set on first received message
      sendMessageNumber: 0,
      receiveMessageNumber: 0,
      previousChainLength: 0,
      skippedMessageKeys: <int, Uint8List>{},
    ));
  } on Object catch (e) {
    return Error('Failed to init ratchet (initiator): $e');
  }
}

/// Creates a new ratchet state for the responder (Bob) after X3DH.
Future<Result<RatchetState, String>> initRatchetResponder({
  required Uint8List sharedSecret,
  required SimpleKeyPair dhKeyPair,
}) async {
  try {
    return Success((
      dhKeyPair: dhKeyPair,
      remoteDhPublic: null,
      rootKey: sharedSecret,
      sendChainKey: Uint8List(32),
      receiveChainKey: Uint8List(32),
      sendMessageNumber: 0,
      receiveMessageNumber: 0,
      previousChainLength: 0,
      skippedMessageKeys: <int, Uint8List>{},
    ));
  } on Object catch (e) {
    return Error('Failed to init ratchet (responder): $e');
  }
}

/// Encrypts a plaintext message, advancing the send chain.
Future<Result<(RatchetState, RatchetMessage), String>> ratchetEncrypt(
  RatchetState state,
  Uint8List plaintext,
) async {
  try {
    // Derive message key from send chain key
    final (newChainKey, messageKey) = await _kdfChainKey(state.sendChainKey);

    // Encrypt with AES-GCM
    final aesGcm = AesGcm.with256bits();
    final secretKey = SecretKey(messageKey);
    final secretBox = await aesGcm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: aesGcm.newNonce(),
    );

    final dhPub = await state.dhKeyPair.extractPublicKey();

    final message = (
      dhPublic: dhPub,
      messageNumber: state.sendMessageNumber,
      previousChainLength: state.previousChainLength,
      ciphertext: Uint8List.fromList(
        secretBox.cipherText + secretBox.mac.bytes,
      ),
      nonce: Uint8List.fromList(secretBox.nonce),
    );

    final newState = (
      dhKeyPair: state.dhKeyPair,
      remoteDhPublic: state.remoteDhPublic,
      rootKey: state.rootKey,
      sendChainKey: newChainKey,
      receiveChainKey: state.receiveChainKey,
      sendMessageNumber: state.sendMessageNumber + 1,
      receiveMessageNumber: state.receiveMessageNumber,
      previousChainLength: state.previousChainLength,
      skippedMessageKeys: state.skippedMessageKeys,
    );

    return Success((newState, message));
  } on Object catch (e) {
    return Error('Ratchet encrypt failed: $e');
  }
}

/// Decrypts a received message, performing a DH ratchet step if needed.
Future<Result<(RatchetState, Uint8List), String>> ratchetDecrypt(
  RatchetState state,
  RatchetMessage message,
) async {
  try {
    var currentState = state;

    // Check if we need a DH ratchet step (new remote public key)
    final needsRatchet = currentState.remoteDhPublic == null ||
        !_publicKeysEqual(
          message.dhPublic,
          currentState.remoteDhPublic,
        );

    if (needsRatchet) {
      currentState = await _dhRatchetStep(currentState, message.dhPublic);
    }

    // Derive message key from receive chain key
    final (newChainKey, messageKey) =
        await _kdfChainKey(currentState.receiveChainKey);

    // Decrypt with AES-GCM
    final aesGcm = AesGcm.with256bits();
    final cipherBytes = message.ciphertext;
    final macLength = 16;
    final cipherText = cipherBytes.sublist(0, cipherBytes.length - macLength);
    final mac = Mac(cipherBytes.sublist(cipherBytes.length - macLength));

    final secretBox = SecretBox(
      cipherText,
      nonce: message.nonce,
      mac: mac,
    );

    final plaintext = await aesGcm.decrypt(
      secretBox,
      secretKey: SecretKey(messageKey),
    );

    final newState = (
      dhKeyPair: currentState.dhKeyPair,
      remoteDhPublic: currentState.remoteDhPublic,
      rootKey: currentState.rootKey,
      sendChainKey: currentState.sendChainKey,
      receiveChainKey: newChainKey,
      sendMessageNumber: currentState.sendMessageNumber,
      receiveMessageNumber: currentState.receiveMessageNumber + 1,
      previousChainLength: currentState.previousChainLength,
      skippedMessageKeys: currentState.skippedMessageKeys,
    );

    return Success((newState, Uint8List.fromList(plaintext)));
  } on Object catch (e) {
    return Error('Ratchet decrypt failed: $e');
  }
}

/// Performs a DH ratchet step when receiving a new public key.
Future<RatchetState> _dhRatchetStep(
  RatchetState state,
  SimplePublicKey remotePublic,
) async {
  final x25519 = X25519();

  // Compute DH with current key pair and new remote public
  final dhResult = await x25519.sharedSecretKey(
    keyPair: state.dhKeyPair,
    remotePublicKey: remotePublic,
  );
  final dhBytes = await dhResult.extractBytes();

  // Derive new root key and receive chain key
  final (rootKey1, receiveChainKey) =
      await _kdfRootKey(state.rootKey, dhBytes);

  // Generate new DH key pair
  final newDhKp = await x25519.newKeyPair();

  // Compute DH with new key pair and remote public
  final dhResult2 = await x25519.sharedSecretKey(
    keyPair: newDhKp,
    remotePublicKey: remotePublic,
  );
  final dhBytes2 = await dhResult2.extractBytes();

  // Derive new root key and send chain key
  final (rootKey2, sendChainKey) = await _kdfRootKey(rootKey1, dhBytes2);

  return (
    dhKeyPair: newDhKp,
    remoteDhPublic: remotePublic,
    rootKey: rootKey2,
    sendChainKey: sendChainKey,
    receiveChainKey: receiveChainKey,
    sendMessageNumber: 0,
    receiveMessageNumber: 0,
    previousChainLength: state.sendMessageNumber,
    skippedMessageKeys: state.skippedMessageKeys,
  );
}

/// KDF for root key ratchet: (rootKey, dhOutput) -> (newRootKey, chainKey).
Future<(Uint8List, Uint8List)> _kdfRootKey(
  List<int> rootKey,
  List<int> dhOutput,
) async {
  final hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 64);
  final derived = await hkdf.deriveKey(
    secretKey: SecretKey(dhOutput),
    nonce: Uint8List.fromList(rootKey),
    info: 'SignalMeshRatchet'.codeUnits,
  );
  final bytes = await derived.extractBytes();
  return (
    Uint8List.fromList(bytes.sublist(0, 32)),
    Uint8List.fromList(bytes.sublist(32, 64)),
  );
}

/// KDF for chain key ratchet: chainKey -> (newChainKey, messageKey).
Future<(Uint8List, Uint8List)> _kdfChainKey(Uint8List chainKey) async {
  final hmac = Hmac(Sha256());

  // Message key = HMAC(chainKey, 0x01)
  final msgMac =
      await hmac.calculateMac([0x01], secretKey: SecretKey(chainKey));

  // Next chain key = HMAC(chainKey, 0x02)
  final nextMac =
      await hmac.calculateMac([0x02], secretKey: SecretKey(chainKey));

  return (
    Uint8List.fromList(nextMac.bytes),
    Uint8List.fromList(msgMac.bytes),
  );
}

bool _publicKeysEqual(SimplePublicKey? a, SimplePublicKey? b) {
  if (a == null || b == null) return false;
  if (a.bytes.length != b.bytes.length) return false;
  for (var i = 0; i < a.bytes.length; i++) {
    if (a.bytes[i] != b.bytes[i]) return false;
  }
  return true;
}
