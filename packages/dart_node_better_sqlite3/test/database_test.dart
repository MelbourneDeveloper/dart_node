/// Tests for dart_node_better_sqlite3 on Node.js.
library;

import 'dart:js_interop';

import 'package:dart_node_better_sqlite3/dart_node_better_sqlite3.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

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
  } catch (_) {
    // Ignore cleanup errors
  }
}

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('openDatabase', () {
    test('opens in-memory database', () {
      final result = openDatabase(':memory:');
      expect(result, isA<Success<Database, String>>());
      final db = (result as Success<Database, String>).value;
      expect(db.isOpen(), true);
      db.close();
    });

    test('opens file database', () {
      const path = '.test_open.db';
      _deleteIfExists(path);

      final result = openDatabase(path);
      expect(result, isA<Success<Database, String>>());
      final db = (result as Success<Database, String>).value;
      expect(db.isOpen(), true);
      db.close();

      _deleteIfExists(path);
    });

    test('returns error for invalid path', () {
      final result = openDatabase('/nonexistent/dir/test.db');
      expect(result, isA<Error<Database, String>>());
    });
  });

  group('Database.exec', () {
    late Database db;

    setUp(() {
      final result = openDatabase(':memory:');
      db = (result as Success<Database, String>).value;
    });

    tearDown(() {
      db.close();
    });

    test('executes CREATE TABLE', () {
      final result = db.exec('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT UNIQUE
        )
      ''');
      expect(result, isA<Success<void, String>>());
    });

    test('executes multiple statements', () {
      final result = db.exec('''
        CREATE TABLE t1 (id INTEGER);
        CREATE TABLE t2 (id INTEGER);
        CREATE TABLE t3 (id INTEGER);
      ''');
      expect(result, isA<Success<void, String>>());
    });

    test('returns error for invalid SQL', () {
      final result = db.exec('NOT VALID SQL');
      expect(result, isA<Error<void, String>>());
    });
  });

  group('Database.prepare', () {
    late Database db;

    setUp(() {
      final result = openDatabase(':memory:');
      db = (result as Success<Database, String>).value;
      db.exec('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
    });

    tearDown(() {
      db.close();
    });

    test('prepares valid statement', () {
      final result = db.prepare('SELECT * FROM users');
      expect(result, isA<Success<Statement, String>>());
    });

    test('returns error for invalid SQL', () {
      final result = db.prepare('SELECT * FROM nonexistent');
      expect(result, isA<Error<Statement, String>>());
    });
  });

  group('Statement.run', () {
    late Database db;
    late Statement insertStmt;

    setUp(() {
      final result = openDatabase(':memory:');
      db = (result as Success<Database, String>).value;
      db.exec('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
      final stmtResult = db.prepare('INSERT INTO users (name) VALUES (?)');
      insertStmt = (stmtResult as Success<Statement, String>).value;
    });

    tearDown(() {
      db.close();
    });

    test('inserts row and returns lastInsertRowid', () {
      final result = insertStmt.run(['Alice']);
      expect(result, isA<Success<RunResult, String>>());
      final runResult = (result as Success<RunResult, String>).value;
      expect(runResult.changes, 1);
      expect(runResult.lastInsertRowid, 1);
    });

    test('inserts multiple rows with incrementing rowid', () {
      insertStmt.run(['Alice']);
      insertStmt.run(['Bob']);
      final result = insertStmt.run(['Charlie']);
      final runResult = (result as Success<RunResult, String>).value;
      expect(runResult.lastInsertRowid, 3);
    });

    test('updates rows and returns changes count', () {
      insertStmt.run(['Alice']);
      insertStmt.run(['Bob']);
      final updateResult = db.prepare('UPDATE users SET name = ?');
      final stmt = (updateResult as Success<Statement, String>).value;
      final result = stmt.run(['Updated']);
      final runResult = (result as Success<RunResult, String>).value;
      expect(runResult.changes, 2);
    });

    test('deletes rows and returns changes count', () {
      insertStmt.run(['Alice']);
      insertStmt.run(['Bob']);
      final deleteResult = db.prepare('DELETE FROM users');
      final stmt = (deleteResult as Success<Statement, String>).value;
      final result = stmt.run();
      final runResult = (result as Success<RunResult, String>).value;
      expect(runResult.changes, 2);
    });
  });

  group('Statement.get', () {
    late Database db;

    setUp(() {
      final result = openDatabase(':memory:');
      db = (result as Success<Database, String>).value;
      db.exec('''
        CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);
        INSERT INTO users (name, age) VALUES ('Alice', 30);
        INSERT INTO users (name, age) VALUES ('Bob', 25);
      ''');
    });

    tearDown(() {
      db.close();
    });

    test('returns first row', () {
      final stmtResult = db.prepare('SELECT * FROM users ORDER BY id');
      final stmt = (stmtResult as Success<Statement, String>).value;
      final result = stmt.get();
      expect(result, isA<Success<Map<String, Object?>?, String>>());
      final row = (result as Success<Map<String, Object?>?, String>).value;
      expect(row, isNotNull);
      expect(row!['name'], 'Alice');
      expect(row['age'], 30);
    });

    test('returns null for no results', () {
      final stmtResult = db.prepare('SELECT * FROM users WHERE id = ?');
      final stmt = (stmtResult as Success<Statement, String>).value;
      final result = stmt.get([999]);
      expect(result, isA<Success<Map<String, Object?>?, String>>());
      final row = (result as Success<Map<String, Object?>?, String>).value;
      expect(row, isNull);
    });

    test('uses parameters correctly', () {
      final stmtResult = db.prepare('SELECT * FROM users WHERE name = ?');
      final stmt = (stmtResult as Success<Statement, String>).value;
      final result = stmt.get(['Bob']);
      final row = (result as Success<Map<String, Object?>?, String>).value;
      expect(row, isNotNull);
      expect(row!['name'], 'Bob');
      expect(row['age'], 25);
    });
  });

  group('Statement.all', () {
    late Database db;

    setUp(() {
      final result = openDatabase(':memory:');
      db = (result as Success<Database, String>).value;
      db.exec('''
        CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);
        INSERT INTO users (name, age) VALUES ('Alice', 30);
        INSERT INTO users (name, age) VALUES ('Bob', 25);
        INSERT INTO users (name, age) VALUES ('Charlie', 35);
      ''');
    });

    tearDown(() {
      db.close();
    });

    test('returns all rows', () {
      final stmtResult = db.prepare('SELECT * FROM users ORDER BY id');
      final stmt = (stmtResult as Success<Statement, String>).value;
      final result = stmt.all();
      expect(result, isA<Success<List<Map<String, Object?>>, String>>());
      final rows =
          (result as Success<List<Map<String, Object?>>, String>).value;
      expect(rows.length, 3);
      expect(rows[0]['name'], 'Alice');
      expect(rows[1]['name'], 'Bob');
      expect(rows[2]['name'], 'Charlie');
    });

    test('returns empty list for no results', () {
      final stmtResult = db.prepare('SELECT * FROM users WHERE age > ?');
      final stmt = (stmtResult as Success<Statement, String>).value;
      final result = stmt.all([100]);
      final rows =
          (result as Success<List<Map<String, Object?>>, String>).value;
      expect(rows, isEmpty);
    });

    test('filters with parameters', () {
      final stmtResult = db.prepare('SELECT * FROM users WHERE age >= ?');
      final stmt = (stmtResult as Success<Statement, String>).value;
      final result = stmt.all([30]);
      final rows =
          (result as Success<List<Map<String, Object?>>, String>).value;
      expect(rows.length, 2);
    });
  });

  group('Database.close', () {
    test('closes database successfully', () {
      final openResult = openDatabase(':memory:');
      final db = (openResult as Success<Database, String>).value;
      expect(db.isOpen(), true);

      final closeResult = db.close();
      expect(closeResult, isA<Success<void, String>>());
      expect(db.isOpen(), false);
    });
  });

  group('Database.pragma', () {
    late Database db;

    setUp(() {
      final result = openDatabase(':memory:');
      db = (result as Success<Database, String>).value;
    });

    tearDown(() {
      db.close();
    });

    test('sets pragma successfully', () {
      final result = db.pragma('cache_size = 10000');
      expect(result, isA<Success<void, String>>());
    });
  });

  group('Data types', () {
    late Database db;

    setUp(() {
      final result = openDatabase(':memory:');
      db = (result as Success<Database, String>).value;
      db.exec('''
        CREATE TABLE types_test (
          id INTEGER PRIMARY KEY,
          int_col INTEGER,
          real_col REAL,
          text_col TEXT,
          blob_col BLOB,
          null_col TEXT
        )
      ''');
    });

    tearDown(() {
      db.close();
    });

    test('handles integer values', () {
      final insertResult = db.prepare(
        'INSERT INTO types_test (int_col) VALUES (?)',
      );
      final stmt = (insertResult as Success<Statement, String>).value;
      stmt.run([42]);

      final selectResult = db.prepare('SELECT int_col FROM types_test');
      final selectStmt = (selectResult as Success<Statement, String>).value;
      final row =
          (selectStmt.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['int_col'], 42);
    });

    test('handles real/double values', () {
      final insertResult = db.prepare(
        'INSERT INTO types_test (real_col) VALUES (?)',
      );
      final stmt = (insertResult as Success<Statement, String>).value;
      stmt.run([3.14159]);

      final selectResult = db.prepare('SELECT real_col FROM types_test');
      final selectStmt = (selectResult as Success<Statement, String>).value;
      final row =
          (selectStmt.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['real_col'], closeTo(3.14159, 0.00001));
    });

    test('handles text values', () {
      final insertResult = db.prepare(
        'INSERT INTO types_test (text_col) VALUES (?)',
      );
      final stmt = (insertResult as Success<Statement, String>).value;
      stmt.run(['Hello, World!']);

      final selectResult = db.prepare('SELECT text_col FROM types_test');
      final selectStmt = (selectResult as Success<Statement, String>).value;
      final row =
          (selectStmt.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['text_col'], 'Hello, World!');
    });

    test('handles null values', () {
      final insertResult = db.prepare(
        'INSERT INTO types_test (null_col) VALUES (?)',
      );
      final stmt = (insertResult as Success<Statement, String>).value;
      stmt.run([null]);

      final selectResult = db.prepare('SELECT null_col FROM types_test');
      final selectStmt = (selectResult as Success<Statement, String>).value;
      final row =
          (selectStmt.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['null_col'], isNull);
    });

    test('handles large integers', () {
      final insertResult = db.prepare(
        'INSERT INTO types_test (int_col) VALUES (?)',
      );
      final stmt = (insertResult as Success<Statement, String>).value;
      stmt.run([9007199254740991]); // Max safe integer in JS

      final selectResult = db.prepare('SELECT int_col FROM types_test');
      final selectStmt = (selectResult as Success<Statement, String>).value;
      final row =
          (selectStmt.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['int_col'], 9007199254740991);
    });
  });

  group('Transactions', () {
    late Database db;

    setUp(() {
      final result = openDatabase(':memory:');
      db = (result as Success<Database, String>).value;
      db.exec('''
        CREATE TABLE accounts (id INTEGER PRIMARY KEY, balance INTEGER)
      ''');
      db.exec('INSERT INTO accounts (balance) VALUES (100)');
    });

    tearDown(() {
      db.close();
    });

    test('commits transaction', () {
      db.exec('BEGIN');
      final updateResult = db.prepare('UPDATE accounts SET balance = ?');
      final stmt = (updateResult as Success<Statement, String>).value;
      stmt.run([200]);
      db.exec('COMMIT');

      final selectResult = db.prepare('SELECT balance FROM accounts');
      final selectStmt = (selectResult as Success<Statement, String>).value;
      final getResult = selectStmt.get();
      expect(getResult, isA<Success<Map<String, Object?>?, String>>());
      final row = (getResult as Success<Map<String, Object?>?, String>).value;
      expect(row!['balance'], 200);
    });

    test('rolls back transaction', () {
      db.exec('BEGIN');
      final updateResult = db.prepare('UPDATE accounts SET balance = ?');
      final stmt = (updateResult as Success<Statement, String>).value;
      stmt.run([200]);
      db.exec('ROLLBACK');

      final selectResult = db.prepare('SELECT balance FROM accounts');
      final selectStmt = (selectResult as Success<Statement, String>).value;
      final getResult = selectStmt.get();
      expect(getResult, isA<Success<Map<String, Object?>?, String>>());
      final row = (getResult as Success<Map<String, Object?>?, String>).value;
      expect(row!['balance'], 100);
    });
  });

  group('Constraints', () {
    late Database db;

    setUp(() {
      final result = openDatabase(':memory:');
      db = (result as Success<Database, String>).value;
      db.exec('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY,
          email TEXT UNIQUE NOT NULL
        )
      ''');
    });

    tearDown(() {
      db.close();
    });

    test('enforces UNIQUE constraint', () {
      final stmtResult = db.prepare('INSERT INTO users (email) VALUES (?)');
      final stmt = (stmtResult as Success<Statement, String>).value;
      stmt.run(['alice@example.com']);
      final result = stmt.run(['alice@example.com']);
      expect(result, isA<Error<RunResult, String>>());
    });

    test('enforces NOT NULL constraint', () {
      final stmtResult = db.prepare('INSERT INTO users (email) VALUES (?)');
      final stmt = (stmtResult as Success<Statement, String>).value;
      final result = stmt.run([null]);
      expect(result, isA<Error<RunResult, String>>());
    });
  });
}
