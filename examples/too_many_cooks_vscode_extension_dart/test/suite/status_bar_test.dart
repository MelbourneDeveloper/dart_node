/// Status Bar Tests
/// Verifies the connection status updates correctly.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

void main() {
  _log('[STATUS BAR TEST] main() called');

  suite(
    'Status Bar',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          _log('[STATUS] suiteSetup - waiting for extension activation');
          await waitForExtensionActivation();
        }),
      );

      suiteTeardown(
        asyncTest(() async {
          _log('[STATUS] suiteTeardown - disconnecting');
          await safeDisconnect();
        }),
      );

      test(
        'Connection status starts as disconnected',
        syncTest(() {
          _log('[STATUS] Running initial status test');
          final api = getTestAPI();
          assertEqual(api.getConnectionStatus(), 'disconnected');
          _log('[STATUS] initial status test PASSED');
        }),
      );

      test(
        'Connection status changes to connected after connect',
        asyncTest(() async {
          _log('[STATUS] Running connect status test');
          final api = getTestAPI();

          await api.connect().toDart;
          await waitForConnection();

          assertEqual(api.getConnectionStatus(), 'connected');
          _log('[STATUS] connect status test PASSED');
        }),
      );

      test(
        'Connection status changes to disconnected after disconnect',
        asyncTest(() async {
          _log('[STATUS] Running disconnect status test');
          final api = getTestAPI();

          await api.connect().toDart;
          await waitForConnection();
          assertEqual(api.getConnectionStatus(), 'connected');

          await api.disconnect().toDart;
          assertEqual(api.getConnectionStatus(), 'disconnected');
          _log('[STATUS] disconnect status test PASSED');
        }),
      );
    }),
  );

  _log('[STATUS BAR TEST] main() completed');
}
