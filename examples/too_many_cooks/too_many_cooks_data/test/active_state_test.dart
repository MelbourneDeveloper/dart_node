/// Tests for activate/deactivate agent state.
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
  const testDbPath = '.test_active_state.db';
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

  test('activate sets agent active', () {
    db!.register('agent1');
    final result = db!.activate('agent1');
    expect(result, isA<Success<void, DbError>>());
  });

  test('activate fails for nonexistent agent', () {
    final result = db!.activate('nonexistent');
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errNotFound);
  });

  test('deactivate sets agent inactive', () {
    db!.register('agent1');
    db!.activate('agent1');
    final result = db!.deactivate('agent1');
    expect(result, isA<Success<void, DbError>>());
  });

  test('deactivate fails for nonexistent agent', () {
    final result = db!.deactivate('nonexistent');
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errNotFound);
  });

  test('deactivateAll deactivates all agents', () {
    db!.register('agent1');
    db!.register('agent2');
    db!.activate('agent1');
    db!.activate('agent2');
    final result = db!.deactivateAll();
    expect(result, isA<Success<void, DbError>>());
  });

  test('deactivateAll succeeds with no agents', () {
    final result = db!.deactivateAll();
    expect(result, isA<Success<void, DbError>>());
  });

  test('lookupByKey returns agent name', () {
    final reg = db!.register('agent1');
    final key = (reg as Success<AgentRegistration, DbError>).value.agentKey;
    final result = db!.lookupByKey(key);
    expect(result, isA<Success<String, DbError>>());
    expect((result as Success<String, DbError>).value, 'agent1');
  });

  test('lookupByKey fails for invalid key', () {
    final result = db!.lookupByKey('invalid-key');
    expect(result, isA<Error<String, DbError>>());
    final error = (result as Error<String, DbError>).error;
    expect(error.code, errUnauthorized);
  });
}
