/// Statement bindings for sql.js.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_sql_js/src/types.dart';
import 'package:nadz/nadz.dart';

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
/// [onWrite] is called after run() to persist changes to disk.
Statement createStatement(
  JSObject jsStmt,
  JSObject jsDb, {
  void Function()? onWrite,
}) => (
  all: ([params]) => _stmtAll(jsStmt, params),
  get: ([params]) => _stmtGet(jsStmt, params),
  run: ([params]) => _stmtRun(jsStmt, jsDb, params, onWrite),
);

void _bindParams(JSObject jsStmt, List<Object?>? params) {
  final bindFn = jsStmt['bind'] as JSFunction;
  if (params != null && params.isNotEmpty) {
    bindFn.callAsFunction(jsStmt, params.map(_jsifyParam).toList().toJS);
  } else {
    // Reset bindings for parameterless execution
    bindFn.callAsFunction(jsStmt);
  }
}

JSAny? _jsifyParam(Object? p) => p.jsify();

Result<List<Map<String, Object?>>, String> _stmtAll(
  JSObject jsStmt,
  List<Object?>? params,
) {
  try {
    _bindParams(jsStmt, params);

    final stepFn = jsStmt['step'] as JSFunction;
    final getAsObjectFn = jsStmt['getAsObject'] as JSFunction;
    final resetFn = jsStmt['reset'] as JSFunction;

    final rows = <Map<String, Object?>>[];
    while ((stepFn.callAsFunction(jsStmt) as JSBoolean).toDart) {
      final jsRow = getAsObjectFn.callAsFunction(jsStmt) as JSObject;
      final row = _convertRow(jsRow.dartify());
      if (row != null) rows.add(row);
    }
    resetFn.callAsFunction(jsStmt);

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
  JSObject jsStmt,
  List<Object?>? params,
) {
  try {
    _bindParams(jsStmt, params);

    final stepFn = jsStmt['step'] as JSFunction;
    final getAsObjectFn = jsStmt['getAsObject'] as JSFunction;
    final resetFn = jsStmt['reset'] as JSFunction;

    final hasRow = (stepFn.callAsFunction(jsStmt) as JSBoolean).toDart;
    if (!hasRow) {
      resetFn.callAsFunction(jsStmt);
      return const Success(null);
    }
    final jsRow = getAsObjectFn.callAsFunction(jsStmt) as JSObject;
    final row = _convertRow(jsRow.dartify());
    resetFn.callAsFunction(jsStmt);

    return Success(row);
  } catch (e) {
    return Error('Statement.get failed: $e');
  }
}

Result<RunResult, String> _stmtRun(
  JSObject jsStmt,
  JSObject jsDb,
  List<Object?>? params,
  void Function()? onWrite,
) {
  try {
    _bindParams(jsStmt, params);

    final stepFn = jsStmt['step'] as JSFunction;
    final resetFn = jsStmt['reset'] as JSFunction;

    // Execute the statement
    stepFn.callAsFunction(jsStmt);
    resetFn.callAsFunction(jsStmt);

    // Get changes from the database object
    final getRowsModifiedFn = jsDb['getRowsModified'] as JSFunction;
    final changes =
        (getRowsModifiedFn.callAsFunction(jsDb) as JSNumber).toDartInt;

    // Get last insert rowid via exec
    final execFn = jsDb['exec'] as JSFunction;
    final rowidResult =
        execFn.callAsFunction(jsDb, 'SELECT last_insert_rowid() as id'.toJS)
            as JSArray<JSAny?>;

    var lastInsertRowid = 0;
    if (rowidResult.length > 0) {
      final resultObj = rowidResult[0] as JSObject;
      final values = resultObj['values'] as JSArray<JSAny?>;
      if (values.length > 0) {
        final firstRow = values[0] as JSArray<JSAny?>;
        if (firstRow.length > 0) {
          final val = firstRow[0];
          if (val != null && !val.isUndefinedOrNull) {
            lastInsertRowid = (val as JSNumber).toDartInt;
          }
        }
      }
    }

    onWrite?.call();
    return Success((changes: changes, lastInsertRowid: lastInsertRowid));
  } catch (e) {
    return Error('Statement.run failed: $e');
  }
}
