/// Output Channel API Tests
library;

import 'package:dart_node_vsix/dart_node_vsix.dart'
    hide consoleError, consoleLog;

import 'test_helpers.dart';

void main() {
  consoleLog('[OUTPUT CHANNEL TEST] main() called');

  suite(
    'Output Channel API',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          await waitForExtensionActivation();
        }),
      );

      test(
        'Extension creates output channel',
        syncTest(() {
          final api = getTestAPI();
          assertEqual(api.getOutputChannelName(), 'VSIX Test');
        }),
      );

      test(
        'createOutputChannel creates channel with name',
        syncTest(() {
          final channel = vscode.window.createOutputChannel('Test Channel');
          assertEqual(channel.name, 'Test Channel');
          channel.dispose();
        }),
      );

      test(
        'Output channel append and appendLine work',
        syncTest(() {
          final channel = vscode.window.createOutputChannel('Append Test')
            ..append('Hello ')
            ..appendLine('World');
          assertOk(true, 'append/appendLine should work');
          channel.dispose();
        }),
      );

      test(
        'Output channel clear works',
        syncTest(() {
          final channel = vscode.window.createOutputChannel('Clear Test')
            ..appendLine('Some text')
            ..clear();
          assertOk(true, 'clear should work');
          channel.dispose();
        }),
      );

      test(
        'Output channel show and hide work',
        syncTest(() {
          final channel = vscode.window.createOutputChannel('Show Test')
            ..show()
            ..hide();
          assertOk(true, 'show/hide should work');
          channel.dispose();
        }),
      );
    }),
  );
}
