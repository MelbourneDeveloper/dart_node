import 'dart:js_interop';

/// WebSocket ready states
enum WebSocketReadyState {
  connecting(0),
  open(1),
  closing(2),
  closed(3);

  const WebSocketReadyState(this.value);
  final int value;
}

/// WebSocket close event data
typedef CloseEventData = ({int code, String reason});

/// WebSocket message handler
typedef MessageHandler = void Function(JSAny data);

/// WebSocket close handler
typedef CloseHandler = void Function(CloseEventData data);

/// WebSocket error handler
typedef ErrorHandler = void Function(JSAny error);

/// WebSocket connection handler
typedef ConnectionHandler = void Function(WebSocketClient client);

/// JS WebSocket Server type
extension type JSWebSocketServer(JSObject _) implements JSObject {
  external void on(String event, JSFunction handler);
  external void close([JSFunction? callback]);
}

/// JS WebSocket type (client connection on server side)
extension type JSWebSocket(JSObject _) implements JSObject {
  external void on(String event, JSFunction handler);
  external void send(JSAny data);
  external void close([int? code, String? reason]);
  external int get readyState;
}

/// JS IncomingMessage for upgrade request
extension type JSIncomingMessage(JSObject _) implements JSObject {
  /// The request URL string
  external JSAny? get url;

  /// The request headers object
  external JSObject get headers;
}

/// Wrapper for a WebSocket client connection
class WebSocketClient {
  WebSocketClient(this._ws);

  final JSWebSocket _ws;
  String? userId;

  void send(String message) => _ws.send(message.toJS);

  void sendJson(Map<String, Object?> data) =>
      _ws.send(data.jsify()!);

  void close([int code = 1000, String reason = '']) =>
      _ws.close(code, reason);

  bool get isOpen => _ws.readyState == WebSocketReadyState.open.value;

  /// Registers a handler for incoming messages
  void onMessage(MessageHandler handler) =>
      _ws.on('message', ((JSAny data) => handler(data)).toJS);

  /// Registers a handler for connection close events
  void onClose(CloseHandler handler) => _ws.on(
        'close',
        ((int code, JSAny? reason) => handler((
              code: code,
              reason: _extractCloseReason(reason),
            ))).toJS,
      );

  String _extractCloseReason(JSAny? reason) => switch (reason) {
        null => '',
        final JSString s => s.toDart,
        _ => reason.toString(),
      };

  /// Registers a handler for error events
  void onError(ErrorHandler handler) =>
      _ws.on('error', ((JSAny error) => handler(error)).toJS);
}
