/// Statement bindings for sql.js.
library;

import 'dart:js_interop';

import 'package:dart_node_sql_js/src/database.dart';
import 'package:dart_node_sql_js/src/types.dart';
import 'package:nadz/nadz.dart';

/// Typed view over a sql.js prepared `Statement` instance.
extension type SqlJsStatement(JSObject _) implements JSObject {
  /// Bind positional parameters to the statement.
  external void bind(JSArray<JSAny?> values);

  /// Advance to the next row. Returns false when exhausted.
  external bool step();

  /// Return the current row as a column-keyed object.
  external JSObject getAsObject();

  /// Reset the statement so it can be executed again.
  external void reset();

  /// Release the statement and its memory.
  external void free();
}

/// A prepared SQL statement.
typedef Statement = ({
  /// Execute and return all rows.
  Result<List<Map<String, Object?>>, String> Function([List<Object?>? params])
  all,

  /// Execute and return first row or null.
  Result<Map<String, Object?>?, String> Function([List<Object?>? params]) get,

  /// Execute and return changes/lastInsertRowid.
  Result<RunResult, String> Function([List<Object?>? params]) run,
});

/// Create a Statement from a sql.js prepared statement.
///
/// [jsStmt] is the sql.js Statement object.
/// [jsDb] is the sql.js Database object (needed for getRowsModified).
Statement createStatement(SqlJsStatement jsStmt, SqlJsDatabase jsDb) => (
  all: ([params]) => _stmtAll(jsStmt, params),
  get: ([params]) => _stmtGet(jsStmt, params),
  run: ([params]) => _stmtRun(jsStmt, jsDb, params),
);

void _bindParams(SqlJsStatement jsStmt, List<Object?>? params) {
  if (params != null && params.isNotEmpty) {
    jsStmt.bind(params.map(_jsifyParam).toList().toJS);
  }
}

JSAny? _jsifyParam(Object? p) => p.jsify();

Result<List<Map<String, Object?>>, String> _stmtAll(
  SqlJsStatement jsStmt,
  List<Object?>? params,
) {
  try {
    _bindParams(jsStmt, params);

    final rows = <Map<String, Object?>>[];
    while (jsStmt.step()) {
      final row = _convertRow(jsStmt.getAsObject().dartify());
      if (row != null) rows.add(row);
    }
    jsStmt.reset();

    return Success(rows);
  } catch (e) {
    return Error('Statement.all failed: $e');
  }
}

Map<String, Object?>? _convertRow(Object? dartified) {
  if (dartified == null) return null;
  final map = dartified as Map<Object?, Object?>;
  return map.map((k, v) => MapEntry(k.toString(), v));
}

Result<Map<String, Object?>?, String> _stmtGet(
  SqlJsStatement jsStmt,
  List<Object?>? params,
) {
  try {
    _bindParams(jsStmt, params);

    if (!jsStmt.step()) {
      jsStmt.reset();
      return const Success(null);
    }
    final row = _convertRow(jsStmt.getAsObject().dartify());
    jsStmt.reset();

    return Success(row);
  } catch (e) {
    return Error('Statement.get failed: $e');
  }
}

Result<RunResult, String> _stmtRun(
  SqlJsStatement jsStmt,
  SqlJsDatabase jsDb,
  List<Object?>? params,
) {
  try {
    _bindParams(jsStmt, params);

    jsStmt
      ..step()
      ..reset();

    final changes = jsDb.getRowsModified();
    final lastInsertRowid = _lastInsertRowid(jsDb);

    return Success((changes: changes, lastInsertRowid: lastInsertRowid));
  } catch (e) {
    return Error('Statement.run failed: $e');
  }
}

/// Read the rowid of the most recent insert via `last_insert_rowid()`.
///
/// Uses a dedicated statement that is freed immediately so it never
/// interferes with the caller's live statements.
int _lastInsertRowid(SqlJsDatabase jsDb) {
  final stmt = jsDb.prepare('SELECT last_insert_rowid() AS id');
  final id = stmt.step() ? _rowidValue(stmt) : 0;
  stmt.free();
  return id;
}

int _rowidValue(SqlJsStatement stmt) {
  final value = _convertRow(stmt.getAsObject().dartify())?['id'];
  return value is num ? value.toInt() : 0;
}
