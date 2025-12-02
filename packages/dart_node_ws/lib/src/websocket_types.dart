import 'dart:js_interop';

/// WebSocket connection ready states as defined by the WebSocket API.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/readyState
enum WebSocketReadyState {
  /// Socket has been created. The connection is not yet open.
  connecting(0),

  /// The connection is open and ready to communicate.
  open(1),

  /// The connection is in the process of closing.
  closing(2),

  /// The connection is closed or couldn't be opened.
  closed(3);

  const WebSocketReadyState(this._value);

  /// The numeric value of the ready state (0-3).
  final int _value;

  /// The numeric value matching the WebSocket API constants.
  int get value => _value;
}

/// WebSocket close event data containing the close code and reason.
///
/// Close codes follow RFC 6455:
/// - 1000: Normal closure - connection completed its purpose
/// - 1001: Going away - server shutdown or browser navigating away
/// - 1002: Protocol error
/// - 1006: Abnormal closure - no close frame received
/// - 1011: Internal error
/// - 3000-3999: Library/framework codes (IANA registered)
/// - 4000-4999: Private use codes
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent/code
typedef CloseEventData = ({
  /// The close code (1000-4999) indicating why the connection closed.
  int code,

  /// A human-readable explanation of why the connection was closed.
  String reason,
});

/// WebSocket message handler
typedef MessageHandler = void Function(JSAny data);

/// WebSocket close handler
typedef CloseHandler = void Function(CloseEventData data);

/// WebSocket error handler
typedef ErrorHandler = void Function(JSAny error);

/// WebSocket connection handler
typedef ConnectionHandler = void Function(WebSocketClient client);

/// JS interop binding for the WebSocket Server from the 'ws' package.
///
/// See: https://github.com/websockets/ws
extension type JSWebSocketServer(JSObject _) implements JSObject {
  /// Registers an event listener for server events.
  ///
  /// Common events: 'connection', 'close', 'error'.
  external void on(String event, JSFunction handler);

  /// Closes the WebSocket server and optionally invokes a callback on
  /// completion.
  external void close([JSFunction? callback]);
}

/// JS interop binding for a WebSocket connection from the 'ws' package.
///
/// Represents a client connection on the server side.
/// See: https://github.com/websockets/ws
extension type JSWebSocket(JSObject _) implements JSObject {
  /// Registers an event listener for WebSocket events.
  ///
  /// Common events: 'message', 'close', 'error'.
  external void on(String event, JSFunction handler);

  /// Sends data through the WebSocket connection.
  external void send(JSAny data);

  /// Closes the WebSocket connection.
  ///
  /// [code] - Status code (default 1000 for normal closure).
  /// [reason] - Human-readable reason for closing.
  external void close([int? code, String? reason]);

  /// The current state of the connection.
  ///
  /// Returns a value matching [WebSocketReadyState]: 0=CONNECTING,
  /// 1=OPEN, 2=CLOSING, 3=CLOSED.
  external int get readyState;
}

/// JS IncomingMessage for upgrade request
extension type JSIncomingMessage(JSObject _) implements JSObject {
  /// The request URL string
  external JSAny? get url;

  /// The request headers object
  external JSObject get headers;
}

/// High-level wrapper for a WebSocket client connection.
///
/// Provides a typed Dart API over the underlying JS WebSocket,
/// abstracting away JS interop details.
class WebSocketClient {
  /// Creates a new WebSocket client wrapper around the given JS WebSocket.
  WebSocketClient(this._ws);

  final JSWebSocket _ws;

  /// Optional user identifier for this connection.
  String? userId;

  /// Sends a string message through the WebSocket.
  void send(String message) => _ws.send(message.toJS);

  /// Sends a JSON-serializable map through the WebSocket.
  void sendJson(Map<String, Object?> data) =>
      _ws.send(data.jsify()!);

  /// Closes the WebSocket connection.
  ///
  /// [code] - Status code (default 1000 = normal closure).
  /// [reason] - Optional human-readable reason for closing.
  void close([int code = 1000, String reason = '']) =>
      _ws.close(code, reason);

  /// Returns true if the connection is open and ready to communicate.
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
