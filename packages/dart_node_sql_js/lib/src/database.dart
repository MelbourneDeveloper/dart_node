/// Database bindings for sql.js (SQLite compiled to WebAssembly).
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_sql_js/src/statement.dart';
import 'package:nadz/nadz.dart';

/// Typed view over the sql.js runtime namespace returned by `initSqlJs()`.
extension type _SqlJsNamespace(JSObject _) implements JSObject {
  @JS('Database')
  external JSFunction get databaseConstructor;
}

/// Typed view over a sql.js `Database` instance.
extension type SqlJsDatabase(JSObject _) implements JSObject {
  /// Run a statement that returns no rows (e.g. `PRAGMA`).
  external void run(String sql);

  /// Prepare a statement for repeated execution.
  external SqlJsStatement prepare(String sql);

  /// Execute one or more statements, ignoring any result set.
  external void exec(String sql);

  /// Serialize the in-memory database to bytes.
  external JSUint8Array export();

  /// Release the database and its associated memory.
  external void close();

  /// Number of rows modified by the most recently executed statement.
  external int getRowsModified();
}

/// Typed view over the Node.js `fs` module (binary file operations).
extension type _BinaryFs(JSObject _) implements JSObject {
  external bool existsSync(String path);
  external JSUint8Array readFileSync(String path);
  external void writeFileSync(String path, JSUint8Array data);
}

final _BinaryFs _fs = _BinaryFs(requireModule('fs') as JSObject);

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
    final promise = initFn.callAsFunction();
    if (promise == null) {
      return const Error('sql.js init returned no promise');
    }
    final namespace = await (promise as JSPromise<JSAny?>).toDart;
    if (namespace == null) {
      return const Error('sql.js init resolved to null');
    }
    final sqlJs = namespace as _SqlJsNamespace;
    return Success((databaseConstructor: sqlJs.databaseConstructor));
  } catch (e) {
    return Error('Failed to initialize sql.js: $e');
  }
}

/// A sql.js database connection.
///
/// sql.js is entirely in-memory. Because `export()` (the only way to
/// serialize) frees every live prepared statement, changes are NOT written
/// after each operation. Call `save` to flush to disk on demand, or rely on
/// `close`, which saves before closing.
typedef Database = ({
  /// Prepare a SQL statement.
  Result<Statement, String> Function(String sql) prepare,

  /// Execute raw SQL (no results).
  Result<void, String> Function(String sql) exec,

  /// Persist the in-memory database to its backing file.
  Result<void, String> Function() save,

  /// Close the database, persisting it to disk first.
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
/// Changes are persisted to [path] on `save` and `close`.
Result<Database, String> openDatabase(
  String path, {
  required SqlJsRuntime sqlJs,
}) {
  try {
    final fileExists = _fs.existsSync(path);
    // sql.js is in-memory; WAL and busy_timeout do not apply.
    // Enable foreign keys for referential integrity.
    final jsDb =
        (fileExists
              ? sqlJs.databaseConstructor.callAsConstructor<SqlJsDatabase>(
                  _fs.readFileSync(path),
                )
              : sqlJs.databaseConstructor.callAsConstructor<SqlJsDatabase>())
          ..run('PRAGMA foreign_keys = ON');

    return Success(_createDatabase(jsDb, path));
  } catch (e) {
    return Error('Failed to open database: $e');
  }
}

/// Persist the in-memory database to disk.
void _save(SqlJsDatabase jsDb, String path) {
  _fs.writeFileSync(path, jsDb.export());
}

Database _createDatabase(SqlJsDatabase jsDb, String path) {
  var open = true;

  return (
    prepare: (sql) => _dbPrepare(jsDb, sql),
    exec: (sql) => _dbExec(jsDb, sql),
    save: () => _dbSave(jsDb, path),
    close: () => _dbClose(jsDb, path, () => open = false),
    pragma: (pragmaValue) => _dbPragma(jsDb, pragmaValue),
    isOpen: () => open,
  );
}

Result<Statement, String> _dbPrepare(SqlJsDatabase jsDb, String sql) {
  try {
    final jsStmt = jsDb.prepare(sql);
    return Success(createStatement(jsStmt, jsDb));
  } catch (e) {
    return Error('Failed to prepare statement: $e');
  }
}

Result<void, String> _dbExec(SqlJsDatabase jsDb, String sql) {
  try {
    // sql.js exec() handles multiple statements separated by ;
    jsDb.exec(sql);
    return const Success(null);
  } catch (e) {
    return Error('Failed to exec: $e');
  }
}

Result<void, String> _dbSave(SqlJsDatabase jsDb, String path) {
  try {
    _save(jsDb, path);
    return const Success(null);
  } catch (e) {
    return Error('Failed to save: $e');
  }
}

Result<void, String> _dbClose(
  SqlJsDatabase jsDb,
  String path,
  void Function() markClosed,
) {
  try {
    _save(jsDb, path);
    jsDb.close();
    markClosed();
    return const Success(null);
  } catch (e) {
    return Error('Failed to close database: $e');
  }
}

Result<void, String> _dbPragma(SqlJsDatabase jsDb, String pragmaValue) {
  try {
    jsDb.run('PRAGMA $pragmaValue');
    return const Success(null);
  } catch (e) {
    return Error('Failed to set pragma: $e');
  }
}
