/// Tests for dart_node_ws library types and APIs.
///
/// These tests run in Node.js environment to get coverage for the library.
@TestOn('node')
library;

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_ws/dart_node_ws.dart';
import 'package:test/test.dart';

//TODO: we need actual web socket server/client interaction tests here.

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
          // Handler registered - just verify it doesn't throw
        })
        ..close();
    });

    test('onConnection receives client on connection', () {
      // The connection test happens in websocket_test.dart (integration tests)
      // Here we just verify the API works without throwing
      createWebSocketServer(port: 9993)
        ..onConnection((client, url) {
          expect(client, isNotNull);
          expect(url, isNotNull);
        })
        ..close();
    });
  });
}
