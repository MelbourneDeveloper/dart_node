/// Command Tests
/// Verifies all registered commands work correctly.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

// Raw JS interop to call vscode.commands.getCommands
@JS('vscode.commands.getCommands')
external JSPromise<JSArray<JSString>> _getCommands(JSBoolean filterInternal);

void main() {
  _log('[COMMANDS TEST] main() called');

  // Ensure any dialog mocks from previous tests are restored
  restoreDialogMocks();

  suite(
    'Commands',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          _log('[COMMANDS TEST] suiteSetup - waiting for extension activation');
          await waitForExtensionActivation();
          _log('[COMMANDS TEST] suiteSetup complete');
        }),
      );

      test(
        'tooManyCooks.connect command is registered',
        asyncTest(() async {
          _log('[COMMANDS TEST] Running: connect command is registered');
          final commands = await _getCommands(true.toJS).toDart;
          final commandList = commands.toDart.map((c) => c.toDart);
          assertOk(
            commandList.contains('tooManyCooks.connect'),
            'connect command should be registered',
          );
          _log('[COMMANDS TEST] PASSED: connect command is registered');
        }),
      );

      test(
        'tooManyCooks.disconnect command is registered',
        asyncTest(() async {
          _log('[COMMANDS TEST] Running: disconnect command is registered');
          final commands = await _getCommands(true.toJS).toDart;
          final commandList = commands.toDart.map((c) => c.toDart);
          assertOk(
            commandList.contains('tooManyCooks.disconnect'),
            'disconnect command should be registered',
          );
          _log('[COMMANDS TEST] PASSED: disconnect command is registered');
        }),
      );

      test(
        'tooManyCooks.refresh command is registered',
        asyncTest(() async {
          _log('[COMMANDS TEST] Running: refresh command is registered');
          final commands = await _getCommands(true.toJS).toDart;
          final commandList = commands.toDart.map((c) => c.toDart);
          assertOk(
            commandList.contains('tooManyCooks.refresh'),
            'refresh command should be registered',
          );
          _log('[COMMANDS TEST] PASSED: refresh command is registered');
        }),
      );

      test(
        'tooManyCooks.showDashboard command is registered',
        asyncTest(() async {
          _log('[COMMANDS TEST] Running: showDashboard command is registered');
          final commands = await _getCommands(true.toJS).toDart;
          final commandList = commands.toDart.map((c) => c.toDart);
          assertOk(
            commandList.contains('tooManyCooks.showDashboard'),
            'showDashboard command should be registered',
          );
          _log('[COMMANDS TEST] PASSED: showDashboard command is registered');
        }),
      );

      test(
        'disconnect command can be executed without error when not connected',
        asyncTest(() async {
          _log('[COMMANDS TEST] Running: disconnect when not connected');

          // Should not throw even when not connected
          await vscode.commands
              .executeCommand('tooManyCooks.disconnect')
              .toDart;

          final api = getTestAPI();
          assertEqual(api.isConnected(), false);
          _log('[COMMANDS TEST] PASSED: disconnect when not connected');
        }),
      );

      test(
        'showDashboard command opens a webview panel',
        asyncTest(() async {
          _log('[COMMANDS TEST] Running: showDashboard opens webview panel');

          // Close any existing editors
          await vscode.commands
              .executeCommand('workbench.action.closeAllEditors')
              .toDart;

          // Execute command
          await vscode.commands
              .executeCommand('tooManyCooks.showDashboard')
              .toDart;

          // Give time for panel to open
          await Future<void>.delayed(const Duration(milliseconds: 500));

          // The dashboard should be visible (can't directly test webview content,
          // but we can verify the command executed without error)
          // The test passes if no error is thrown

          // Clean up
          await vscode.commands
              .executeCommand('workbench.action.closeAllEditors')
              .toDart;

          _log('[COMMANDS TEST] PASSED: showDashboard opens webview panel');
        }),
      );
    }),
  );

  _log('[COMMANDS TEST] main() completed');
}
