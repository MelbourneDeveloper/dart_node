import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';

import 'package:dart_node_ws/src/websocket_types.dart';

/// Creates a WebSocket server on the specified port
WebSocketServer createWebSocketServer({required int port}) {
  final ws = requireModule('ws');
  final wsObj = switch (ws) {
    final JSObject o => o,
    _ => throw StateError('WebSocket module not found'),
  };
  final serverClass = switch (wsObj['Server']) {
    final JSFunction f => f,
    _ => throw StateError('WebSocket Server class not found'),
  };
  final options = JSObject();
  options['port'] = port.toJS;
  final server = serverClass.callAsConstructor<JSWebSocketServer>(options);
  return WebSocketServer._(server, port);
}

/// WebSocket server wrapper
class WebSocketServer {
  WebSocketServer._(this._server, this.port);

  final JSWebSocketServer _server;

  /// The port the server is listening on
  final int port;

  /// Registers a handler for new client connections
  void onConnection(
    void Function(WebSocketClient client, String? url) handler,
  ) => _server.on(
    'connection',
    ((JSWebSocket ws, JSIncomingMessage request) {
      final client = WebSocketClient(ws);
      final url = _extractUrl(request);
      handler(client, url);
    }).toJS,
  );

  String? _extractUrl(JSIncomingMessage request) => switch (request.url) {
    null => null,
    final JSString s => s.toDart,
    _ => null,
  };

  /// Closes the WebSocket server
  void close([void Function()? callback]) =>
      _server.close(callback != null ? (() => callback()).toJS : null);
}
