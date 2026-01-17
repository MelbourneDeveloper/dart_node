/// Status Bar Tests
/// Verifies the connection status updates correctly.
library;

import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('Status Bar', () {
    test('Connection status starts as disconnected', () {
      final (:manager, :client) = createTestStore();

      expect(
        manager.state.connectionStatus,
        equals(ConnectionStatus.disconnected),
      );

      client.dispose();
    });

    test('Connection status changes to connecting during connect', () async {
      final (:manager, :client) = createTestStore();

      var sawConnecting = false;
      manager.subscribe(() {
        if (manager.state.connectionStatus == ConnectionStatus.connecting) {
          sawConnecting = true;
        }
      });

      await manager.connect();

      expect(sawConnecting, isTrue);
      expect(
        manager.state.connectionStatus,
        equals(ConnectionStatus.connected),
      );

      client.dispose();
    });

    test('Connection status changes to connected after successful connect',
        () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        expect(
          manager.state.connectionStatus,
          equals(ConnectionStatus.connected),
        );
      });
    });

    test('Connection status changes to disconnected after disconnect',
        () async {
      await withTestStore((manager, client) async {
        await manager.connect();
        expect(
          manager.state.connectionStatus,
          equals(ConnectionStatus.connected),
        );

        await manager.disconnect();
        expect(
          manager.state.connectionStatus,
          equals(ConnectionStatus.disconnected),
        );
      });
    });
  });
}
