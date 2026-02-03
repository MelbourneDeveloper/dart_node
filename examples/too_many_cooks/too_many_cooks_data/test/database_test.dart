/// Tests for database creation and lifecycle.
library;

import 'dart:js_interop';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

extension type _Fs(JSObject _) implements JSObject {
  external void unlinkSync(String path);
  external bool existsSync(String path);
  external void rmdirSync(String path, _RmdirOptions options);
}

extension type _RmdirOptions._(JSObject _) implements JSObject {
  external factory _RmdirOptions({bool recursive});
}

final _Fs _fs = _Fs(requireModule('fs') as JSObject);

void _deleteIfExists(String path) {
  try {
    if (_fs.existsSync(path)) {
      _fs.unlinkSync(path);
    }
  } on Object catch (_) {}
}

void _deleteDirIfExists(String path) {
  try {
    if (_fs.existsSync(path)) {
      _fs.rmdirSync(path, _RmdirOptions(recursive: true));
    }
  } on Object catch (_) {}
}

void main() {
  test('createDb succeeds with valid path', () {
    const testDbPath = '.test_create_db.db';
    _deleteIfExists(testDbPath);

    final config = createDataConfig(dbPath: testDbPath);
    final result = createDb(config);
    expect(result, isA<Success<TooManyCooksDb, String>>());

    final db = (result as Success<TooManyCooksDb, String>).value;
    db.close();
    _deleteIfExists(testDbPath);
  });

  test('createDb creates parent directory if needed', () {
    const testDir = '.test_nested_dir';
    const testDbPath = '$testDir/subdir/data.db';
    _deleteDirIfExists(testDir);

    final config = createDataConfig(dbPath: testDbPath);
    final result = createDb(config);
    expect(result, isA<Success<TooManyCooksDb, String>>());

    final db = (result as Success<TooManyCooksDb, String>).value;
    db.close();
    _deleteDirIfExists(testDir);
  });

  test('close succeeds', () {
    const testDbPath = '.test_close.db';
    _deleteIfExists(testDbPath);

    final config = createDataConfig(dbPath: testDbPath);
    final createResult = createDb(config);
    final db = (createResult as Success<TooManyCooksDb, String>).value;

    final closeResult = db.close();
    expect(closeResult, isA<Success<void, DbError>>());

    _deleteIfExists(testDbPath);
  });

  test('schema version is set correctly', () {
    expect(schemaVersion, 1);
  });

  test('error codes are defined', () {
    expect(errNotFound, 'NOT_FOUND');
    expect(errUnauthorized, 'UNAUTHORIZED');
    expect(errLockHeld, 'LOCK_HELD');
    expect(errLockExpired, 'LOCK_EXPIRED');
    expect(errValidation, 'VALIDATION');
    expect(errDatabase, 'DATABASE');
  });
}
