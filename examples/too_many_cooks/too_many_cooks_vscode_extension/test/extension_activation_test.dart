/// Extension Activation Tests
/// Verifies the extension activates correctly and exposes the test API.
library;

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Extension Activation', () {
    test('StoreManager can be created', () async {
      final (:manager, :workspaceFolder) = createTestStore();
      expect(manager, isNotNull);
      expect(workspaceFolder, isNotEmpty);
      await cleanupTestStore(workspaceFolder);
    });

    test('StoreManager has all required methods', () async {
      final (:manager, :workspaceFolder) = createTestStore();

      // State access
      expect(manager.state, isNotNull);
      expect(manager.isConnected, isFalse);

      // Actions
      expect(manager.connect, isA<Function>());
      expect(manager.disconnect, isA<Function>());

      await cleanupTestStore(workspaceFolder);
    });

    test('Initial state is disconnected', () async {
      final (:manager, :workspaceFolder) = createTestStore();

      expect(
        manager.state.connectionStatus,
        equals(ConnectionStatus.disconnected),
      );
      expect(manager.isConnected, isFalse);

      await cleanupTestStore(workspaceFolder);
    });

    test('Initial state has empty arrays', () async {
      final (:manager, :workspaceFolder) = createTestStore();

      expect(manager.state.agents, isEmpty);
      expect(manager.state.locks, isEmpty);
      expect(manager.state.messages, isEmpty);
      expect(manager.state.plans, isEmpty);

      await cleanupTestStore(workspaceFolder);
    });

    test('Initial computed values are zero', () async {
      final (:manager, :workspaceFolder) = createTestStore();

      expect(selectAgentCount(manager.state), equals(0));
      expect(selectLockCount(manager.state), equals(0));
      expect(selectMessageCount(manager.state), equals(0));
      expect(selectUnreadMessageCount(manager.state), equals(0));

      await cleanupTestStore(workspaceFolder);
    });
  });
}
