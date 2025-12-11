/// Test server for WebSocket and Express integration tests.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_express/dart_node_express.dart';
import 'package:dart_node_ws/dart_node_ws.dart';
import 'package:nadz/nadz.dart';

/// Port for HTTP server
const httpPort = 3456;

/// Port for WebSocket server
const wsPort = 3457;

void main() {
  final wsServer = _startWebSocketServer();
  _startHttpServer(wsServer);
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

/// JSON body parser middleware
JSFunction _jsonParser() {
  final expressModule = switch (requireModule('express')) {
    final JSObject o => o,
    _ => throw StateError('Express module not found'),
  };
  final jsonFn = switch (expressModule['json']) {
    final JSFunction f => f,
    _ => throw StateError('Express json function not found'),
  };
  return switch (jsonFn.callAsFunction()) {
    final JSFunction f => f,
    _ => throw StateError('Failed to create JSON parser'),
  };
}

void _startHttpServer(WebSocketServer wsServer) {
  express()
    ..use(_jsonParser())
    ..get('/health', handler((req, res) {
      res.jsonMap({'status': 'ok', 'wsPort': wsPort});
    }))
    ..get('/echo/:message', handler((req, res) {
      final message = req.params['message'].toString();
      res.jsonMap({'echo': message});
    }))
    ..post('/json', handler((req, res) {
      final body = req.body;
      res.jsonMap({'received': body.dartify(), 'success': true});
    }))
    ..get('/error', asyncHandler((req, res) async {
      await Future<void>.value();
      throw const NotFoundError('Test error');
    }))
    ..get('/status/:code', handler((req, res) {
      final code = int.tryParse(req.params['code'].toString()) ?? 200;
      res
        ..status(code)
        ..jsonMap({'statusCode': code});
    }))
    ..postWithMiddleware('/validated', [
      validateBody(_testSchema),
      handler((req, res) {
        switch (getValidatedBody<TestUserData>(req)) {
          case Error(:final error):
            res
              ..status(400)
              ..jsonMap({'error': error});
          case Success(:final value):
            res.jsonMap({'name': value.name, 'age': value.age});
        }
      }),
    ])
    ..use(errorHandler())
    ..listen(
      httpPort,
      (() {
        consoleLog('HTTP server running on http://localhost:$httpPort');
      }).toJS,
    );
}

/// Test user data type
typedef TestUserData = ({String name, int age});

/// Test validation schema
final _testSchema = schema<TestUserData>(
  {
    'name': string().minLength(1).maxLength(100),
    'age': int_().min(0).max(150),
  },
  (map) => (name: map['name']! as String, age: map['age']! as int),
);
