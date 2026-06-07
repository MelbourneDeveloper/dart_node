/// Integration tests for dart_node_sql_js on Node.js.
library;

import 'dart:js_interop';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_sql_js/dart_node_sql_js.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

extension type _Fs(JSObject _) implements JSObject {
  external void unlinkSync(String path);
  external bool existsSync(String path);
  external void writeFileSync(String path, String data);
  external void mkdirSync(String path);
  external void rmdirSync(String path);
}

final _Fs _fs = _Fs(requireModule('fs') as JSObject);

const String _dbPath = '.test_sql_js.db';
const String _reopenPath = '.test_sql_js_reopen.db';
const String _savePath = '.test_sql_js_save.db';
const String _dirPath = '.test_sql_js_dir.db';
const String _badDirPath = '/nonexistent_dir_sql_js/test.db';

void _deleteIfExists(String path) {
  try {
    if (_fs.existsSync(path)) {
      _fs.unlinkSync(path);
    }
  } catch (_) {
    // Ignore cleanup errors
  }
}

SqlJsRuntime _runtimeOf(Result<SqlJsRuntime, String> result) =>
    (result as Success<SqlJsRuntime, String>).value;

Database _databaseOf(Result<Database, String> result) =>
    (result as Success<Database, String>).value;

Statement _statementOf(Result<Statement, String> result) =>
    (result as Success<Statement, String>).value;

void main() {
  late SqlJsRuntime runtime;

  setUpAll(() async {
    runtime = _runtimeOf(await initializeSqlJs());
  });

  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('initializeSqlJs', () {
    test('returns a runtime with a database constructor', () async {
      final result = await initializeSqlJs();
      expect(result, isA<Success<SqlJsRuntime, String>>());
    });
  });

  group('openDatabase', () {
    test('creates a new database when the file does not exist', () {
      _deleteIfExists(_dbPath);
      final db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
      expect(db.isOpen(), true);
      db.close();
      _deleteIfExists(_dbPath);
    });

    test('loads an existing database file', () {
      _deleteIfExists(_reopenPath);
      final first = _databaseOf(openDatabase(_reopenPath, sqlJs: runtime));
      first.exec('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
      final insert = _statementOf(
        first.prepare('INSERT INTO t (v) VALUES (?)'),
      );
      insert.run(['persisted']);
      first.close();

      expect(_fs.existsSync(_reopenPath), true);

      final reopened = _databaseOf(openDatabase(_reopenPath, sqlJs: runtime));
      final query = _statementOf(reopened.prepare('SELECT v FROM t'));
      final row = (query.get() as Success<Map<String, Object?>?, String>).value;
      expect(row, isNotNull);
      expect(row!['v'], 'persisted');
      reopened.close();
      _deleteIfExists(_reopenPath);
    });

    test('returns error when the path cannot be read', () {
      _deleteIfExists(_dirPath);
      _fs.mkdirSync(_dirPath);
      final result = openDatabase(_dirPath, sqlJs: runtime);
      expect(result, isA<Error<Database, String>>());
      _fs.rmdirSync(_dirPath);
    });

    test('save persists changes that survive reopen', () {
      _deleteIfExists(_savePath);
      final db = _databaseOf(openDatabase(_savePath, sqlJs: runtime));
      db.exec('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
      final insert = _statementOf(db.prepare('INSERT INTO t (v) VALUES (?)'));
      insert.run(['flushed']);
      final saveResult = db.save();
      expect(saveResult, isA<Success<void, String>>());

      final reopened = _databaseOf(openDatabase(_savePath, sqlJs: runtime));
      final query = _statementOf(reopened.prepare('SELECT v FROM t'));
      final row = (query.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['v'], 'flushed');
      reopened.close();
      _deleteIfExists(_savePath);
    });
  });

  group('Database.exec', () {
    late Database db;

    setUp(() {
      _deleteIfExists(_dbPath);
      db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
    });

    tearDown(() {
      db.close();
      _deleteIfExists(_dbPath);
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
      _deleteIfExists(_dbPath);
      db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
      db.exec('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
    });

    tearDown(() {
      db.close();
      _deleteIfExists(_dbPath);
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
      _deleteIfExists(_dbPath);
      db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
      db.exec('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
      insertStmt = _statementOf(
        db.prepare('INSERT INTO users (name) VALUES (?)'),
      );
    });

    tearDown(() {
      db.close();
      _deleteIfExists(_dbPath);
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
      final stmt = _statementOf(db.prepare('UPDATE users SET name = ?'));
      final result = stmt.run(['Updated']);
      final runResult = (result as Success<RunResult, String>).value;
      expect(runResult.changes, 2);
    });

    test('deletes rows and returns changes count', () {
      insertStmt.run(['Alice']);
      insertStmt.run(['Bob']);
      final stmt = _statementOf(db.prepare('DELETE FROM users'));
      final result = stmt.run();
      final runResult = (result as Success<RunResult, String>).value;
      expect(runResult.changes, 2);
    });
  });

  group('Statement.get', () {
    late Database db;

    setUp(() {
      _deleteIfExists(_dbPath);
      db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
      db.exec('''
        CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);
        INSERT INTO users (name, age) VALUES ('Alice', 30);
        INSERT INTO users (name, age) VALUES ('Bob', 25);
      ''');
    });

    tearDown(() {
      db.close();
      _deleteIfExists(_dbPath);
    });

    test('returns first row', () {
      final stmt = _statementOf(db.prepare('SELECT * FROM users ORDER BY id'));
      final result = stmt.get();
      expect(result, isA<Success<Map<String, Object?>?, String>>());
      final row = (result as Success<Map<String, Object?>?, String>).value;
      expect(row, isNotNull);
      expect(row!['name'], 'Alice');
      expect(row['age'], 30);
    });

    test('returns null for no results', () {
      final stmt = _statementOf(db.prepare('SELECT * FROM users WHERE id = ?'));
      final result = stmt.get([999]);
      expect(result, isA<Success<Map<String, Object?>?, String>>());
      final row = (result as Success<Map<String, Object?>?, String>).value;
      expect(row, isNull);
    });

    test('uses parameters correctly', () {
      final stmt = _statementOf(
        db.prepare('SELECT * FROM users WHERE name = ?'),
      );
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
      _deleteIfExists(_dbPath);
      db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
      db.exec('''
        CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);
        INSERT INTO users (name, age) VALUES ('Alice', 30);
        INSERT INTO users (name, age) VALUES ('Bob', 25);
        INSERT INTO users (name, age) VALUES ('Charlie', 35);
      ''');
    });

    tearDown(() {
      db.close();
      _deleteIfExists(_dbPath);
    });

    test('returns all rows', () {
      final stmt = _statementOf(db.prepare('SELECT * FROM users ORDER BY id'));
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
      final stmt = _statementOf(
        db.prepare('SELECT * FROM users WHERE age > ?'),
      );
      final result = stmt.all([100]);
      final rows =
          (result as Success<List<Map<String, Object?>>, String>).value;
      expect(rows, isEmpty);
    });

    test('filters with parameters', () {
      final stmt = _statementOf(
        db.prepare('SELECT * FROM users WHERE age >= ?'),
      );
      final result = stmt.all([30]);
      final rows =
          (result as Success<List<Map<String, Object?>>, String>).value;
      expect(rows.length, 2);
    });
  });

  group('Database.close', () {
    test('closes database successfully', () {
      _deleteIfExists(_dbPath);
      final db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
      expect(db.isOpen(), true);

      final closeResult = db.close();
      expect(closeResult, isA<Success<void, String>>());
      expect(db.isOpen(), false);
      _deleteIfExists(_dbPath);
    });

    test('returns error when the save target directory is missing', () {
      final db = _databaseOf(openDatabase(_badDirPath, sqlJs: runtime));
      final closeResult = db.close();
      expect(closeResult, isA<Error<void, String>>());
    });
  });

  group('Database.pragma', () {
    late Database db;

    setUp(() {
      _deleteIfExists(_dbPath);
      db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
    });

    tearDown(() {
      db.close();
      _deleteIfExists(_dbPath);
    });

    test('sets pragma successfully', () {
      final result = db.pragma('cache_size = 10000');
      expect(result, isA<Success<void, String>>());
    });

    test('returns error for invalid pragma', () {
      final result = db.pragma('= = =');
      expect(result, isA<Error<void, String>>());
    });
  });

  group('Data types', () {
    late Database db;

    setUp(() {
      _deleteIfExists(_dbPath);
      db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
      db.exec('''
        CREATE TABLE types_test (
          id INTEGER PRIMARY KEY,
          int_col INTEGER,
          real_col REAL,
          text_col TEXT,
          null_col TEXT
        )
      ''');
    });

    tearDown(() {
      db.close();
      _deleteIfExists(_dbPath);
    });

    test('handles integer values', () {
      final stmt = _statementOf(
        db.prepare('INSERT INTO types_test (int_col) VALUES (?)'),
      );
      stmt.run([42]);
      final select = _statementOf(db.prepare('SELECT int_col FROM types_test'));
      final row =
          (select.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['int_col'], 42);
    });

    test('handles real/double values', () {
      final stmt = _statementOf(
        db.prepare('INSERT INTO types_test (real_col) VALUES (?)'),
      );
      stmt.run([3.14159]);
      final select = _statementOf(
        db.prepare('SELECT real_col FROM types_test'),
      );
      final row =
          (select.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['real_col'], closeTo(3.14159, 0.00001));
    });

    test('handles text values', () {
      final stmt = _statementOf(
        db.prepare('INSERT INTO types_test (text_col) VALUES (?)'),
      );
      stmt.run(['Hello, World!']);
      final select = _statementOf(
        db.prepare('SELECT text_col FROM types_test'),
      );
      final row =
          (select.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['text_col'], 'Hello, World!');
    });

    test('handles null values', () {
      final stmt = _statementOf(
        db.prepare('INSERT INTO types_test (null_col) VALUES (?)'),
      );
      stmt.run([null]);
      final select = _statementOf(
        db.prepare('SELECT null_col FROM types_test'),
      );
      final row =
          (select.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['null_col'], isNull);
    });
  });

  group('Transactions', () {
    late Database db;

    setUp(() {
      _deleteIfExists(_dbPath);
      db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
      db.exec(
        'CREATE TABLE accounts (id INTEGER PRIMARY KEY, balance INTEGER)',
      );
      db.exec('INSERT INTO accounts (balance) VALUES (100)');
    });

    tearDown(() {
      db.close();
      _deleteIfExists(_dbPath);
    });

    test('commits transaction', () {
      db.exec('BEGIN');
      final stmt = _statementOf(db.prepare('UPDATE accounts SET balance = ?'));
      stmt.run([200]);
      db.exec('COMMIT');

      final select = _statementOf(db.prepare('SELECT balance FROM accounts'));
      final row =
          (select.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['balance'], 200);
    });

    test('rolls back transaction', () {
      db.exec('BEGIN');
      final stmt = _statementOf(db.prepare('UPDATE accounts SET balance = ?'));
      stmt.run([200]);
      db.exec('ROLLBACK');

      final select = _statementOf(db.prepare('SELECT balance FROM accounts'));
      final row =
          (select.get() as Success<Map<String, Object?>?, String>).value;
      expect(row!['balance'], 100);
    });
  });

  group('Constraints', () {
    late Database db;

    setUp(() {
      _deleteIfExists(_dbPath);
      db = _databaseOf(openDatabase(_dbPath, sqlJs: runtime));
      db.exec('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY,
          email TEXT UNIQUE NOT NULL
        )
      ''');
    });

    tearDown(() {
      db.close();
      _deleteIfExists(_dbPath);
    });

    test('enforces UNIQUE constraint', () {
      final stmt = _statementOf(
        db.prepare('INSERT INTO users (email) VALUES (?)'),
      );
      stmt.run(['alice@example.com']);
      final result = stmt.run(['alice@example.com']);
      expect(result, isA<Error<RunResult, String>>());
    });

    test('enforces NOT NULL constraint', () {
      final stmt = _statementOf(
        db.prepare('INSERT INTO users (email) VALUES (?)'),
      );
      final result = stmt.run([null]);
      expect(result, isA<Error<RunResult, String>>());
    });
  });
}
