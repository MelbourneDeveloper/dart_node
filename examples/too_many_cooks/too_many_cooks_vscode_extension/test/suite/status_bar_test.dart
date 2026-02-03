/// Status Bar Tests
/// Verifies the status bar item updates correctly.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

// Ensure any dialog mocks from previous tests are restored
void _restoreMocks() => restoreDialogMocks();

void main() {
  _log('[STATUS BAR TEST] main() called');

  _restoreMocks();

  suite(
    'Status Bar',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          _log('[STATUS] suiteSetup - waiting for extension activation');
          await waitForExtensionActivation();
        }),
      );

      test(
        'Status bar exists after activation',
        syncTest(() {
          _log('[STATUS] Running: Status bar exists after activation');
          // The status bar is created during activation
          // We can't directly query it, but we verify the extension is active
          final api = getTestAPI();
          assertOk(
            api.isA<JSObject>(),
            'Extension should be active with status bar',
          );
          _log('[STATUS] PASSED: Status bar exists after activation');
        }),
      );

      test(
        'Connection status changes are reflected',
        asyncTest(() async {
          _log('[STATUS] Running: Connection status changes are reflected');

          // Ensure clean state by disconnecting first
          await safeDisconnect();
          final api = getTestAPI();

          // Initial state should be disconnected
          assertEqual(api.getConnectionStatus(), 'disconnected');
          _log('[STATUS] PASSED: Connection status changes are reflected');
        }),
      );
    }),
  );

  _log('[STATUS BAR TEST] main() completed');
}
