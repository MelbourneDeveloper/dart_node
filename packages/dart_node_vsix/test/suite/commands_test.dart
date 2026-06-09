/// Commands API Tests
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart'
    hide consoleError, consoleLog;

import 'test_helpers.dart';

@JS('vscode.commands.getCommands')
external JSPromise<JSArray<JSString>> _getCommands(JSBoolean filterInternal);

void main() {
  consoleLog('[COMMANDS TEST] main() called');

  suite(
    'Commands API',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          await waitForExtensionActivation();
        }),
      );

      test(
        'registerCommand registers the self-test command',
        asyncTest(() async {
          final commands = await _getCommands(true.toJS).toDart;
          final list = commands.toDart.map((c) => c.toDart);
          assertOk(
            list.contains('dartNode.test'),
            'Self-test command should be registered',
          );
        }),
      );

      test(
        'general-purpose feature commands are registered',
        asyncTest(() async {
          final commands = await _getCommands(true.toJS).toDart;
          final list = commands.toDart.map((c) => c.toDart).toList();
          for (final id in const [
            'dartNode.hello',
            'dartNode.showVersion',
            'dartNode.echo',
            'dartNode.count',
          ]) {
            assertOk(list.contains(id), '$id should be registered');
          }
        }),
      );

      test(
        'getCommands returns array of commands',
        asyncTest(() async {
          final commands = await vscode.commands.getCommands(true).toDart;
          assertOk(commands.toDart.isNotEmpty, 'Should have commands');
        }),
      );

      test(
        'executeCommand runs without error',
        asyncTest(() async {
          // Execute a safe built-in command
          await vscode.commands
              .executeCommand('workbench.action.closeAllEditors')
              .toDart;
          // If we get here, it worked
          assertOk(true, 'executeCommand should work');
        }),
      );
    }),
  );
}
