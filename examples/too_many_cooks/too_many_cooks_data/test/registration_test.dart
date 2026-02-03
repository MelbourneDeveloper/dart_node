/// Tests for agent registration.
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
  const testDbPath = '.test_registration.db';
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

  test('register creates agent with key', () {
    final result = db!.register('test-agent');
    expect(result, isA<Success<AgentRegistration, DbError>>());
    final reg = (result as Success<AgentRegistration, DbError>).value;
    expect(reg.agentName, 'test-agent');
    expect(reg.agentKey.length, 64);
  });

  test('register fails for duplicate name', () {
    db!.register('duplicate-agent');
    final result = db!.register('duplicate-agent');
    expect(result, isA<Error<AgentRegistration, DbError>>());
    final error = (result as Error<AgentRegistration, DbError>).error;
    expect(error.code, errValidation);
    expect(error.message, contains('already registered'));
  });

  test('register fails for empty name', () {
    final result = db!.register('');
    expect(result, isA<Error<AgentRegistration, DbError>>());
    final error = (result as Error<AgentRegistration, DbError>).error;
    expect(error.code, errValidation);
    expect(error.message, contains('1-50'));
  });

  test('register fails for name over 50 chars', () {
    final result = db!.register('a' * 51);
    expect(result, isA<Error<AgentRegistration, DbError>>());
    final error = (result as Error<AgentRegistration, DbError>).error;
    expect(error.code, errValidation);
    expect(error.message, contains('1-50'));
  });

  test('register accepts name of exactly 50 chars', () {
    final result = db!.register('a' * 50);
    expect(result, isA<Success<AgentRegistration, DbError>>());
  });

  test('listAgents returns registered agents', () {
    db!.register('agent1');
    db!.register('agent2');
    final result = db!.listAgents();
    expect(result, isA<Success<List<AgentIdentity>, DbError>>());
    final agents = (result as Success<List<AgentIdentity>, DbError>).value;
    expect(agents.length, 2);
    expect(agents.map((a) => a.agentName).toSet(), {'agent1', 'agent2'});
  });
}
