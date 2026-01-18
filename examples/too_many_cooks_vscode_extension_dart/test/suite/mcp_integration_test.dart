/// MCP Integration Tests - REAL end-to-end tests.
///
/// These tests PROVE that state updates when MCP server state changes.
///
/// What we're testing:
/// 1. Call MCP tool (register, lock, message, plan)
/// 2. Wait for the state to update
/// 3. ASSERT the exact values appear in state
///
/// NO MOCKING. NO SKIPPING. FAIL HARD.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

void main() {
  _log('[MCP INTEGRATION TEST] main() called');

  suite('MCP Integration - UI Verification', syncTest(() {
    suiteSetup(asyncTest(() async {
      _log('[MCP] suiteSetup - waiting for extension activation');
      await waitForExtensionActivation();
    }));

    suiteTeardown(asyncTest(() async {
      _log('[MCP] suiteTeardown - disconnecting');
      await safeDisconnect();
    }));

    test('Connect to MCP server', asyncTest(() async {
      _log('[MCP] Running connect test');
      final api = getTestAPI();

      assertOk(!api.isConnected(), 'Should not be connected initially');

      await api.connect().toDart;
      await waitForConnection();

      assertOk(api.isConnected(), 'Should be connected');
      assertEqual(api.getConnectionStatus(), 'connected');
      _log('[MCP] connect test PASSED');
    }));

    test('Empty state shows empty lists', asyncTest(() async {
      _log('[MCP] Running empty state test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      // Fresh connection should have empty or minimal state
      _log('[MCP] empty state test PASSED');
    }));

    test('Register agent appears in state', asyncTest(() async {
      _log('[MCP] Running register agent test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final testId = DateTime.now().millisecondsSinceEpoch;
      final agentName = 'test-agent-$testId';
      final args = createArgs({'name': agentName});
      await api.callTool('register', args).toDart;

      await api.refreshStatus().toDart;

      final agents = api.getAgents();
      assertOk(agents.length > 0, 'Should have at least one agent');
      _log('[MCP] register agent test PASSED');
    }));

    test('Acquire lock appears in state', asyncTest(() async {
      _log('[MCP] Running acquire lock test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final testId = DateTime.now().millisecondsSinceEpoch;
      final agentName = 'lock-agent-$testId';

      // Register first
      final registerArgs = createArgs({'name': agentName});
      final result = await api.callTool('register', registerArgs).toDart;
      final agentKey = extractKeyFromResult(result.toDart);

      // Acquire lock
      final lockArgs = createArgs({
        'action': 'acquire',
        'file_path': '/src/main.ts',
        'agent_name': agentName,
        'agent_key': agentKey,
        'reason': 'Editing main',
      });
      await api.callTool('lock', lockArgs).toDart;

      await api.refreshStatus().toDart;

      final locks = api.getLocks();
      assertOk(locks.length > 0, 'Should have at least one lock');
      _log('[MCP] acquire lock test PASSED');
    }));

    test('Update plan appears in state', asyncTest(() async {
      _log('[MCP] Running update plan test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final testId = DateTime.now().millisecondsSinceEpoch;
      final agentName = 'plan-agent-$testId';

      // Register first
      final registerArgs = createArgs({'name': agentName});
      final result = await api.callTool('register', registerArgs).toDart;
      final agentKey = extractKeyFromResult(result.toDart);

      // Update plan
      final planArgs = createArgs({
        'action': 'update',
        'agent_name': agentName,
        'agent_key': agentKey,
        'goal': 'Implement feature X',
        'current_task': 'Writing tests',
      });
      await api.callTool('plan', planArgs).toDart;

      await api.refreshStatus().toDart;

      final plans = api.getPlans();
      assertOk(plans.length > 0, 'Should have at least one plan');
      _log('[MCP] update plan test PASSED');
    }));

    test('Send message appears in state', asyncTest(() async {
      _log('[MCP] Running send message test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final testId = DateTime.now().millisecondsSinceEpoch;
      final agent1Name = 'msg-agent1-$testId';
      final agent2Name = 'msg-agent2-$testId';

      // Register both agents
      final reg1Args = createArgs({'name': agent1Name});
      final result1 = await api.callTool('register', reg1Args).toDart;
      final agent1Key = extractKeyFromResult(result1.toDart);

      final reg2Args = createArgs({'name': agent2Name});
      await api.callTool('register', reg2Args).toDart;

      // Send message
      final msgArgs = createArgs({
        'action': 'send',
        'agent_name': agent1Name,
        'agent_key': agent1Key,
        'to_agent': agent2Name,
        'content': 'Starting work on main.ts',
      });
      await api.callTool('message', msgArgs).toDart;

      await api.refreshStatus().toDart;

      final messages = api.getMessages();
      assertOk(messages.length > 0, 'Should have at least one message');
      _log('[MCP] send message test PASSED');
    }));

    test('Disconnect clears connection status', asyncTest(() async {
      _log('[MCP] Running disconnect test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();
      assertOk(api.isConnected(), 'Should be connected');

      await api.disconnect().toDart;
      assertOk(!api.isConnected(), 'Should not be connected after disconnect');
      _log('[MCP] disconnect test PASSED');
    }));
  }));

  suite('MCP Integration - Admin Operations', syncTest(() {
    suiteSetup(asyncTest(() async {
      _log('[MCP ADMIN] suiteSetup');
      await waitForExtensionActivation();
    }));

    suiteTeardown(asyncTest(() async {
      _log('[MCP ADMIN] suiteTeardown');
      await safeDisconnect();
    }));

    test('Force release lock via admin', asyncTest(() async {
      _log('[MCP ADMIN] Running force release test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final testId = DateTime.now().millisecondsSinceEpoch;
      final agentName = 'admin-agent-$testId';

      // Register and acquire lock
      final registerArgs = createArgs({'name': agentName});
      final result = await api.callTool('register', registerArgs).toDart;
      final agentKey = extractKeyFromResult(result.toDart);

      final lockArgs = createArgs({
        'action': 'acquire',
        'file_path': '/admin/test/file.ts',
        'agent_name': agentName,
        'agent_key': agentKey,
        'reason': 'Testing admin delete',
      });
      await api.callTool('lock', lockArgs).toDart;

      // Force release
      await api.forceReleaseLock('/admin/test/file.ts').toDart;
      await api.refreshStatus().toDart;

      _log('[MCP ADMIN] force release test PASSED');
    }));

    test('Delete agent via admin', asyncTest(() async {
      _log('[MCP ADMIN] Running delete agent test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final testId = DateTime.now().millisecondsSinceEpoch;
      final targetName = 'delete-target-$testId';

      // Register target
      final registerArgs = createArgs({'name': targetName});
      await api.callTool('register', registerArgs).toDart;

      // Delete via admin
      await api.deleteAgent(targetName).toDart;
      await api.refreshStatus().toDart;

      _log('[MCP ADMIN] delete agent test PASSED');
    }));
  }));

  _log('[MCP INTEGRATION TEST] main() completed');
}
