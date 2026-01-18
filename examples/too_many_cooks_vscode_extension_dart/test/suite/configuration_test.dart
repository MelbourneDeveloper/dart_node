/// Configuration Tests
/// Verifies configuration settings work correctly.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

void main() {
  _log('[CONFIGURATION TEST] main() called');

  // Ensure any dialog mocks from previous tests are restored
  restoreDialogMocks();

  suite('Configuration', syncTest(() {
    suiteSetup(asyncTest(() async {
      _log('[CONFIG] suiteSetup - waiting for extension activation');
      await waitForExtensionActivation();
    }));

    test('autoConnect configuration exists', syncTest(() {
      _log('[CONFIG] Running: autoConnect configuration exists');
      final config = vscode.workspace.getConfiguration('tooManyCooks');
      final autoConnect = config.get<JSBoolean>('autoConnect');
      assertOk(
        !autoConnect.isUndefinedOrNull,
        'autoConnect config should exist',
      );
      _log('[CONFIG] PASSED: autoConnect configuration exists');
    }));

    test('autoConnect defaults to true', syncTest(() {
      _log('[CONFIG] Running: autoConnect defaults to true');
      final config = vscode.workspace.getConfiguration('tooManyCooks');
      final autoConnect = config.get<JSBoolean>('autoConnect');
      // Default is true according to package.json
      assertEqual(autoConnect?.toDart, true);
      _log('[CONFIG] PASSED: autoConnect defaults to true');
    }));
  }));

  _log('[CONFIGURATION TEST] main() completed');
}
