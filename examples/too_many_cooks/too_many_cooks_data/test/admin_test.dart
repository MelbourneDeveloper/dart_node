/// Tests for admin operations (no auth required).
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
  const testDbPath = '.test_admin.db';
  TooManyCooksDb? db;

  setUp(() {
    _deleteIfExists(testDbPath);
    final config = createDataConfig(dbPath: testDbPath);
    final result = createDb(config);
    expect(result, isA<Success<TooManyCooksDb, String>>());
    db = (result as Success<TooManyCooksDb, String>).value;
  });

  tearDown(() {
    db?.close();
    _deleteIfExists(testDbPath);
  });

  test('adminDeleteLock removes lock', () {
    // Register agent and acquire lock
    final regResult = db!.register('admin-test-agent');
    final reg = (regResult as Success<AgentRegistration, DbError>).value;
    db!.acquireLock(
      '/admin/file.dart',
      reg.agentName,
      reg.agentKey,
      null,
      60000,
    );

    // Admin deletes lock (no auth required)
    final result = db!.adminDeleteLock('/admin/file.dart');
    expect(result, isA<Success<void, DbError>>());

    // Verify lock is gone
    final query = db!.queryLock('/admin/file.dart');
    final lock = (query as Success<FileLock?, DbError>).value;
    expect(lock, isNull);
  });

  test('adminDeleteLock fails for nonexistent lock', () {
    final result = db!.adminDeleteLock('/no/such/lock.dart');
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errNotFound);
  });

  test('adminDeleteAgent removes agent and all related data', () {
    // Register agent
    final regResult = db!.register('delete-me-agent');
    final reg = (regResult as Success<AgentRegistration, DbError>).value;

    // Create agent data: lock, plan, message
    db!.acquireLock(
      '/delete/file.dart',
      reg.agentName,
      reg.agentKey,
      null,
      60000,
    );
    db!.updatePlan(reg.agentName, reg.agentKey, 'Goal', 'Task');

    // Register another agent to send message
    final reg2Result = db!.register('other-agent');
    final reg2 = (reg2Result as Success<AgentRegistration, DbError>).value;
    db!.sendMessage(reg.agentName, reg.agentKey, reg2.agentName, 'Hello');

    // Admin deletes agent
    final result = db!.adminDeleteAgent(reg.agentName);
    expect(result, isA<Success<void, DbError>>());

    // Verify agent is gone
    final agents = db!.listAgents();
    final agentList = (agents as Success<List<AgentIdentity>, DbError>).value;
    final agentNames = agentList.map((a) => a.agentName);
    expect(agentNames, isNot(contains('delete-me-agent')));

    // Verify lock is gone
    final lock = db!.queryLock('/delete/file.dart');
    expect((lock as Success<FileLock?, DbError>).value, isNull);

    // Verify plan is gone
    final plan = db!.getPlan(reg.agentName);
    expect((plan as Success<AgentPlan?, DbError>).value, isNull);
  });

  test('adminDeleteAgent fails for nonexistent agent', () {
    final result = db!.adminDeleteAgent('nonexistent-agent');
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errNotFound);
  });

  test('adminResetKey generates new key', () {
    // Register agent
    final regResult = db!.register('reset-key-agent');
    final reg = (regResult as Success<AgentRegistration, DbError>).value;
    final oldKey = reg.agentKey;

    // Reset key
    final result = db!.adminResetKey(reg.agentName);
    expect(result, isA<Success<AgentRegistration, DbError>>());
    final newReg = (result as Success<AgentRegistration, DbError>).value;

    expect(newReg.agentName, reg.agentName);
    expect(newReg.agentKey, isNot(oldKey));
    expect(newReg.agentKey.length, 64);
  });

  test('adminResetKey invalidates old key', () {
    // Register agent
    final regResult = db!.register('invalidate-key-agent');
    final reg = (regResult as Success<AgentRegistration, DbError>).value;
    final oldKey = reg.agentKey;

    // Reset key
    db!.adminResetKey(reg.agentName);

    // Old key should no longer work
    final authResult = db!.authenticate(reg.agentName, oldKey);
    expect(authResult, isA<Error<AgentIdentity, DbError>>());
    final error = (authResult as Error<AgentIdentity, DbError>).error;
    expect(error.code, errUnauthorized);
  });

  test('adminResetKey releases locks held by agent', () {
    // Register agent and acquire lock
    final regResult = db!.register('lock-reset-agent');
    final reg = (regResult as Success<AgentRegistration, DbError>).value;
    db!.acquireLock(
      '/reset/file.dart',
      reg.agentName,
      reg.agentKey,
      null,
      60000,
    );

    // Reset key
    db!.adminResetKey(reg.agentName);

    // Lock should be released
    final lock = db!.queryLock('/reset/file.dart');
    expect((lock as Success<FileLock?, DbError>).value, isNull);
  });

  test('adminResetKey fails for nonexistent agent', () {
    final result = db!.adminResetKey('nonexistent-agent');
    expect(result, isA<Error<AgentRegistration, DbError>>());
    final error = (result as Error<AgentRegistration, DbError>).error;
    expect(error.code, errNotFound);
  });

  test('new key works after reset', () {
    // Register agent
    final regResult = db!.register('new-key-works-agent');
    final reg = (regResult as Success<AgentRegistration, DbError>).value;

    // Reset key
    final resetResult = db!.adminResetKey(reg.agentName);
    final newReg = (resetResult as Success<AgentRegistration, DbError>).value;

    // New key should work
    final authResult = db!.authenticate(newReg.agentName, newReg.agentKey);
    expect(authResult, isA<Success<AgentIdentity, DbError>>());
  });
}
