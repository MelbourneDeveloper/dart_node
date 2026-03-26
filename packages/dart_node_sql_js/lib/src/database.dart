/// Database bindings for sql.js (SQLite compiled to WebAssembly).
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_sql_js/src/statement.dart';
import 'package:nadz/nadz.dart';

/// Pre-initialized sql.js runtime.
///
/// Obtained from [initializeSqlJs], passed to [openDatabase].
typedef SqlJsRuntime = ({JSFunction databaseConstructor});

/// Initialize sql.js. Call once at startup.
///
/// Returns a [SqlJsRuntime] that must be passed to [openDatabase].
Future<Result<SqlJsRuntime, String>> initializeSqlJs() async {
  try {
    final initFn = requireModule('sql.js') as JSFunction;
    final promise = initFn.callAsFunction(null) as JSPromise<JSAny?>;
    final sqlJs = await promise.toDart as JSObject;
    final dbConstructor = sqlJs['Database'] as JSFunction;
    return Success((databaseConstructor: dbConstructor));
  } catch (e) {
    return Error('Failed to initialize sql.js: $e');
  }
}

/// A sql.js database connection.
typedef Database = ({
  /// Prepare a SQL statement.
  Result<Statement, String> Function(String sql) prepare,

  /// Execute raw SQL (no results).
  Result<void, String> Function(String sql) exec,

  /// Close the database.
  Result<void, String> Function() close,

  /// Set a pragma value.
  Result<void, String> Function(String pragmaValue) pragma,

  /// Check if database is open.
  bool Function() isOpen,
});

/// Open a sql.js database.
///
/// If [path] points to an existing file, loads it.
/// Otherwise creates a new empty database.
/// Auto-persists to disk after write operations.
Result<Database, String> openDatabase(
  String path, {
  required SqlJsRuntime sqlJs,
}) {
  try {
    final fs = requireModule('fs') as JSObject;
    final existsSyncFn = fs['existsSync'] as JSFunction;
    final readFileSyncFn = fs['readFileSync'] as JSFunction;

    JSObject jsDb;
    final fileExists =
        (existsSyncFn.callAsFunction(fs, path.toJS) as JSBoolean).toDart;

    if (fileExists) {
      final buffer = readFileSyncFn.callAsFunction(fs, path.toJS);
      jsDb = sqlJs.databaseConstructor
          .callAsConstructor<JSObject>(buffer);
    } else {
      jsDb = sqlJs.databaseConstructor.callAsConstructor<JSObject>();
    }

    // sql.js is in-memory; WAL and busy_timeout do not apply.
    // Enable foreign keys for referential integrity.
    _dbRun(jsDb, 'PRAGMA foreign_keys = ON');

    return Success(_createDatabase(jsDb, path, fs));
  } catch (e) {
    return Error('Failed to open database: $e');
  }
}

/// Run a SQL statement directly on the JS database object.
void _dbRun(JSObject jsDb, String sql) {
  (jsDb['run'] as JSFunction).callAsFunction(jsDb, sql.toJS);
}

/// Persist the in-memory database to disk.
void _save(JSObject jsDb, String path, JSObject fs) {
  final exportFn = jsDb['export'] as JSFunction;
  final data = exportFn.callAsFunction(jsDb);

  final bufferClass = requireModule('buffer') as JSObject;
  final bufferFrom =
      (bufferClass['Buffer'] as JSObject)['from'] as JSFunction;
  final nodeBuffer = bufferFrom.callAsFunction(null, data);

  final writeFileSyncFn = fs['writeFileSync'] as JSFunction;
  writeFileSyncFn.callAsFunction(fs, path.toJS, nodeBuffer);
}

Database _createDatabase(JSObject jsDb, String path, JSObject fs) {
  var open = true;

  return (
    prepare: (sql) => _dbPrepare(jsDb, sql, path, fs),
    exec: (sql) => _dbExec(jsDb, sql, path, fs),
    close: () => _dbClose(jsDb, path, fs, () => open = false),
    pragma: (pragmaValue) => _dbPragma(jsDb, pragmaValue),
    isOpen: () => open,
  );
}

Result<Statement, String> _dbPrepare(
  JSObject jsDb,
  String sql,
  String path,
  JSObject fs,
) {
  try {
    final prepareFn = jsDb['prepare'] as JSFunction;
    final jsStmt =
        prepareFn.callAsFunction(jsDb, sql.toJS) as JSObject;
    return Success(
      createStatement(jsStmt, jsDb, onWrite: () => _save(jsDb, path, fs)),
    );
  } catch (e) {
    return Error('Failed to prepare statement: $e');
  }
}

Result<void, String> _dbExec(
  JSObject jsDb,
  String sql,
  String path,
  JSObject fs,
) {
  try {
    // sql.js exec() handles multiple statements separated by ;
    (jsDb['exec'] as JSFunction).callAsFunction(jsDb, sql.toJS);
    _save(jsDb, path, fs);
    return const Success(null);
  } catch (e) {
    return Error('Failed to exec: $e');
  }
}

Result<void, String> _dbClose(
  JSObject jsDb,
  String path,
  JSObject fs,
  void Function() markClosed,
) {
  try {
    _save(jsDb, path, fs);
    (jsDb['close'] as JSFunction).callAsFunction(jsDb);
    markClosed();
    return const Success(null);
  } catch (e) {
    return Error('Failed to close database: $e');
  }
}

Result<void, String> _dbPragma(JSObject jsDb, String pragmaValue) {
  try {
    _dbRun(jsDb, 'PRAGMA $pragmaValue');
    return const Success(null);
  } catch (e) {
    return Error('Failed to set pragma: $e');
  }
}
