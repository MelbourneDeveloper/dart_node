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
  Result<void, String> Function(String pragmaValue) pragma,

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
    _callPragma(jsDb, 'journal_mode = WAL');
    _callPragma(jsDb, 'busy_timeout = 5000');

    return Success(_createDatabase(jsDb));
  } catch (e) {
    return Error('Failed to open database: $e');
  }
}

Database _createDatabase(JSObject jsDb) => (
      prepare: (sql) => _dbPrepare(jsDb, sql),
      exec: (sql) => _dbExec(jsDb, sql),
      close: () => _dbClose(jsDb),
      pragma: (pragmaValue) => _dbPragma(jsDb, pragmaValue),
      isOpen: () => _dbIsOpen(jsDb),
    );

Result<Statement, String> _dbPrepare(JSObject jsDb, String sql) {
  try {
    final prepareFn = jsDb['prepare']! as JSFunction;
    final jsStmt = prepareFn.callAsFunction(jsDb, sql.toJS)! as JSObject;
    return Success(createStatement(jsStmt));
  } catch (e) {
    return Error('Failed to prepare statement: $e');
  }
}

Result<void, String> _dbExec(JSObject jsDb, String sql) {
  try {
    (jsDb['exec']! as JSFunction).callAsFunction(jsDb, sql.toJS);
    return const Success(null);
  } catch (e) {
    return Error('Failed to exec: $e');
  }
}

Result<void, String> _dbClose(JSObject jsDb) {
  try {
    (jsDb['close']! as JSFunction).callAsFunction(jsDb);
    return const Success(null);
  } catch (e) {
    return Error('Failed to close database: $e');
  }
}

Result<void, String> _dbPragma(JSObject jsDb, String pragmaValue) {
  try {
    (jsDb['pragma']! as JSFunction).callAsFunction(jsDb, pragmaValue.toJS);
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

void _callPragma(JSObject jsDb, String pragmaValue) {
  (jsDb['pragma']! as JSFunction).callAsFunction(jsDb, pragmaValue.toJS);
}
