/// Test helpers for VSCode Extension Host integration tests.
///
/// These helpers run in the VSCode Extension Host environment
/// and interact with the REAL compiled extension and MCP server.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';
import 'package:dart_node_vsix/src/js_helpers.dart' as js;

import 'test_api.dart';

// Re-export commonly used helpers from js_helpers for convenience.
export 'package:dart_node_vsix/src/js_helpers.dart'
    show
        consoleError,
        consoleLog,
        countTreeItemChildren,
        dateNow,
        dumpTreeSnapshot,
        extractAgentKeyFromResult,
        findTreeItemChildByLabel,
        getStringProp,
        getTreeItemChildren,
        getTreeItemDescription,
        getTreeItemLabel,
        reflectGet,
        reflectSet,
        treeItemHasChildWithLabel;

/// Extension ID for the Dart extension.
const extensionId = 'Nimblesite.too-many-cooks-dart';

/// Cached TestAPI instance.
TestAPI? _cachedTestAPI;

/// Server path for tests.
var _serverPath = '';

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

// Private aliases that delegate to js_helpers (for internal use).
void _consoleLog(String msg) => js.consoleLog(msg);
void _consoleError(String msg) => js.consoleError(msg);
void _reflectSet(JSObject target, String key, JSAny? value) =>
    js.reflectSet(target, key, value);
JSObject get _globalThis => js.globalThis;
String? get _dirnameNullable => js.dirname;

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

// =============================================================================
// Dialog Mocking Infrastructure
// =============================================================================

/// Get the vscode.window object for mocking.
@JS('require')
external JSObject _requireVscodeModule(String module);

@JS('Reflect.get')
external JSAny? _reflectGetAny(JSObject target, JSString key);

/// Get a property from a JS object.
JSAny? _jsGet(JSObject target, String key) => _reflectGetAny(target, key.toJS);

/// Get vscode.window using globalThis.vscode (where the extension wrapper
/// stores it). This ensures we get the SAME vscode module instance that the
/// compiled extension uses, not a potentially different require() result.
@JS('globalThis.vscode.window')
external JSObject get _globalVscodeWindow;

JSObject _getVscodeWindow() {
  // First try globalThis.vscode.window (set by extension wrapper)
  try {
    final window = _globalVscodeWindow;
    _consoleLog('[_getVscodeWindow] Using globalThis.vscode.window');
    return window;
  } on Object {
    // Fallback to require('vscode').window
    _consoleLog('[_getVscodeWindow] Falling back to require("vscode").window');
    final vscodeModule = _requireVscodeModule('vscode');
    final window = _jsGet(vscodeModule, 'window');
    if (window == null) throw StateError('vscode.window is null');
    return window as JSObject;
  }
}


/// Eval for creating JS functions.
@JS('eval')
external JSAny _eval(String code);

/// Stored original methods (captured at first mock install).
JSAny? _storedShowWarningMessage;
JSAny? _storedShowQuickPick;
JSAny? _storedShowInputBox;

/// Mock response queues.
final List<String?> _warningMessageResponses = [];
final List<String?> _quickPickResponses = [];
final List<String?> _inputBoxResponses = [];

/// Whether mocks are currently installed.
bool _mocksInstalled = false;

/// Queue a response for the next showWarningMessage call.
void mockWarningMessage(String? response) {
  if (_mocksInstalled) {
    // Push directly to the JS array
    _pushWarningResponse(response?.toJS);
  } else {
    _warningMessageResponses.add(response);
  }
}

/// Queue a response for the next showQuickPick call.
/// Uses extension-side test queue (not vscode.window mock) to bypass dart2js
/// interop issues with showQuickPick's complex signature.
void mockQuickPick(String? response) {
  _consoleLog('[mockQuickPick] called with: $response');
  // Always use extension-side queue (set up in installDialogMocks)
  _pushTestQuickPickResponse(response?.toJS);
  _consoleLog('[mockQuickPick] pushed to extension test queue');
}

/// Queue a response for the next showInputBox call.
void mockInputBox(String? response) {
  if (_mocksInstalled) {
    // Push directly to the JS array
    _pushInputBoxResponse(response?.toJS);
  } else {
    _inputBoxResponses.add(response);
  }
}

/// Set global JS arrays for mock responses.
@JS('globalThis._mockWarningResponses')
external set _globalMockWarningResponses(JSArray<JSAny?> arr);

@JS('globalThis._mockQuickPickResponses')
external set _globalMockQuickPickResponses(JSArray<JSAny?> arr);

@JS('globalThis._mockInputBoxResponses')
external set _globalMockInputBoxResponses(JSArray<JSAny?> arr);

/// Extension-side test queue for QuickPick (bypasses vscode.window mock).
/// The extension checks this queue and uses it instead of real showQuickPick.
@JS('globalThis._testQuickPickResponses')
external set _globalTestQuickPickResponses(JSArray<JSAny?>? arr);

/// Push to extension-side test QuickPick queue.
@JS('globalThis._testQuickPickResponses.push')
external void _pushTestQuickPickResponse(JSAny? response);

/// Push to the global JS array for warning message responses.
@JS('globalThis._mockWarningResponses.push')
external void _pushWarningResponse(JSAny? response);

/// Push to the global JS array for quick pick responses (old mock approach).
@JS('globalThis._mockQuickPickResponses.push')
external void _pushQuickPickResponse(JSAny? response);

/// Push to the global JS array for input box responses.
@JS('globalThis._mockInputBoxResponses.push')
external void _pushInputBoxResponse(JSAny? response);

/// Create a pure JS mock function that shifts from a global array.
/// NO Dart callbacks - pure JS reading from JS arrays.
/// Returns an async function that accepts any number of parameters but ignores
/// them, matching VSCode's dialog methods signature.
///
/// CRITICAL: Uses eval to create a pure JS async arrow function that returns
/// a Promise, exactly matching how TypeScript mocks work.
JSAny _createPureJsArrayMock(String arrayName) => _eval(
      // Arrow function exactly like TypeScript mock pattern.
      'async (items, options) => { '
      'console.log("[MOCK] $arrayName called"); '
      'var arr = globalThis.$arrayName || []; '
      'var val = arr.shift(); '
      'console.log("[MOCK] $arrayName returning:", val); '
      'return val === undefined ? null : val; '
      '}',
    );

/// Install dialog mocks on vscode.window.
void installDialogMocks() {
  if (_mocksInstalled) return;

  final window = _getVscodeWindow();

  // Store originals on first install
  _storedShowWarningMessage ??= _jsGet(window, 'showWarningMessage');
  _storedShowQuickPick ??= _jsGet(window, 'showQuickPick');
  _storedShowInputBox ??= _jsGet(window, 'showInputBox');

  // Initialize global JS arrays (empty arrays that will be modified in-place)
  _globalMockWarningResponses = <JSAny?>[].toJS;
  _globalMockQuickPickResponses = <JSAny?>[].toJS;
  _globalMockInputBoxResponses = <JSAny?>[].toJS;

  // Initialize extension-side test queue for QuickPick
  // The extension checks this and bypasses vscode.window.showQuickPick entirely
  _globalTestQuickPickResponses = <JSAny?>[].toJS;
  _consoleLog('[MOCK INSTALL] Extension QuickPick test queue initialized');

  // Copy any pre-queued responses from Dart lists to JS arrays
  for (final r in _warningMessageResponses) {
    _pushWarningResponse(r?.toJS);
  }
  for (final r in _inputBoxResponses) {
    _pushInputBoxResponse(r?.toJS);
  }
  _warningMessageResponses.clear();
  _quickPickResponses.clear();
  _inputBoxResponses.clear();

  // Install pure JS mock functions for warning and input box
  // QuickPick uses extension-side queue instead (bypasses dart2js issues)
  _reflectSet(_globalThis, '_testMockedWindow', window);

  _reflectSet(
    window,
    'showWarningMessage',
    _createPureJsArrayMock('_mockWarningResponses'),
  );

  // NOTE: showQuickPick is NOT mocked here - extension checks
  // _testQuickPickResponses queue directly to avoid dart2js interop issues

  _reflectSet(
    window,
    'showInputBox',
    _createPureJsArrayMock('_mockInputBoxResponses'),
  );

  _consoleLog('[MOCK INSTALL] Dialog mocks installed (QuickPick uses '
      'extension-side queue)');

  _mocksInstalled = true;
  _consoleLog('[TEST HELPER] Dialog mocks installed');
}

/// Restore original dialog methods.
void restoreDialogMocks() {
  if (!_mocksInstalled) return;

  final window = _getVscodeWindow();

  if (_storedShowWarningMessage != null) {
    _reflectSet(window, 'showWarningMessage', _storedShowWarningMessage);
  }
  if (_storedShowQuickPick != null) {
    _reflectSet(window, 'showQuickPick', _storedShowQuickPick);
  }
  if (_storedShowInputBox != null) {
    _reflectSet(window, 'showInputBox', _storedShowInputBox);
  }

  // Clear extension-side test queue
  _globalTestQuickPickResponses = null;

  _warningMessageResponses.clear();
  _quickPickResponses.clear();
  _inputBoxResponses.clear();
  _mocksInstalled = false;
  _consoleLog('[TEST HELPER] Dialog mocks restored');
}

/// Helper to open the Too Many Cooks panel.
Future<void> openTooManyCooksPanel() async {
  _consoleLog('[TEST HELPER] Opening Too Many Cooks panel...');
  await vscode.commands
      .executeCommand('workbench.view.extension.tooManyCooks')
      .toDart;
  // Wait for panel to be visible
  await Future<void>.delayed(const Duration(milliseconds: 500));
  _consoleLog('[TEST HELPER] Panel opened');
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
