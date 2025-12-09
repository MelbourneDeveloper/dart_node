/// Database bindings for better-sqlite3.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_better_sqlite3/src/statement.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:nadz/nadz.dart';

/// A better-sqlite3 database connection.
typedef Database = ({
  /// Prepare a SQL statement.
  Result<Statement, String> Function(String sql) prepare,

  /// Execute raw SQL (no results).
  Result<void, String> Function(String sql) exec,

  /// Close the database.
  Result<void, String> Function() close,

  /// Set a pragma value.
  Result<void, String> Function(String pragma) pragma,

  /// Check if database is open.
  bool Function() isOpen,
});

/// Open a better-sqlite3 database.
///
/// Automatically enables WAL mode and sets busy timeout.
Result<Database, String> openDatabase(String path) {
  try {
    final betterSqlite3 = requireModule('better-sqlite3');
    final dbClass = betterSqlite3 as JSFunction;
    final jsDb = dbClass.callAsConstructor<JSObject>(path.toJS);

    // Enable WAL mode for concurrency
    final pragmaFn = jsDb['pragma'] as JSFunction;
    pragmaFn.callAsFunction(jsDb, 'journal_mode = WAL'.toJS);
    pragmaFn.callAsFunction(jsDb, 'busy_timeout = 5000'.toJS);

    return Success(_createDatabase(jsDb));
  } catch (e) {
    return Error('Failed to open database: $e');
  }
}

Database _createDatabase(JSObject jsDb) => (
  prepare: (sql) => _dbPrepare(jsDb, sql),
  exec: (sql) => _dbExec(jsDb, sql),
  close: () => _dbClose(jsDb),
  pragma: (pragma) => _dbPragma(jsDb, pragma),
  isOpen: () => _dbIsOpen(jsDb),
);

Result<Statement, String> _dbPrepare(JSObject jsDb, String sql) {
  try {
    final prepareFn = jsDb['prepare'] as JSFunction;
    final jsStmt = prepareFn.callAsFunction(jsDb, sql.toJS) as JSObject;
    return Success(createStatement(jsStmt));
  } catch (e) {
    return Error('Failed to prepare statement: $e');
  }
}

Result<void, String> _dbExec(JSObject jsDb, String sql) {
  try {
    final execFn = jsDb['exec'] as JSFunction;
    execFn.callAsFunction(jsDb, sql.toJS);
    return const Success(null);
  } catch (e) {
    return Error('Failed to exec: $e');
  }
}

Result<void, String> _dbClose(JSObject jsDb) {
  try {
    final closeFn = jsDb['close'] as JSFunction;
    closeFn.callAsFunction(jsDb);
    return const Success(null);
  } catch (e) {
    return Error('Failed to close database: $e');
  }
}

Result<void, String> _dbPragma(JSObject jsDb, String pragma) {
  try {
    final pragmaFn = jsDb['pragma'] as JSFunction;
    pragmaFn.callAsFunction(jsDb, pragma.toJS);
    return const Success(null);
  } catch (e) {
    return Error('Failed to set pragma: $e');
  }
}

bool _dbIsOpen(JSObject jsDb) {
  try {
    final openProp = jsDb['open'];
    if (openProp == null || openProp.isUndefinedOrNull) return false;
    return (openProp as JSBoolean).toDart;
  } catch (_) {
    return false;
  }
}
