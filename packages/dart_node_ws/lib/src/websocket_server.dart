import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';

import 'package:dart_node_ws/src/websocket_types.dart';

/// Creates a WebSocket server on the specified port
WebSocketServer createWebSocketServer({required int port}) {
  final ws = requireModule('ws') as JSObject;
  final serverClass = ws['Server']! as JSFunction;
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
  ) =>
      _server.on(
        'connection',
        ((JSWebSocket ws, JSIncomingMessage request) {
          final client = WebSocketClient(ws);
          final url = _extractUrl(request);
          handler(client, url);
        }).toJS,
      );

  String? _extractUrl(JSIncomingMessage request) {
    final urlObj = request.url;
    return switch (urlObj) {
      null => null,
      final u when u.isA<JSString>() => (u as JSString).toDart,
      _ => null,
    };
  }

  /// Closes the WebSocket server
  void close([void Function()? callback]) => _server.close(
        callback != null ? (() => callback()).toJS : null,
      );
}
