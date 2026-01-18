/// Test helpers for dart_node_vsix package tests.
///
/// These helpers run in the VSCode Extension Host environment
/// and test the REAL VSCode extension APIs via dart:js_interop.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';
import 'package:dart_node_vsix/test_api_types.dart';

/// Console logging.
@JS('console.log')
external void consoleLog(String msg);

/// Console error logging.
@JS('console.error')
external void consoleError(String msg);

/// globalThis for setting test globals.
@JS('globalThis')
external JSObject get globalThis;

/// Set a property on an object using Reflect.
@JS('Reflect.set')
external void reflectSet(JSObject target, JSString key, JSAny? value);

/// Get a property from an object using Reflect.
@JS('Reflect.get')
external JSAny? reflectGet(JSObject target, JSString key);

/// Create an empty JS object.
@JS('Object.create')
external JSObject _createJSObjectFromProto(JSAny? proto);

/// Create an empty JS object.
JSObject createJSObject() => _createJSObjectFromProto(null);

/// Extension ID for the test extension.
const extensionId = 'Nimblesite.dart-node-vsix-test';

/// Cached TestAPI instance.
TestAPI? _cachedTestAPI;

/// Wait for a condition to be true, polling at regular intervals.
Future<void> waitForCondition(
  bool Function() condition, {
  String message = 'Condition not met within timeout',
  Duration timeout = const Duration(seconds: 10),
  Duration interval = const Duration(milliseconds: 100),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (condition()) return;
    await Future<void>.delayed(interval);
  }
  throw TimeoutException(message);
}

/// Get the cached TestAPI instance.
TestAPI getTestAPI() {
  if (_cachedTestAPI == null) {
    throw StateError(
      'Test API not initialized - call waitForExtensionActivation first',
    );
  }
  return _cachedTestAPI!;
}

/// Wait for the test extension to fully activate.
Future<void> waitForExtensionActivation() async {
  consoleLog('[TEST HELPER] Starting extension activation wait...');

  // Get the extension
  final extension = vscode.extensions.getExtension(extensionId);
  if (extension == null) {
    throw StateError(
      'Extension not found: $extensionId - '
      'check publisher name in package.json',
    );
  }

  consoleLog('[TEST HELPER] Extension found: ${extension.id}');

  // Activate if not already active
  if (!extension.isActive) {
    consoleLog('[TEST HELPER] Activating extension...');
    await extension.activate().toDart;
    consoleLog('[TEST HELPER] Extension activate() completed');
  } else {
    consoleLog('[TEST HELPER] Extension already active');
  }

  // Get exports - should be available immediately after activate
  consoleLog('[TEST HELPER] Getting exports...');
  final exports = extension.exports;
  if (exports != null) {
    _cachedTestAPI = TestAPI(exports as JSObject);
    consoleLog('[TEST HELPER] Test API verified immediately');
  } else {
    consoleLog('[TEST HELPER] Waiting for exports...');
    await waitForCondition(
      () {
        final exp = extension.exports;
        if (exp != null) {
          _cachedTestAPI = TestAPI(exp as JSObject);
          consoleLog('[TEST HELPER] Test API verified after wait');
          return true;
        }
        return false;
      },
      message: 'Extension exports not available within timeout',
      timeout: const Duration(seconds: 30),
    );
  }

  consoleLog('[TEST HELPER] Extension activation complete');
}

/// Helper to set a property on a JS object.
void setProperty(JSObject obj, String key, JSAny? value) {
  reflectSet(obj, key.toJS, value);
}

/// Helper to get a string property from a JS object.
String? getStringProperty(JSObject obj, String key) {
  final value = reflectGet(obj, key.toJS);
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.typeofEquals('string')) return (value as JSString).toDart;
  return value.toString();
}

/// Helper to get an int property from a JS object.
int? getIntProperty(JSObject obj, String key) {
  final value = reflectGet(obj, key.toJS);
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.typeofEquals('number')) return (value as JSNumber).toDartInt;
  return null;
}

/// Helper to get a bool property from a JS object.
bool? getBoolProperty(JSObject obj, String key) {
  final value = reflectGet(obj, key.toJS);
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.typeofEquals('boolean')) return (value as JSBoolean).toDart;
  return null;
}
