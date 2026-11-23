import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:frontend/src/types.dart';

/// Browser WebSocket extension type
extension type BrowserWebSocket(JSObject _) implements JSObject {
  external void close([int? code, String? reason]);
  external void send(String data);
  external int get readyState;

  JSFunction? get onopen => this['onopen'] as JSFunction?;
  set onopen(JSFunction? handler) => this['onopen'] = handler;

  JSFunction? get onmessage => this['onmessage'] as JSFunction?;
  set onmessage(JSFunction? handler) => this['onmessage'] = handler;

  JSFunction? get onclose => this['onclose'] as JSFunction?;
  set onclose(JSFunction? handler) => this['onclose'] = handler;

  JSFunction? get onerror => this['onerror'] as JSFunction?;
  set onerror(JSFunction? handler) => this['onerror'] = handler;
}

/// WebSocket message event
extension type MessageEvent(JSObject _) implements JSObject {
  external JSAny get data;
}

/// Create a new WebSocket connection
BrowserWebSocket createWebSocket(String url) {
  final wsCtor = globalContext['WebSocket']! as JSFunction;
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
      switch (data.isA<JSString>()) {
        case true:
          final message = data.dartify() as String?;
          switch (message) {
            case final String m:
              handleWebSocketMessage(m, onTaskEvent);
            case null:
              break;
          }
        case false:
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
  final json = globalContext['JSON']! as JSObject;
  final parseFn = json['parse']! as JSFunction;
  final parsed = parseFn.callAsFunction(null, message.toJS)! as JSObject;
  onTaskEvent(parsed);
}
