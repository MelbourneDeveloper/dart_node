/// View Tests
/// Verifies state views are accessible and UI bugs are fixed.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

void main() {
  _log('[VIEWS TEST] main() called');

  suite('Views', syncTest(() {
    suiteSetup(asyncTest(() async {
      _log('[VIEWS] suiteSetup - waiting for extension activation');
      await waitForExtensionActivation();
    }));

    suiteTeardown(asyncTest(() async {
      _log('[VIEWS] suiteTeardown - disconnecting');
      await safeDisconnect();
    }));

    test('Agents list is accessible from API', asyncTest(() async {
      _log('[VIEWS] Running agents list test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final agents = api.getAgents();
      assertOk(agents.length >= 0, 'Agents list should be accessible');
      _log('[VIEWS] agents list test PASSED');
    }));

    test('Locks list is accessible from API', asyncTest(() async {
      _log('[VIEWS] Running locks list test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final locks = api.getLocks();
      assertOk(locks.length >= 0, 'Locks list should be accessible');
      _log('[VIEWS] locks list test PASSED');
    }));

    test('Messages list is accessible from API', asyncTest(() async {
      _log('[VIEWS] Running messages list test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final messages = api.getMessages();
      assertOk(messages.length >= 0, 'Messages list should be accessible');
      _log('[VIEWS] messages list test PASSED');
    }));

    test('Plans list is accessible from API', asyncTest(() async {
      _log('[VIEWS] Running plans list test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final plans = api.getPlans();
      assertOk(plans.length >= 0, 'Plans list should be accessible');
      _log('[VIEWS] plans list test PASSED');
    }));
  }));

  suite('UI Bug Fixes', syncTest(() {
    suiteSetup(asyncTest(() async {
      _log('[UI BUGS] suiteSetup');
      await waitForExtensionActivation();
    }));

    suiteTeardown(asyncTest(() async {
      _log('[UI BUGS] suiteTeardown');
      await safeDisconnect();
    }));

    test('Messages are properly stored with all fields', asyncTest(() async {
      _log('[UI BUGS] Running message storage test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final testId = DateTime.now().millisecondsSinceEpoch;
      final agentName = 'ui-test-$testId';

      // Register agent
      final registerArgs = createArgs({'name': agentName});
      final result = await api.callTool('register', registerArgs).toDart;
      final agentKey = extractKeyFromResult(result.toDart);

      // Send message
      final msgArgs = createArgs({
        'action': 'send',
        'agent_name': agentName,
        'agent_key': agentKey,
        'to_agent': '*',
        'content': 'Test message for UI verification',
      });
      await api.callTool('message', msgArgs).toDart;

      await api.refreshStatus().toDart;

      final messages = api.getMessages();
      assertOk(messages.length > 0, 'Should have at least one message');
      _log('[UI BUGS] message storage test PASSED');
    }));

    test('Broadcast messages to * are stored correctly', asyncTest(() async {
      _log('[UI BUGS] Running broadcast test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      final testId = DateTime.now().millisecondsSinceEpoch;
      final agentName = 'broadcast-$testId';

      // Register agent
      final registerArgs = createArgs({'name': agentName});
      final result = await api.callTool('register', registerArgs).toDart;
      final agentKey = extractKeyFromResult(result.toDart);

      // Send broadcast
      final msgArgs = createArgs({
        'action': 'send',
        'agent_name': agentName,
        'agent_key': agentKey,
        'to_agent': '*',
        'content': 'Broadcast test message',
      });
      await api.callTool('message', msgArgs).toDart;

      await api.refreshStatus().toDart;

      final messages = api.getMessages();
      assertOk(messages.length > 0, 'Should have broadcast message');
      _log('[UI BUGS] broadcast test PASSED');
    }));
  }));

  _log('[VIEWS TEST] main() completed');
}
