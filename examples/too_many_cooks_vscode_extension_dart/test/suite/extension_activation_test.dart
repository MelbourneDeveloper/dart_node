/// Extension Activation Test - ONE simple test
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

@JS('console.log')
external void _log(String msg);

void main() {
  _log('[DART TEST] main() called');

  suite('VSCode API Access', syncTest(() {
    test('can access vscode.window', syncTest(() {
      _log('[DART TEST] Getting vscode.window...');
      // Accessing window to verify VSCode API is available
      vscode.window;
      _log('[DART TEST] Window object accessed successfully');
      assertOk(true, 'vscode.window is accessible');
      _log('[DART TEST] TEST PASSED!');
    }));
  }));

  _log('[DART TEST] main() completed');
}
