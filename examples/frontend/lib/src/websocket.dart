import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:frontend/src/types.dart';

/// Browser WebSocket extension type
extension type BrowserWebSocket(JSObject _) implements JSObject {
  external void close([int? code, String? reason]);
  external void send(String data);
  external int get readyState;

  JSFunction? get onopen => switch (this['onopen']) {
    final JSFunction f => f,
    _ => null,
  };
  set onopen(JSFunction? handler) => this['onopen'] = handler;

  JSFunction? get onmessage => switch (this['onmessage']) {
    final JSFunction f => f,
    _ => null,
  };
  set onmessage(JSFunction? handler) => this['onmessage'] = handler;

  JSFunction? get onclose => switch (this['onclose']) {
    final JSFunction f => f,
    _ => null,
  };
  set onclose(JSFunction? handler) => this['onclose'] = handler;

  JSFunction? get onerror => switch (this['onerror']) {
    final JSFunction f => f,
    _ => null,
  };
  set onerror(JSFunction? handler) => this['onerror'] = handler;
}

/// WebSocket message event
extension type MessageEvent(JSObject _) implements JSObject {
  external JSAny get data;
}

/// Create a new WebSocket connection
BrowserWebSocket createWebSocket(String url) {
  final wsCtor = switch (globalContext['WebSocket']) {
    final JSFunction f => f,
    _ => throw StateError('WebSocket not available'),
  };
  return BrowserWebSocket(wsCtor.callAsConstructor<JSObject>(url.toJS));
}

/// Connects to the WebSocket server with the given token
BrowserWebSocket? connectWebSocket({
  required String token,
  required void Function(JSObject event) onTaskEvent,
  void Function()? onOpen,
  void Function()? onClose,
  String baseWsUrl = wsUrl,
}) {
  final ws = createWebSocket('$baseWsUrl?token=$token')
    ..onopen = ((JSAny _) {
      onOpen?.call();
    }).toJS
    ..onmessage = ((MessageEvent event) {
      final data = event.data;
      switch (data) {
        case final JSString jsStr:
          handleWebSocketMessage(jsStr.toDart, onTaskEvent);
        case _:
          break;
      }
    }).toJS
    ..onclose = ((JSAny _) {
      onClose?.call();
    }).toJS
    ..onerror = ((JSAny _) {
      // Error handling - close will be called after
    }).toJS;

  return ws;
}

/// Parse and handle incoming WebSocket message
void handleWebSocketMessage(
  String message,
  void Function(JSObject) onTaskEvent,
) {
  final json = switch (globalContext['JSON']) {
    final JSObject o => o,
    _ => throw StateError('JSON not available'),
  };
  final parseFn = switch (json['parse']) {
    final JSFunction f => f,
    _ => throw StateError('JSON.parse not available'),
  };
  final parsed = switch (parseFn.callAsFunction(null, message.toJS)) {
    final JSObject o => o,
    _ => throw StateError('Failed to parse JSON'),
  };
  onTaskEvent(parsed);
}
