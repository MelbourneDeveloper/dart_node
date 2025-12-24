/// Command Tests
/// Verifies all registered commands work correctly.
library;

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Commands', () {
    test('connect command establishes connection', () async {
      await withTestStore((manager, client) async {
        expect(manager.isConnected, isFalse);

        await manager.connect();

        expect(manager.isConnected, isTrue);
        expect(
          manager.state.connectionStatus,
          equals(ConnectionStatus.connected),
        );
      });
    });

    test('disconnect command can be executed without error when not connected',
        () async {
      await withTestStore((manager, client) async {
        // Should not throw even when not connected
        await manager.disconnect();
        expect(manager.isConnected, isFalse);
      });
    });

    test('refresh command updates state from server', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Add some data via client directly
        client.agents['refresh-agent'] = (
          key: 'key-1',
          registeredAt: DateTime.now().millisecondsSinceEpoch,
          lastActive: DateTime.now().millisecondsSinceEpoch,
        );

        // Refresh should pick up new data
        await manager.refreshStatus();

        expect(findAgent(manager, 'refresh-agent'), isNotNull);
      });
    });
  });
}
