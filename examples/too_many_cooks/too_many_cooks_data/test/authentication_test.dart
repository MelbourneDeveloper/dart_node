/// Tests for agent authentication.
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
  const testDbPath = '.test_authentication.db';
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

  test('authenticate succeeds with valid credentials', () {
    final regResult = db!.register('auth-agent');
    final reg = (regResult as Success<AgentRegistration, DbError>).value;

    final authResult = db!.authenticate(reg.agentName, reg.agentKey);
    expect(authResult, isA<Success<AgentIdentity, DbError>>());
    final agent = (authResult as Success<AgentIdentity, DbError>).value;
    expect(agent.agentName, 'auth-agent');
  });

  test('authenticate fails with invalid key', () {
    db!.register('auth-agent2');

    final authResult = db!.authenticate('auth-agent2', 'wrong-key');
    expect(authResult, isA<Error<AgentIdentity, DbError>>());
    final error = (authResult as Error<AgentIdentity, DbError>).error;
    expect(error.code, errUnauthorized);
  });

  test('authenticate fails for nonexistent agent', () {
    final authResult = db!.authenticate('nonexistent', 'any-key');
    expect(authResult, isA<Error<AgentIdentity, DbError>>());
    final error = (authResult as Error<AgentIdentity, DbError>).error;
    expect(error.code, errUnauthorized);
  });

  test('authenticate updates last_active timestamp', () {
    final regResult = db!.register('timestamp-agent');
    final reg = (regResult as Success<AgentRegistration, DbError>).value;

    final firstAuth = db!.authenticate(reg.agentName, reg.agentKey);
    final firstAgent = (firstAuth as Success<AgentIdentity, DbError>).value;

    // Small delay to ensure timestamp changes
    final secondAuth = db!.authenticate(reg.agentName, reg.agentKey);
    final secondAgent = (secondAuth as Success<AgentIdentity, DbError>).value;

    expect(secondAgent.lastActive, greaterThanOrEqualTo(firstAgent.lastActive));
  });
}
