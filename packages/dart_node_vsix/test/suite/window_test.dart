/// Window API Tests
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart'
    hide consoleError, consoleLog;

import 'test_helpers.dart';

void main() {
  consoleLog('[WINDOW TEST] main() called');

  suite(
    'Window API',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          await waitForExtensionActivation();
        }),
      );

      test(
        'showInformationMessage returns promise',
        syncTest(() {
          // Note: We only test that the function exists and returns a promise.
          // We cannot await it because dialogs don't auto-dismiss in tests.
          final promise = vscode.window.showInformationMessage('Test message');
          // Promise is non-nullable but we test existence for API verification.
          // ignore: unnecessary_null_comparison
          assertOk(
            promise != null,
            'showInformationMessage should return promise',
          );
        }),
      );

      test(
        'MessageOptions can be created',
        syncTest(() {
          final options = MessageOptions(modal: true);
          // Check that it's a valid JS object by checking typeofEquals
          assertOk(
            (options as JSAny).typeofEquals('object'),
            'Should create options object',
          );
        }),
      );

      test(
        'InputBoxOptions can be created',
        syncTest(() {
          final options = InputBoxOptions(
            prompt: 'Enter value',
            placeHolder: 'placeholder',
            value: 'default',
          );
          assertOk(
            (options as JSAny).typeofEquals('object'),
            'Should create options object',
          );
        }),
      );

      test(
        'QuickPickOptions can be created',
        syncTest(() {
          final options = QuickPickOptions(placeHolder: 'Select an item');
          assertOk(
            (options as JSAny).typeofEquals('object'),
            'Should create options object',
          );
        }),
      );

      test(
        'ViewColumn constants are correct',
        syncTest(() {
          assertEqual(ViewColumn.one, 1);
          assertEqual(ViewColumn.two, 2);
          assertEqual(ViewColumn.three, 3);
        }),
      );
    }),
  );
}
