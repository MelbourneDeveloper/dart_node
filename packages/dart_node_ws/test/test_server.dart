/// Test server for WebSocket tests (no Express dependency).
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_ws/dart_node_ws.dart';

/// Port for WebSocket server
const wsPort = 3457;

void main() {
  _startWebSocketServer();
}

WebSocketServer _startWebSocketServer() {
  final server = createWebSocketServer(port: wsPort)
    ..onConnection((client, url) {
      consoleLog('Client connected: $url');

      client
        ..onMessage((message) {
          final text = message.text;
          if (text == null || text.isEmpty) {
            client.send('error:no-text');
            return;
          }

          // Echo messages back with prefix
          if (text.startsWith('echo:')) {
            client.send('echoed:${text.substring(5)}');
            return;
          }

          // JSON echo
          if (text.startsWith('json:')) {
            final jsonStr = text.substring(5);
            final parsed = _parseJson(jsonStr);
            if (parsed != null) {
              client.sendJson({'received': parsed, 'type': 'json-echo'});
            } else {
              client.send('error:invalid-json');
            }
            return;
          }

          // Close request
          if (text == 'close') {
            client.close(1000, 'requested');
            return;
          }

          // Close with custom code
          if (text.startsWith('close:')) {
            final code = int.tryParse(text.substring(6)) ?? 1000;
            client.close(code, 'custom-close');
            return;
          }

          // Default: echo the message
          client.send('received:$text');
        })
        ..onClose((data) {
          consoleLog('Client closed: ${data.code} ${data.reason}');
        })
        ..onError((error) {
          consoleLog('Client error: ${error.message}');
        })
        // Send welcome message
        ..send('connected');

      // Send URL if present
      if (url != null) {
        client.send('url:$url');
      }
    });

  consoleLog('WebSocket server running on ws://localhost:$wsPort');
  return server;
}

Map<String, Object?>? _parseJson(String jsonStr) {
  final json = switch (globalContext['JSON']) {
    final JSObject o => o,
    _ => null,
  };
  if (json == null) return null;

  final parseFn = switch (json['parse']) {
    final JSFunction f => f,
    _ => null,
  };
  if (parseFn == null) return null;

  final result = parseFn.callAsFunction(null, jsonStr.toJS);
  final dartified = switch (result) {
    final JSObject o => o.dartify(),
    _ => null,
  };
  // dartify() returns Map<Object?, Object?>, need to cast keys to String
  return switch (dartified) {
    final Map<Object?, Object?> m => m.cast<String, Object?>(),
    _ => null,
  };
}
