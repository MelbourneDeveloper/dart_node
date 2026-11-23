/// Statement bindings for better-sqlite3.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_better_sqlite3/src/types.dart';
import 'package:nadz/nadz.dart';

/// A prepared SQL statement.
typedef Statement = ({
  /// Execute and return all rows.
  Result<List<Map<String, Object?>>, String> Function([
    List<Object?>? params,
  ]) all,

  /// Execute and return first row or null.
  Result<Map<String, Object?>?, String> Function([List<Object?>? params]) get,

  /// Execute and return changes/lastInsertRowid.
  Result<RunResult, String> Function([List<Object?>? params]) run,
});

/// Create a Statement from a JS object.
Statement createStatement(JSObject jsStmt) => (
      all: ([params]) => _stmtAll(jsStmt, params),
      get: ([params]) => _stmtGet(jsStmt, params),
      run: ([params]) => _stmtRun(jsStmt, params),
    );

JSAny? _jsifyParam(Object? p) => p.jsify();

Result<List<Map<String, Object?>>, String> _stmtAll(
  JSObject jsStmt,
  List<Object?>? params,
) {
  try {
    final allFn = jsStmt['all']! as JSFunction;
    final jsParams = params?.map(_jsifyParam).toList().toJS;
    final result = jsParams != null
        ? allFn.callAsFunction(jsStmt, jsParams)!
        : allFn.callAsFunction(jsStmt)!;
    final jsArray = result as JSArray<JSAny?>;
    final rows = <Map<String, Object?>>[];
    for (var i = 0; i < jsArray.length; i++) {
      final jsRow = jsArray[i]! as JSObject;
      final row = _convertRow(jsRow.dartify()) ?? {};
      rows.add(row);
    }
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
    final getFn = jsStmt['get']! as JSFunction;
    final jsParams = params?.map(_jsifyParam).toList().toJS;
    final result = jsParams != null
        ? getFn.callAsFunction(jsStmt, jsParams)
        : getFn.callAsFunction(jsStmt);
    if (result == null || result.isUndefinedOrNull) return const Success(null);
    final jsRow = result as JSObject;
    final row = _convertRow(jsRow.dartify());
    return Success(row);
  } catch (e) {
    return Error('Statement.get failed: $e');
  }
}

Result<RunResult, String> _stmtRun(JSObject jsStmt, List<Object?>? params) {
  try {
    final runFn = jsStmt['run']! as JSFunction;
    final jsParams = params?.map(_jsifyParam).toList().toJS;
    final result = jsParams != null
        ? runFn.callAsFunction(jsStmt, jsParams)!
        : runFn.callAsFunction(jsStmt)!;
    final jsResult = result as JSObject;
    final changes = (jsResult['changes']! as JSNumber).toDartInt;
    final lastId = jsResult['lastInsertRowid'];
    final lastInsertRowid = lastId != null && !lastId.isUndefinedOrNull
        ? (lastId as JSNumber).toDartInt
        : 0;
    return Success((changes: changes, lastInsertRowid: lastInsertRowid));
  } catch (e) {
    return Error('Statement.run failed: $e');
  }
}
