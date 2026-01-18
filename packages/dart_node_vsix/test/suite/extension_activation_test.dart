/// Extension Activation Tests
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart'
    hide consoleError, consoleLog;

import 'test_helpers.dart';

void main() {
  consoleLog('[ACTIVATION TEST] main() called');

  suite('Extension Activation', syncTest(() {
    suiteSetup(asyncTest(() async {
      await waitForExtensionActivation();
    }));

    test('Extension is present and can be activated', asyncTest(() async {
      final extension = vscode.extensions.getExtension(extensionId);
      assertOk(extension != null, 'Extension should be present');
      assertOk(extension!.isActive, 'Extension should be active');
    }));

    test('Extension exports TestAPI', syncTest(() {
      final api = getTestAPI();
      final jsObj = api as JSObject;
      assertOk(jsObj.isA<JSObject>(), 'TestAPI should be available');
    }));

    test('Extension logs activation messages', syncTest(() {
      final api = getTestAPI();
      final logs = api.getLogMessages();
      assertOk(logs.length > 0, 'Extension must produce log messages');

      var hasActivating = false;
      var hasActivated = false;
      for (var i = 0; i < logs.length; i++) {
        final msg = logs[i].toDart;
        if (msg.contains('activating')) hasActivating = true;
        if (msg.contains('activated')) hasActivated = true;
      }
      assertOk(hasActivating, 'Must log activating');
      assertOk(hasActivated, 'Must log activated');
    }));
  }));
}
