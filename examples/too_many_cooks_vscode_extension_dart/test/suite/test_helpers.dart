/// Test helpers for VSCode Extension Host integration tests.
///
/// These helpers run in the VSCode Extension Host environment
/// and interact with the REAL compiled extension and MCP server.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_api.dart';

/// Extension ID for the Dart extension.
const extensionId = 'Nimblesite.too-many-cooks-dart';

/// Cached TestAPI instance.
TestAPI? _cachedTestAPI;

/// Server path for tests.
late String _serverPath;

/// Path module.
@JS('require')
external _Path _requirePath(String module);

extension type _Path._(JSObject _) implements JSObject {
  external String resolve(String p1, [String? p2, String? p3, String? p4]);
  external String join(String p1, [String? p2, String? p3, String? p4]);
}

final _path = _requirePath('path');

/// FS module.
@JS('require')
external _Fs _requireFs(String module);

extension type _Fs._(JSObject _) implements JSObject {
  external bool existsSync(String path);
  external void unlinkSync(String path);
}

final _fs = _requireFs('fs');

/// Process environment.
@JS('process.env.HOME')
external String? get _envHome;

/// Console.log.
@JS('console.log')
external void _consoleLog(String message);

/// Console.error.
@JS('console.error')
external void _consoleError(String message);

/// globalThis.
@JS('globalThis')
external JSObject get _globalThis;

/// Reflect.set.
@JS('Reflect.set')
external void _reflectSet(JSObject target, String key, JSAny? value);

/// __dirname (may be null in some environments).
@JS('__dirname')
external String? get _dirnameNullable;

/// Initialize paths and set test server path.
void _initPaths() {
  // __dirname may be null in ES module or certain VSCode test contexts
  // In that case, we don't need to set a custom server path - use npx
  final dirname = _dirnameNullable;
  if (dirname == null) {
    _consoleLog('[TEST HELPER] __dirname is null, skipping server path init');
    _serverPath = '';
    return;
  }
  // __dirname at runtime is out/test/suite
  // Go up 4 levels to examples/, then into too_many_cooks
  _serverPath = _path.resolve(
    dirname,
    '../../../../too_many_cooks/build/bin/server.js',
  );
}

/// Set the test server path on globalThis before extension activates.
void setTestServerPath() {
  _initPaths();
  _reflectSet(_globalThis, '_tooManyCooksTestServerPath', _serverPath.toJS);
  _consoleLog('[TEST HELPER] Set test server path: $_serverPath');
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

/// Wait for the extension to fully activate.
Future<void> waitForExtensionActivation() async {
  _consoleLog('[TEST HELPER] Starting extension activation wait...');

  try {
    // Initialize paths
    _consoleLog('[TEST HELPER] Initializing paths...');
    _initPaths();
    _consoleLog('[TEST HELPER] Paths initialized');

    // Set test server path if local build exists
    // Extension will fall back to npx if not set
    if (_serverPath.isNotEmpty && _fs.existsSync(_serverPath)) {
      setTestServerPath();
    } else {
      _consoleLog('[TEST HELPER] Local server not found, using npx');
    }

    // Get the extension
    _consoleLog('[TEST HELPER] Getting extension...');
    final extension = vscode.extensions.getExtension(extensionId);
    if (extension == null) {
      throw StateError(
        'Extension not found: $extensionId - '
        'check publisher name in package.json',
      );
    }

    _consoleLog('[TEST HELPER] Extension found: ${extension.id}');
    _consoleLog('[TEST HELPER] Extension isActive: ${extension.isActive}');

    // Activate if not already active
    if (!extension.isActive) {
      _consoleLog('[TEST HELPER] Activating extension...');
      await extension.activate().toDart;
      _consoleLog('[TEST HELPER] Extension activate() completed');
    } else {
      _consoleLog('[TEST HELPER] Extension already active');
    }

    // Get exports - should be available immediately after activate
    _consoleLog('[TEST HELPER] Getting exports...');
    final exports = extension.exports;
    _consoleLog('[TEST HELPER] Exports: $exports');
    if (exports != null) {
      _cachedTestAPI = TestAPI(exports as JSObject);
      _consoleLog('[TEST HELPER] Test API verified immediately');
    } else {
      _consoleLog('[TEST HELPER] Waiting for exports...');
      // If not immediately available, wait for them
      await waitForCondition(
        () {
          final exp = extension.exports;
          if (exp != null) {
            _cachedTestAPI = TestAPI(exp as JSObject);
            _consoleLog('[TEST HELPER] Test API verified after wait');
            return true;
          }
          return false;
        },
        message: 'Extension exports not available within timeout',
        timeout: const Duration(seconds: 30),
      );
    }

    _consoleLog('[TEST HELPER] Extension activation complete');
  } on Object catch (e, st) {
    _consoleError('[TEST HELPER] Error: $e');
    _consoleError('[TEST HELPER] Stack: $st');
    rethrow;
  }
}

/// Wait for connection to MCP server.
Future<void> waitForConnection({
  Duration timeout = const Duration(seconds: 30),
}) async {
  _consoleLog('[TEST HELPER] Waiting for MCP connection...');

  final api = getTestAPI();

  await waitForCondition(
    // ignore: unnecessary_lambdas - can't tearoff external extension members
    () => api.isConnected(),
    message: 'MCP connection timed out',
    timeout: timeout,
  );

  _consoleLog('[TEST HELPER] MCP connection established');
}

/// Safely disconnect from MCP server.
Future<void> safeDisconnect() async {
  final api = getTestAPI();

  // Wait a moment for any pending connection to settle
  await Future<void>.delayed(const Duration(milliseconds: 500));

  // Only disconnect if actually connected
  if (api.isConnected()) {
    try {
      await api.disconnect().toDart;
    } on Object {
      // Ignore errors during disconnect
    }
  }

  _consoleLog('[TEST HELPER] Safe disconnect complete');
}

/// Wait for a lock to appear in the tree, refreshing state each poll.
Future<void> waitForLockInTree(
  TestAPI api,
  String filePath, {
  Duration timeout = const Duration(seconds: 10),
  Duration interval = const Duration(milliseconds: 200),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    // Refresh state from server before checking
    try {
      await api.refreshStatus().toDart;
    } on Object {
      // Ignore refresh errors
    }
    if (api.findLockInTree(filePath) != null) return;
    await Future<void>.delayed(interval);
  }
  throw TimeoutException('Lock to appear: $filePath');
}

/// Wait for a lock to disappear from the tree, refreshing state each poll.
Future<void> waitForLockGone(
  TestAPI api,
  String filePath, {
  Duration timeout = const Duration(seconds: 10),
  Duration interval = const Duration(milliseconds: 200),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    try {
      await api.refreshStatus().toDart;
    } on Object {
      // Ignore refresh errors
    }
    if (api.findLockInTree(filePath) == null) return;
    await Future<void>.delayed(interval);
  }
  throw TimeoutException('Lock to disappear: $filePath');
}

/// Wait for an agent to appear in the tree, refreshing state each poll.
Future<void> waitForAgentInTree(
  TestAPI api,
  String agentName, {
  Duration timeout = const Duration(seconds: 10),
  Duration interval = const Duration(milliseconds: 200),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    try {
      await api.refreshStatus().toDart;
    } on Object {
      // Ignore refresh errors
    }
    if (api.findAgentInTree(agentName) != null) return;
    await Future<void>.delayed(interval);
  }
  throw TimeoutException('Agent to appear: $agentName');
}

/// Wait for an agent to disappear from the tree, refreshing state each poll.
Future<void> waitForAgentGone(
  TestAPI api,
  String agentName, {
  Duration timeout = const Duration(seconds: 10),
  Duration interval = const Duration(milliseconds: 200),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    try {
      await api.refreshStatus().toDart;
    } on Object {
      // Ignore refresh errors
    }
    if (api.findAgentInTree(agentName) == null) return;
    await Future<void>.delayed(interval);
  }
  throw TimeoutException('Agent to disappear: $agentName');
}

/// Wait for a message to appear in the tree, refreshing state each poll.
Future<void> waitForMessageInTree(
  TestAPI api,
  String content, {
  Duration timeout = const Duration(seconds: 10),
  Duration interval = const Duration(milliseconds: 200),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    try {
      await api.refreshStatus().toDart;
    } on Object {
      // Ignore refresh errors
    }
    if (api.findMessageInTree(content) != null) return;
    await Future<void>.delayed(interval);
  }
  throw TimeoutException('Message to appear: $content');
}

/// Clean the Too Many Cooks database for fresh test state.
void cleanDatabase() {
  final homeDir = _envHome ?? '/tmp';
  final dbDir = _path.join(homeDir, '.too_many_cooks');

  for (final f in ['data.db', 'data.db-wal', 'data.db-shm']) {
    try {
      _fs.unlinkSync(_path.join(dbDir, f));
    } on Object {
      // Ignore if doesn't exist
    }
  }

  _consoleLog('[TEST HELPER] Database cleaned');
}

/// Restore any dialog mocks (no-op in Dart - kept for API compatibility).
void restoreDialogMocks() {
  // Dialog mocking not implemented in Dart tests yet
}

/// Create a plain JS object via eval (JSObject() constructor doesn't work).
@JS('eval')
external JSObject _evalCreateObj(String code);

/// Create a JSObject from a Map for tool call arguments.
JSObject createArgs(Map<String, Object> args) {
  final obj = _evalCreateObj('({})');
  for (final entry in args.entries) {
    _reflectSet(obj, entry.key, entry.value.jsify());
  }
  return obj;
}

/// Extract agent key from MCP register result.
String extractKeyFromResult(String result) {
  // Result is JSON like: {"agent_key": "xxx", ...}
  final match = RegExp(r'"agent_key"\s*:\s*"([^"]+)"').firstMatch(result);
  if (match == null) {
    throw StateError('Could not extract agent_key from result: $result');
  }
  return match.group(1)!;
}
