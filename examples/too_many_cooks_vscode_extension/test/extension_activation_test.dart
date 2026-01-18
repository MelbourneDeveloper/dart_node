/// Extension Activation Tests
/// Verifies the extension activates correctly and exposes the test API.
library;

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Extension Activation', () {
    test('StoreManager can be created', () {
      final (:manager, :client) = createTestStore();
      expect(manager, isNotNull);
      expect(client, isNotNull);
      client.dispose();
    });

    test('StoreManager has all required methods', () {
      final (:manager, :client) = createTestStore();

      // State access
      expect(manager.state, isNotNull);
      expect(manager.isConnected, isFalse);

      // Actions
      expect(manager.connect, isA<Function>());
      expect(manager.disconnect, isA<Function>());
      expect(manager.callTool, isA<Function>());

      client.dispose();
    });

    test('Initial state is disconnected', () {
      final (:manager, :client) = createTestStore();

      expect(
        manager.state.connectionStatus,
        equals(ConnectionStatus.disconnected),
      );
      expect(manager.isConnected, isFalse);

      client.dispose();
    });

    test('Initial state has empty arrays', () {
      final (:manager, :client) = createTestStore();

      expect(manager.state.agents, isEmpty);
      expect(manager.state.locks, isEmpty);
      expect(manager.state.messages, isEmpty);
      expect(manager.state.plans, isEmpty);

      client.dispose();
    });

    test('Initial computed values are zero', () {
      final (:manager, :client) = createTestStore();

      expect(selectAgentCount(manager.state), equals(0));
      expect(selectLockCount(manager.state), equals(0));
      expect(selectMessageCount(manager.state), equals(0));
      expect(selectUnreadMessageCount(manager.state), equals(0));

      client.dispose();
    });
  });

  group('MCP Server Feature Verification', () {
    test('Admin tool MUST exist on MCP server', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Test admin tool exists by calling it
        final result = await manager.callTool('admin', {
          'action': 'delete_agent',
          'agent_name': 'non-existent-agent-12345',
        });

        // Valid responses: {"deleted":true} or {"error":"..."}
        expect(result, anyOf(contains('deleted'), contains('error')));
      });
    });

    test('Subscribe tool MUST exist on MCP server', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('subscribe', {'action': 'list'});

        expect(result, contains('subscribers'));
      });
    });

    test('All core tools are available', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Test status tool
        final statusResult = await manager.callTool('status', {});
        expect(statusResult, contains('agents'));

        // Test register tool
        final registerResult = await manager.callTool('register', {
          'name': 'test-agent',
        });
        expect(registerResult, contains('agent_key'));

        // Core tools exist and respond
        expect(client.toolCalls, contains(startsWith('status:')));
        expect(client.toolCalls, contains(startsWith('register:')));
      });
    });
  });
}
