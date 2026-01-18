/// Configuration Tests
/// Verifies configuration and extension settings work correctly.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

void main() {
  _log('[CONFIGURATION TEST] main() called');

  suite('Configuration', syncTest(() {
    suiteSetup(asyncTest(() async {
      _log('[CONFIG] suiteSetup - waiting for extension activation');
      await waitForExtensionActivation();
    }));

    suiteTeardown(asyncTest(() async {
      _log('[CONFIG] suiteTeardown - disconnecting');
      await safeDisconnect();
    }));

    test('Extension activates with TestAPI exported', syncTest(() {
      _log('[CONFIG] Running TestAPI export test');
      final api = getTestAPI();
      assertOk(api.getConnectionStatus().isNotEmpty, 'TestAPI should work');
      _log('[CONFIG] TestAPI export test PASSED');
    }));

    test('Connection status starts as disconnected', syncTest(() {
      _log('[CONFIG] Running initial status test');
      final api = getTestAPI();
      assertEqual(api.getConnectionStatus(), 'disconnected');
      _log('[CONFIG] initial status test PASSED');
    }));

    test('Connect changes status to connected', asyncTest(() async {
      _log('[CONFIG] Running connect status test');
      final api = getTestAPI();

      await api.connect().toDart;
      await waitForConnection();

      assertEqual(api.getConnectionStatus(), 'connected');
      _log('[CONFIG] connect status test PASSED');
    }));
  }));

  _log('[CONFIGURATION TEST] main() completed');
}
