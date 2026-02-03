/// Tests for file lock operations.
library;

import 'dart:js_interop';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

extension type _Fs(JSObject _) implements JSObject {
  external void unlinkSync(String path);
  external bool existsSync(String path);
}

final _Fs _fs = _Fs(requireModule('fs') as JSObject);

void _deleteIfExists(String path) {
  try {
    if (_fs.existsSync(path)) {
      _fs.unlinkSync(path);
    }
  } on Object catch (_) {}
}

void main() {
  const testDbPath = '.test_locks.db';
  TooManyCooksDb? db;
  var agentName = '';
  var agentKey = '';

  setUp(() {
    _deleteIfExists(testDbPath);
    final config = createDataConfig(dbPath: testDbPath);
    final result = createDb(config);
    expect(result, isA<Success<TooManyCooksDb, String>>());
    db = (result as Success<TooManyCooksDb, String>).value;

    // Register a test agent
    final regResult = db!.register('lock-agent');
    final reg = (regResult as Success<AgentRegistration, DbError>).value;
    agentName = reg.agentName;
    agentKey = reg.agentKey;
  });

  tearDown(() {
    db?.close();
    _deleteIfExists(testDbPath);
  });

  test('acquireLock succeeds on free file', () {
    final result = db!.acquireLock(
      '/path/to/file.dart',
      agentName,
      agentKey,
      'editing',
      60000,
    );
    expect(result, isA<Success<LockResult, DbError>>());
    final lockResult = (result as Success<LockResult, DbError>).value;
    expect(lockResult.acquired, true);
    expect(lockResult.lock, isNotNull);
    expect(lockResult.lock!.filePath, '/path/to/file.dart');
    expect(lockResult.lock!.agentName, agentName);
    expect(lockResult.lock!.reason, 'editing');
    expect(lockResult.error, isNull);
  });

  test('acquireLock fails when held by another agent', () {
    // Register second agent
    final reg2Result = db!.register('lock-agent-2');
    final reg2 = (reg2Result as Success<AgentRegistration, DbError>).value;

    // First agent acquires lock
    db!.acquireLock('/contested/file.dart', agentName, agentKey, null, 60000);

    // Second agent tries to acquire
    final result = db!.acquireLock(
      '/contested/file.dart',
      reg2.agentName,
      reg2.agentKey,
      null,
      60000,
    );
    expect(result, isA<Success<LockResult, DbError>>());
    final lockResult = (result as Success<LockResult, DbError>).value;
    expect(lockResult.acquired, false);
    expect(lockResult.lock, isNull);
    expect(lockResult.error, contains('Held by'));
  });

  test('acquireLock fails with invalid credentials', () {
    final result = db!.acquireLock(
      '/path/to/file.dart',
      agentName,
      'wrong-key',
      null,
      60000,
    );
    expect(result, isA<Error<LockResult, DbError>>());
    final error = (result as Error<LockResult, DbError>).error;
    expect(error.code, errUnauthorized);
  });

  test('releaseLock succeeds when owned', () {
    db!.acquireLock('/release/file.dart', agentName, agentKey, null, 60000);

    final result = db!.releaseLock('/release/file.dart', agentName, agentKey);
    expect(result, isA<Success<void, DbError>>());

    // Verify lock is gone
    final queryResult = db!.queryLock('/release/file.dart');
    final lock = (queryResult as Success<FileLock?, DbError>).value;
    expect(lock, isNull);
  });

  test('releaseLock fails when not owned', () {
    final result = db!.releaseLock('/not/locked.dart', agentName, agentKey);
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errNotFound);
  });

  test('queryLock returns lock info', () {
    db!.acquireLock('/query/file.dart', agentName, agentKey, 'testing', 60000);

    final result = db!.queryLock('/query/file.dart');
    expect(result, isA<Success<FileLock?, DbError>>());
    final lock = (result as Success<FileLock?, DbError>).value;
    expect(lock, isNotNull);
    expect(lock!.filePath, '/query/file.dart');
    expect(lock.agentName, agentName);
    expect(lock.reason, 'testing');
  });

  test('queryLock returns null for unlocked file', () {
    final result = db!.queryLock('/not/locked.dart');
    expect(result, isA<Success<FileLock?, DbError>>());
    final lock = (result as Success<FileLock?, DbError>).value;
    expect(lock, isNull);
  });

  test('listLocks returns all active locks', () {
    db!.acquireLock('/list/file1.dart', agentName, agentKey, null, 60000);
    db!.acquireLock('/list/file2.dart', agentName, agentKey, null, 60000);

    final result = db!.listLocks();
    expect(result, isA<Success<List<FileLock>, DbError>>());
    final locks = (result as Success<List<FileLock>, DbError>).value;
    expect(locks.length, 2);
    expect(locks.map((l) => l.filePath).toSet(), {
      '/list/file1.dart',
      '/list/file2.dart',
    });
  });

  test('renewLock extends expiration', () {
    db!.acquireLock('/renew/file.dart', agentName, agentKey, null, 1000);

    final queryBefore = db!.queryLock('/renew/file.dart');
    final lockBefore = (queryBefore as Success<FileLock?, DbError>).value!;

    final result = db!.renewLock(
      '/renew/file.dart',
      agentName,
      agentKey,
      60000,
    );
    expect(result, isA<Success<void, DbError>>());

    final queryAfter = db!.queryLock('/renew/file.dart');
    final lockAfter = (queryAfter as Success<FileLock?, DbError>).value!;
    expect(lockAfter.expiresAt, greaterThan(lockBefore.expiresAt));
    expect(lockAfter.version, greaterThan(lockBefore.version));
  });

  test('renewLock fails when not owned', () {
    final result = db!.renewLock('/not/owned.dart', agentName, agentKey, 60000);
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errNotFound);
  });

  test('acquireLock takes over expired lock', () {
    // Acquire with 0ms timeout (immediately expired)
    db!.acquireLock('/expire/file.dart', agentName, agentKey, null, 0);

    // Register second agent
    final reg2Result = db!.register('lock-agent-3');
    final reg2 = (reg2Result as Success<AgentRegistration, DbError>).value;

    // Second agent should acquire expired lock (expiry checked at acquire time)
    final result = db!.acquireLock(
      '/expire/file.dart',
      reg2.agentName,
      reg2.agentKey,
      null,
      60000,
    );
    expect(result, isA<Success<LockResult, DbError>>());
    final lockResult = (result as Success<LockResult, DbError>).value;
    expect(lockResult.acquired, true);
    expect(lockResult.lock!.agentName, reg2.agentName);
  });

  test('forceReleaseLock fails on non-expired lock', () {
    // Register second agent
    final reg2Result = db!.register('force-agent');
    final reg2 = (reg2Result as Success<AgentRegistration, DbError>).value;

    // First agent acquires with long timeout
    db!.acquireLock('/force/file.dart', agentName, agentKey, null, 600000);

    // Second agent tries to force release
    final result = db!.forceReleaseLock(
      '/force/file.dart',
      reg2.agentName,
      reg2.agentKey,
    );
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errLockHeld);
  });

  test('forceReleaseLock fails when no lock exists', () {
    final result = db!.forceReleaseLock('/no/lock.dart', agentName, agentKey);
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errNotFound);
  });
}
