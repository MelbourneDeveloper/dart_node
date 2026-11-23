import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'types.dart';

/// React Native WebSocket extension type (same API as browser WebSocket)
extension type RNWebSocket(JSObject _) implements JSObject {
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
extension type WSMessageEvent(JSObject _) implements JSObject {
  external JSAny get data;
}

/// Create a new WebSocket connection
RNWebSocket _createWebSocket(String url) {
  final wsCtor = globalContext['WebSocket']! as JSFunction;
  return RNWebSocket(wsCtor.callAsConstructor<JSObject>(url.toJS));
}

/// Connects to the WebSocket server with the given token
RNWebSocket? connectWebSocket({
  required String token,
  required void Function(JSObject event) onTaskEvent,
  void Function()? onOpen,
  void Function()? onClose,
}) => _createWebSocket('$wsUrl?token=$token')
  ..onopen = ((JSAny _) {
    onOpen?.call();
  }).toJS
  ..onmessage = ((WSMessageEvent event) {
    final data = event.data;
    switch (data.isA<JSString>()) {
      case true:
        final message = data.dartify() as String?;
        switch (message) {
          case final String m:
            _handleMessage(m, onTaskEvent);
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

void _handleMessage(String message, void Function(JSObject) onTaskEvent) {
  final json = globalContext['JSON']! as JSObject;
  final parseFn = json['parse']! as JSFunction;
  final parsed = parseFn.callAsFunction(null, message.toJS)! as JSObject;
  onTaskEvent(parsed);
}
