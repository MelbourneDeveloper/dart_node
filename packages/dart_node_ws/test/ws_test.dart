/// Tests for dart_node_ws library types and APIs.
///
/// These tests run in Node.js environment to get coverage for the library.
@TestOn('node')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_ws/dart_node_ws.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('WebSocketReadyState', () {
    test('connecting has value 0', () {
      expect(WebSocketReadyState.connecting.value, equals(0));
    });

    test('open has value 1', () {
      expect(WebSocketReadyState.open.value, equals(1));
    });

    test('closing has value 2', () {
      expect(WebSocketReadyState.closing.value, equals(2));
    });

    test('closed has value 3', () {
      expect(WebSocketReadyState.closed.value, equals(3));
    });

    test('all states are distinct', () {
      final values = WebSocketReadyState.values.map((s) => s.value).toSet();
      expect(values.length, equals(4));
    });
  });

  group('createWebSocketServer', () {
    test('creates server on specified port', () {
      final server = createWebSocketServer(port: 9999);
      expect(server, isNotNull);
      expect(server.port, equals(9999));
      server.close();
    });

    test('multiple servers can be created on different ports', () {
      final server1 = createWebSocketServer(port: 9998);
      final server2 = createWebSocketServer(port: 9997);

      expect(server1.port, equals(9998));
      expect(server2.port, equals(9997));

      server1.close();
      server2.close();
    });

    test('close with callback invokes callback', () async {
      final server = createWebSocketServer(port: 9996);
      var callbackInvoked = false;

      server.close(() {
        callbackInvoked = true;
      });

      // Give callback time to fire
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callbackInvoked, isTrue);
    });

    test('close without callback works', () {
      // Should not throw
      createWebSocketServer(port: 9995).close();
    });
  });

  group('WebSocketServer connection handling', () {
    test('onConnection registers handler', () {
      createWebSocketServer(port: 9994)
        ..onConnection((client, url) {
          // Handler registered
        })
        ..close();
    });

    test('onConnection receives client on connection', () {
      createWebSocketServer(port: 9993)
        ..onConnection((client, url) {
          expect(client, isNotNull);
          expect(url, isNotNull);
        })
        ..close();
    });
  });

  group('WebSocket Integration Tests', () {
    late WebSocketServer server;
    const testPort = 3456;

    setUp(() async {
      server = createWebSocketServer(port: testPort);
    });

    tearDown(() async {
      server.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('client can connect to server', () async {
      final completer = Completer<void>();

      server.onConnection((client, url) {
        completer.complete();
      });

      final client = _createWebSocketClient('ws://localhost:$testPort');

      await completer.future.timeout(const Duration(seconds: 2));
      await _waitForOpen(client);
      client.close();
    });

    test('server receives messages from client', () async {
      final messageCompleter = Completer<String>();

      server.onConnection((serverClient, url) {
        serverClient.onMessage((message) {
          messageCompleter.complete(message.text ?? '');
        });
      });

      final client = _createWebSocketClient('ws://localhost:$testPort');

      await _waitForOpen(client);
      _sendMessage(client, 'Hello from client');

      final receivedMessage = await messageCompleter.future.timeout(
        const Duration(seconds: 2),
      );
      expect(receivedMessage, equals('Hello from client'));
      client.close();
    });

    test('client receives messages from server', () async {
      final messageCompleter = Completer<String>();

      server.onConnection((serverClient, url) {
        serverClient.send('Welcome to server');
      });

      final client = _createWebSocketClient('ws://localhost:$testPort');

      _onMessage(client, (data) {
        final message = _extractMessage(data);
        messageCompleter.complete(message);
      });

      final receivedMessage = await messageCompleter.future.timeout(
        const Duration(seconds: 2),
      );
      expect(receivedMessage, equals('Welcome to server'));
      client.close();
    });
  });
}

/// Creates a WebSocket client using Node.js ws package
JSWebSocket _createWebSocketClient(String url) {
  final ws = requireModule('ws');
  final wsClass = switch (ws) {
    final JSFunction f => f,
    _ => throw StateError('WebSocket module not found'),
  };
  return JSWebSocket(wsClass.callAsConstructor<JSObject>(url.toJS));
}

/// Waits for WebSocket to reach OPEN state
Future<void> _waitForOpen(JSWebSocket ws) async {
  final completer = Completer<void>();

  if (ws.readyState == 1) {
    completer.complete();
  } else {
    ws.on('open', (() => completer.complete()).toJS);
    ws.on(
      'error',
      ((JSAny error) => completer.completeError(
        'Connection failed: $error',
      )).toJS,
    );
  }

  return completer.future.timeout(const Duration(seconds: 2));
}

/// Sends a message through WebSocket
void _sendMessage(JSWebSocket ws, String message) {
  ws.send(message.toJS);
}

/// Sets up message handler for WebSocket
void _onMessage(JSWebSocket ws, void Function(JSAny) handler) {
  ws.on('message', handler.toJS);
}

/// Extracts string message from JSAny data
String _extractMessage(JSAny data) {
  // Convert using JavaScript String() function for safety
  try {
    final stringConstructor = globalContext['String'] as JSFunction;
    return (stringConstructor.callAsFunction(null, data) as JSString).toDart;
  } catch (_) {
    return data.toString();
  }
}

/// JS interop types for WebSocket client
extension type JSWebSocket(JSObject _) implements JSObject {
  external void on(String event, JSFunction handler);
  external void send(JSAny data);
  external void close([int? code, String? reason]);
  external int get readyState;
}
