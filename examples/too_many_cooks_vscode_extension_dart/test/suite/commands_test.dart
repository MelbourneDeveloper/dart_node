/// Command Tests
/// Verifies all registered commands work correctly.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_api.dart';
import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

void main() {
  _log('[COMMANDS TEST] main() called');

  suite('Commands', syncTest(() {
    suiteSetup(asyncTest(() async {
      _log('[COMMANDS TEST] suiteSetup - waiting for extension activation');
      await waitForExtensionActivation();
      _log('[COMMANDS TEST] suiteSetup complete');
    }));

    suiteTeardown(asyncTest(() async {
      _log('[COMMANDS TEST] suiteTeardown - disconnecting');
      await safeDisconnect();
      _log('[COMMANDS TEST] suiteTeardown complete');
    }));

    test('connect command establishes connection', asyncTest(() async {
      _log('[COMMANDS TEST] Running connect test');
      final api = getTestAPI();

      assertOk(!api.isConnected(), 'Should not be connected initially');

      await api.connect().toDart;
      await waitForConnection();

      assertOk(api.isConnected(), 'Should be connected after connect()');
      assertEqual(api.getConnectionStatus(), 'connected');
      _log('[COMMANDS TEST] connect test PASSED');
    }));

    test('disconnect command works when not connected', asyncTest(() async {
      _log('[COMMANDS TEST] Running disconnect test');
      final api = getTestAPI();

      // Ensure disconnected first
      await safeDisconnect();
      assertOk(!api.isConnected(), 'Should not be connected');

      // Should not throw even when not connected
      await api.disconnect().toDart;
      assertOk(!api.isConnected(), 'Should still not be connected');
      _log('[COMMANDS TEST] disconnect test PASSED');
    }));

    test('refresh command updates state from server', asyncTest(() async {
      _log('[COMMANDS TEST] Running refresh test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      // Register an agent via MCP tool
      final args = createArgs({'name': 'refresh-agent'});
      await api.callTool('register', args).toDart;

      // Refresh should pick up new data
      await api.refreshStatus().toDart;

      // Check agent appears in state
      final agents = api.getAgents();
      assertOk(agents.length > 0, 'Should have at least one agent');
      _log('[COMMANDS TEST] refresh test PASSED');
    }));
  }));

  _log('[COMMANDS TEST] main() completed');
}
