/// Extension Activation Test - ONE simple test
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

@JS('console.log')
external void _log(String msg);

void main() {
  _log('[DART TEST] main() called');

  suite('VSCode API Access', syncTest(() {
    test('Extension is loaded and vscode API is accessible', syncTest(() {
      _log('[DART TEST] Checking VSCode API access...');

      // Verify extensions API is available by checking our extension
      const extId = 'Nimblesite.too-many-cooks-dart';
      final ext = vscode.extensions.getExtension(extId);
      assertOk(ext != null, 'Our extension should be loaded');
      _log('[DART TEST] Extension found: ${ext?.id}');

      // Verify workspace API is available
      final config = vscode.workspace.getConfiguration('tooManyCooks');
      final autoConnect = config.get<JSBoolean>('autoConnect');
      _log('[DART TEST] Config autoConnect: $autoConnect');

      // Verify we can access extension exports
      final exports = ext?.exports;
      assertOk(exports != null, 'Extension should have exports');
      _log('[DART TEST] Extension exports available');

      _log('[DART TEST] TEST PASSED!');
    }));
  }));

  _log('[DART TEST] main() completed');
}
