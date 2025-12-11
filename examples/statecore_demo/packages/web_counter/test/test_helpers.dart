/// Test helpers for statecore demo tests.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/src/testing_library.dart';

/// Create a JSObject from a Dart map
JSObject createJSObject(Map<String, Object?> map) {
  final json = globalContext['JSON']! as JSObject;
  final parseFn = json['parse']! as JSFunction;
  final jsonStr = _toJsonString(map);
  return parseFn.callAsFunction(null, jsonStr.toJS)! as JSObject;
}

String _toJsonString(Map<String, Object?> map) {
  final entries = map.entries.map((e) {
    final value = e.value;
    String valueStr;
    if (value is String) {
      valueStr = '"$value"';
    } else if (value is bool) {
      valueStr = value.toString();
    } else if (value is num) {
      valueStr = value.toString();
    } else if (value == null) {
      valueStr = 'null';
    } else if (value is Map) {
      valueStr = _toJsonString(value.cast<String, Object?>());
    } else if (value is List) {
      valueStr = _toJsonList(value.cast<Object?>());
    } else {
      valueStr = '"$value"';
    }
    return '"${e.key}":$valueStr';
  });
  return '{${entries.join(',')}}';
}

String _toJsonList(List<Object?> list) {
  final items = list.map((item) {
    if (item is String) return '"$item"';
    if (item is num) return item.toString();
    if (item is bool) return item.toString();
    if (item == null) return 'null';
    if (item is Map) return _toJsonString(item.cast<String, Object?>());
    if (item is List) return _toJsonList(item.cast<Object?>());
    return '"$item"';
  });
  return '[${items.join(',')}]';
}

/// Wait for text to appear in rendered output
Future<void> waitForText(
  TestRenderResult result,
  String text, {
  int maxAttempts = 20,
  Duration interval = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxAttempts; i++) {
    if (result.container.textContent.contains(text)) return;
    await Future<void>.delayed(interval);
  }
  throw StateError('Text "$text" not found after $maxAttempts attempts');
}
