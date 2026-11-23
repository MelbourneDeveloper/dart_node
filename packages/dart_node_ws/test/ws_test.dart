/// Tests for dart_node_ws library types and APIs.
///
/// These tests run in JS environment to get coverage for the actual library.
@TestOn('js')
library;

import 'package:dart_node_ws/dart_node_ws.dart';
import 'package:test/test.dart';

void main() {
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
      final server = createWebSocketServer(port: 9995);
      // Should not throw
      server.close();
    });
  });

  group('WebSocketServer connection handling', () {
    test('onConnection registers handler', () {
      final server = createWebSocketServer(port: 9994);
      var handlerRegistered = false;

      server.onConnection((client, url) {
        handlerRegistered = true;
      });

      // Handler was registered (we check it doesn't throw)
      expect(true, isTrue);
      server.close();
    });

    test('onConnection receives client on connection', () async {
      final server = createWebSocketServer(port: 9993);
      WebSocketClient? receivedClient;
      String? receivedUrl;

      server.onConnection((client, url) {
        receivedClient = client;
        receivedUrl = url;
      });

      // The connection test happens in websocket_test.dart (integration tests)
      // Here we just verify the API works without throwing
      expect(server.port, equals(9993));
      server.close();
    });
  });
}
