import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nadz/nadz.dart';

import '../crypto/double_ratchet.dart';
import '../crypto/x3dh.dart';
import '../dht/node_id.dart';

/// An established E2E encrypted session between two peers.
typedef Session = ({
  NodeId localId,
  NodeId remoteId,
  RatchetState ratchetState,
  DateTime establishedAt,
  int messagesSent,
  int messagesReceived,
});

/// Pending session waiting for acknowledgement.
typedef PendingSession = ({
  NodeId remoteId,
  SimpleKeyPair identityKeyPair,
  X3dhResult x3dhResult,
  DateTime initiatedAt,
});

/// Session store: manages active sessions keyed by remote NodeId.
typedef SessionStore = ({
  Map<String, Session> activeSessions,
  Map<String, PendingSession> pendingSessions,
});

/// Creates an empty session store.
SessionStore createSessionStore() => (
  activeSessions: <String, Session>{},
  pendingSessions: <String, PendingSession>{},
);

/// Initiates a new session with a remote peer using X3DH.
Future<Result<(SessionStore, PendingSession), String>> initiateSession({
  required SessionStore store,
  required NodeId localId,
  required SimpleKeyPair identityKeyPair,
  required PreKeyBundle remoteBundle,
  required NodeId remoteId,
}) async {
  final x3dhResult = await x3dhInitiate(
    identityKeyPair: identityKeyPair,
    remoteBundle: remoteBundle,
  );

  return switch (x3dhResult) {
    Success(:final value) => () {
        final pending = (
          remoteId: remoteId,
          identityKeyPair: identityKeyPair,
          x3dhResult: value,
          initiatedAt: DateTime.now(),
        );
        final key = nodeIdToHex(remoteId);
        final updatedPending =
            Map<String, PendingSession>.from(store.pendingSessions)
              ..[key] = pending;
        final updatedStore = (
          activeSessions: store.activeSessions,
          pendingSessions: updatedPending,
        );
        return Success((updatedStore, pending));
      }(),
    Error(:final error) => Error(error),
  };
}

/// Completes a session after receiving acknowledgement (initiator side).
Future<Result<(SessionStore, Session), String>> completeSession({
  required SessionStore store,
  required NodeId localId,
  required NodeId remoteId,
  required SimplePublicKey remoteSignedPreKey,
}) async {
  final key = nodeIdToHex(remoteId);
  final pending = store.pendingSessions[key];
  if (pending == null) return Error('No pending session for $key');

  final ratchetResult = await initRatchetInitiator(
    sharedSecret: pending.x3dhResult.sharedSecret,
    remotePublicKey: remoteSignedPreKey,
  );

  return switch (ratchetResult) {
    Success(:final value) => () {
        final session = (
          localId: localId,
          remoteId: remoteId,
          ratchetState: value,
          establishedAt: DateTime.now(),
          messagesSent: 0,
          messagesReceived: 0,
        );
        final updatedActive =
            Map<String, Session>.from(store.activeSessions)..[key] = session;
        final updatedPending =
            Map<String, PendingSession>.from(store.pendingSessions)
              ..remove(key);
        return Success((
          (
            activeSessions: updatedActive,
            pendingSessions: updatedPending,
          ),
          session,
        ));
      }(),
    Error(:final error) => Error(error),
  };
}

/// Accepts an incoming session request (responder side).
Future<Result<(SessionStore, Session), String>> acceptSession({
  required SessionStore store,
  required NodeId localId,
  required NodeId remoteId,
  required Uint8List sharedSecret,
  required SimpleKeyPair localSignedPreKeyPair,
}) async {
  final ratchetResult = await initRatchetResponder(
    sharedSecret: sharedSecret,
    dhKeyPair: localSignedPreKeyPair,
  );

  return switch (ratchetResult) {
    Success(:final value) => () {
        final key = nodeIdToHex(remoteId);
        final session = (
          localId: localId,
          remoteId: remoteId,
          ratchetState: value,
          establishedAt: DateTime.now(),
          messagesSent: 0,
          messagesReceived: 0,
        );
        final updatedActive =
            Map<String, Session>.from(store.activeSessions)..[key] = session;
        return Success((
          (
            activeSessions: updatedActive,
            pendingSessions: store.pendingSessions,
          ),
          session,
        ));
      }(),
    Error(:final error) => Error(error),
  };
}

/// Encrypts a message within an active session.
Future<Result<(Session, RatchetMessage), String>> encryptSessionMessage(
  Session session,
  Uint8List plaintext,
) async {
  final result = await ratchetEncrypt(session.ratchetState, plaintext);
  return switch (result) {
    Success(:final value) => Success((
        (
          localId: session.localId,
          remoteId: session.remoteId,
          ratchetState: value.$1,
          establishedAt: session.establishedAt,
          messagesSent: session.messagesSent + 1,
          messagesReceived: session.messagesReceived,
        ),
        value.$2,
      )),
    Error(:final error) => Error(error),
  };
}

/// Decrypts a received message within an active session.
Future<Result<(Session, Uint8List), String>> decryptSessionMessage(
  Session session,
  RatchetMessage message,
) async {
  final result = await ratchetDecrypt(session.ratchetState, message);
  return switch (result) {
    Success(:final value) => Success((
        (
          localId: session.localId,
          remoteId: session.remoteId,
          ratchetState: value.$1,
          establishedAt: session.establishedAt,
          messagesSent: session.messagesSent,
          messagesReceived: session.messagesReceived + 1,
        ),
        value.$2,
      )),
    Error(:final error) => Error(error),
  };
}

/// Gets an active session by remote node ID.
Session? getSession(SessionStore store, NodeId remoteId) =>
    store.activeSessions[nodeIdToHex(remoteId)];

/// Returns the number of active sessions.
int activeSessionCount(SessionStore store) => store.activeSessions.length;
