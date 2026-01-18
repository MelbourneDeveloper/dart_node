/// Status Bar API Tests
library;

import 'package:dart_node_vsix/dart_node_vsix.dart'
    hide consoleError, consoleLog;

import 'test_helpers.dart';

void main() {
  consoleLog('[STATUS BAR TEST] main() called');

  suite(
    'Status Bar API',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          await waitForExtensionActivation();
        }),
      );

      test(
        'Status bar item is created with correct text',
        syncTest(() {
          final api = getTestAPI();
          final text = api.getStatusBarText();
          assertOk(
            text.contains('VSIX Test'),
            'Status bar should have test text',
          );
        }),
      );

      test(
        'StatusBarAlignment enum has correct values',
        syncTest(() {
          assertEqual(StatusBarAlignment.left.value, 1);
          assertEqual(StatusBarAlignment.right.value, 2);
        }),
      );

      test(
        'createStatusBarItem creates item',
        syncTest(() {
          final item = vscode.window.createStatusBarItem(
            StatusBarAlignment.right.value,
            50,
          )..text = 'Test Item';
          assertEqual(item.text, 'Test Item');
          item.dispose();
        }),
      );

      test(
        'Status bar item tooltip can be set',
        syncTest(() {
          final item = vscode.window.createStatusBarItem()
            ..tooltip = 'My Tooltip';
          assertEqual(item.tooltip, 'My Tooltip');
          item.dispose();
        }),
      );

      test(
        'Status bar item command can be set',
        syncTest(() {
          final item = vscode.window.createStatusBarItem()
            ..command = 'workbench.action.toggleSidebarVisibility';
          assertEqual(item.command, 'workbench.action.toggleSidebarVisibility');
          item.dispose();
        }),
      );
    }),
  );
}
