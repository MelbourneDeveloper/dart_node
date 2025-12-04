/// Test helpers and mock utilities for mobile app tests.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/src/testing_library.dart';
import 'package:mobile/types.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';

/// Create a mock AuthEffects for testing
AuthEffects createMockAuth({
  void Function(JSAny?)? onSetToken,
  void Function(JSAny?)? onSetUser,
  void Function(String)? onSetView,
}) => (
  setToken: onSetToken ?? (JSAny? _) {},
  setUser: onSetUser ?? (JSAny? _) {},
  setView: onSetView ?? (String _) {},
);

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
    } else if (value is int) {
      valueStr = value.toString();
    } else if (value is double) {
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
    if (item is bool) return item.toString();
    if (item is int) return item.toString();
    if (item is double) return item.toString();
    if (item == null) return 'null';
    if (item is Map) return _toJsonString(item.cast<String, Object?>());
    if (item is List) return _toJsonList(item.cast<Object?>());
    return '"$item"';
  });
  return '[${items.join(',')}]';
}

/// Create a mock JSTask for testing
JSTask createMockTask({
  required String id,
  required String title,
  bool completed = false,
}) => JSTask.fromJS(
  createJSObject({'id': id, 'title': title, 'completed': completed}),
);

/// Create a mock JSUser for testing
JSUser createMockUser({
  required String name,
  String email = 'test@example.com',
}) => JSUser.fromJS(createJSObject({'name': name, 'email': email}));

// --- Fetch Mock Infrastructure ---

/// Create a mock fetch function from URL pattern -> response map
///
/// Keys can be:
/// - URL pattern: '/tasks' matches any method
/// - Method + URL: 'POST /tasks' matches only POST to /tasks
Fetch createMockFetch(Map<String, Map<String, Object?>> responses) =>
    (url, {method = 'GET', token, body}) async {
      // First try method-specific match (e.g., 'POST /tasks')
      final methodKey = '$method $url'.replaceAll(RegExp('https?://[^/]+'), '');
      for (final entry in responses.entries) {
        if (entry.key.contains(' ') && methodKey.contains(entry.key)) {
          return _buildResponse(entry.value);
        }
      }
      // Fall back to URL-only match
      for (final entry in responses.entries) {
        if (entry.key.contains(' ')) continue;
        if (url.contains(entry.key)) {
          return _buildResponse(entry.value);
        }
      }
      throw StateError('No mock for $method $url');
    };

Result<JSObject, String> _buildResponse(Map<String, Object?> response) {
  final success = response['success'] == true;
  return success
      ? Success(createJSObject(response))
      : Error(response['error']?.toString() ?? 'Request failed');
}

/// Create a fetch that throws to test error handling
Fetch createThrowingFetch() =>
    (url, {method = 'GET', token, body}) =>
        Future.error(Exception('Network error'));

// --- WebSocket Mock ---

JSObject? _lastMockWs;

/// Setup mock WebSocket for testing
void mockWebSocket() {
  globalContext['WebSocket'] = ((JSString url) {
    final ws = JSObject();
    ws['close'] = (() {}).toJS;
    ws['send'] = ((JSAny _) {}).toJS;
    _lastMockWs = ws;
    return ws;
  }).toJS;
}

/// Simulate a WebSocket message from the server
void simulateWsMessage(String json) {
  final ws = _lastMockWs;
  if (ws == null) return;
  final onmessage = ws['onmessage'];
  if (onmessage == null) return;
  final event = JSObject();
  event['data'] = json.toJS;
  (onmessage as JSFunction).callAsFunction(null, event);
}

// --- Setup ---

/// Setup all mocks for testing
void setupMocks() {
  mockWebSocket();
}

// --- Wait Helpers ---

/// Wait for text to appear in the rendered result
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
