/// Test helpers for VSCode extension integration tests.
///
/// This Dart file compiles to JavaScript and provides utilities
/// for testing the Too Many Cooks VSCode extension.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Global reference to the TestAPI from the extension.
TestAPI? _cachedTestAPI;

/// Path to the local server for testing.
const String serverPath = '../../too_many_cooks/build/bin/server.js';

/// Sets the test server path before extension activates.
void setTestServerPath() {
  globalThis.setProperty('_tooManyCooksTestServerPath'.toJS, serverPath.toJS);
  consoleLog('[TEST HELPER] Set test server path: $serverPath');
}

/// Gets the test API from the extension's exports.
TestAPI getTestAPI() {
  if (_cachedTestAPI == null) {
    throw StateError(
      'Test API not initialized - call waitForExtensionActivation first',
    );
  }
  return _cachedTestAPI!;
}

/// Waits for a condition to be true, polling at regular intervals.
Future<void> waitForCondition(
  bool Function() condition, {
  String message = 'Condition not met within timeout',
  int timeout = 10000,
}) async {
  const interval = 100;
  final startTime = DateTime.now().millisecondsSinceEpoch;

  while (DateTime.now().millisecondsSinceEpoch - startTime < timeout) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: interval));
  }

  throw TimeoutException(message);
}

/// Waits for the extension to fully activate.
Future<void> waitForExtensionActivation() async {
  consoleLog('[TEST HELPER] Starting extension activation wait...');

  setTestServerPath();

  final extension = vscodeExtensions.getExtension(
    'Nimblesite.too-many-cooks-dart',
  );
  if (extension == null) {
    throw StateError(
      'Extension not found - check publisher name in package.json',
    );
  }

  consoleLog('[TEST HELPER] Extension found, checking activation status...');

  if (!extension.isActive) {
    consoleLog('[TEST HELPER] Extension not active, activating now...');
    await extension.activate().toDart;
    consoleLog('[TEST HELPER] Extension activate() completed');
  } else {
    consoleLog('[TEST HELPER] Extension already active');
  }

  await waitForCondition(
    () {
      final exports = extension.exports;
      if (exports != null) {
        _cachedTestAPI = TestAPI(exports);
        consoleLog('[TEST HELPER] Test API verified');
        return true;
      }
      return false;
    },
    message: 'Extension exports not available within timeout',
    timeout: 30000,
  );

  consoleLog('[TEST HELPER] Extension activation complete');
}

/// Waits for connection to the MCP server.
Future<void> waitForConnection({int timeout = 30000}) async {
  consoleLog('[TEST HELPER] Waiting for MCP connection...');

  final api = getTestAPI();

  await waitForCondition(
    api.isConnected,
    message: 'MCP connection timed out',
    timeout: timeout,
  );

  consoleLog('[TEST HELPER] MCP connection established');
}

/// Safely disconnects.
Future<void> safeDisconnect() async {
  final api = getTestAPI();
  await Future<void>.delayed(const Duration(milliseconds: 500));

  if (api.isConnected()) {
    try {
      await api.disconnect();
    } on Object catch (_) {
      // Ignore errors during disconnect
    }
  }

  consoleLog('[TEST HELPER] Safe disconnect complete');
}

/// Cleans the Too Many Cooks database files for fresh test state.
void cleanDatabase() {
  consoleLog('[TEST HELPER] Database cleanup requested');
}

// ============================================================================
// VSCode API Bindings
// ============================================================================

@JS('vscode.extensions')
external VSCodeExtensions get vscodeExtensions;

@JS('console.log')
external void consoleLog(String message);

@JS()
external JSObject get globalThis;

extension type VSCodeExtensions._(JSObject _) implements JSObject {
  external VSCodeExtension? getExtension(String id);
}

extension type VSCodeExtension._(JSObject _) implements JSObject {
  external bool get isActive;
  external JSPromise<JSObject?> activate();
  external JSObject? get exports;
}

// ============================================================================
// TestAPI Wrapper
// ============================================================================

/// Wrapper around the TestAPI JavaScript object exported by the extension.
class TestAPI {
  TestAPI(this._obj);

  final JSObject _obj;

  /// Returns true if the underlying JS object is defined.
  bool get isValid => _obj.isDefinedAndNotNull;

  // State getters
  List<AgentIdentity> getAgents() {
    final result = _callMethod('getAgents');
    if (result == null) return [];
    final arr = result as JSArray;
    return arr.toDart
        .map((e) => AgentIdentity.fromJS(e! as JSObject))
        .toList();
  }

  List<FileLock> getLocks() {
    final result = _callMethod('getLocks');
    if (result == null) return [];
    final arr = result as JSArray;
    return arr.toDart.map((e) => FileLock.fromJS(e! as JSObject)).toList();
  }

  List<Message> getMessages() {
    final result = _callMethod('getMessages');
    if (result == null) return [];
    final arr = result as JSArray;
    return arr.toDart.map((e) => Message.fromJS(e! as JSObject)).toList();
  }

  List<AgentPlan> getPlans() {
    final result = _callMethod('getPlans');
    if (result == null) return [];
    final arr = result as JSArray;
    return arr.toDart.map((e) => AgentPlan.fromJS(e! as JSObject)).toList();
  }

  String getConnectionStatus() {
    final result = _callMethod('getConnectionStatus');
    final str = result as JSString?;
    return str?.toDart ?? 'disconnected';
  }

  // Computed getters
  int getAgentCount() {
    final result = _callMethod('getAgentCount')! as JSNumber;
    return result.toDartInt;
  }

  int getLockCount() {
    final result = _callMethod('getLockCount')! as JSNumber;
    return result.toDartInt;
  }

  int getMessageCount() {
    final result = _callMethod('getMessageCount')! as JSNumber;
    return result.toDartInt;
  }

  int getUnreadMessageCount() {
    final result = _callMethod('getUnreadMessageCount')! as JSNumber;
    return result.toDartInt;
  }

  List<AgentDetails> getAgentDetails() {
    final result = _callMethod('getAgentDetails');
    if (result == null) return [];
    final arr = result as JSArray;
    return arr.toDart
        .map((e) => AgentDetails.fromJS(e! as JSObject))
        .toList();
  }

  // Store actions
  Future<void> connect() async {
    final promise = _callMethod('connect')! as JSPromise;
    await promise.toDart;
  }

  Future<void> disconnect() async {
    final promise = _callMethod('disconnect')! as JSPromise;
    await promise.toDart;
  }

  Future<void> refreshStatus() async {
    final promise = _callMethod('refreshStatus')! as JSPromise;
    await promise.toDart;
  }

  bool isConnected() {
    final result = _callMethod('isConnected')! as JSBoolean;
    return result.toDart;
  }

  bool isConnecting() {
    final result = _callMethod('isConnecting')! as JSBoolean;
    return result.toDart;
  }

  Future<String> callTool(String name, Map<String, Object?> args) async {
    final jsArgs = args.jsify()! as JSObject;
    final fn = _obj.getProperty<JSFunction>('callTool'.toJS);
    final promise =
        fn.callAsFunction(_obj, name.toJS, jsArgs)! as JSPromise<JSString>;
    final result = await promise.toDart;
    return result.toDart;
  }

  Future<void> forceReleaseLock(String filePath) async {
    final fn = _obj.getProperty<JSFunction>('forceReleaseLock'.toJS);
    final promise = fn.callAsFunction(_obj, filePath.toJS)! as JSPromise;
    await promise.toDart;
  }

  Future<void> deleteAgent(String agentName) async {
    final fn = _obj.getProperty<JSFunction>('deleteAgent'.toJS);
    final promise = fn.callAsFunction(_obj, agentName.toJS)! as JSPromise;
    await promise.toDart;
  }

  Future<void> sendMessage(
    String fromAgent,
    String toAgent,
    String content,
  ) async {
    final fn = _obj.getProperty<JSFunction>('sendMessage'.toJS);
    final promise = fn.callAsFunction(
      _obj,
      fromAgent.toJS,
      toAgent.toJS,
      content.toJS,
    )! as JSPromise;
    await promise.toDart;
  }

  // Tree view queries
  int getLockTreeItemCount() {
    final result = _callMethod('getLockTreeItemCount')! as JSNumber;
    return result.toDartInt;
  }

  int getMessageTreeItemCount() {
    final result = _callMethod('getMessageTreeItemCount')! as JSNumber;
    return result.toDartInt;
  }

  // Tree snapshots
  List<TreeItemSnapshot> getAgentsTreeSnapshot() {
    final result = _callMethod('getAgentsTreeSnapshot');
    if (result == null) return [];
    final arr = result as JSArray;
    return arr.toDart
        .map((e) => TreeItemSnapshot.fromJS(e! as JSObject))
        .toList();
  }

  List<TreeItemSnapshot> getLocksTreeSnapshot() {
    final result = _callMethod('getLocksTreeSnapshot');
    if (result == null) return [];
    final arr = result as JSArray;
    return arr.toDart
        .map((e) => TreeItemSnapshot.fromJS(e! as JSObject))
        .toList();
  }

  List<TreeItemSnapshot> getMessagesTreeSnapshot() {
    final result = _callMethod('getMessagesTreeSnapshot');
    if (result == null) return [];
    final arr = result as JSArray;
    return arr.toDart
        .map((e) => TreeItemSnapshot.fromJS(e! as JSObject))
        .toList();
  }

  // Find specific items
  TreeItemSnapshot? findAgentInTree(String agentName) {
    final fn = _obj.getProperty<JSFunction>('findAgentInTree'.toJS);
    final result = fn.callAsFunction(_obj, agentName.toJS);
    if (result == null || result.isUndefinedOrNull) return null;
    return TreeItemSnapshot.fromJS(result as JSObject);
  }

  TreeItemSnapshot? findLockInTree(String filePath) {
    final fn = _obj.getProperty<JSFunction>('findLockInTree'.toJS);
    final result = fn.callAsFunction(_obj, filePath.toJS);
    if (result == null || result.isUndefinedOrNull) return null;
    return TreeItemSnapshot.fromJS(result as JSObject);
  }

  TreeItemSnapshot? findMessageInTree(String content) {
    final fn = _obj.getProperty<JSFunction>('findMessageInTree'.toJS);
    final result = fn.callAsFunction(_obj, content.toJS);
    if (result == null || result.isUndefinedOrNull) return null;
    return TreeItemSnapshot.fromJS(result as JSObject);
  }

  // Logging
  List<String> getLogMessages() {
    final result = _callMethod('getLogMessages');
    if (result == null) return [];
    final arr = result as JSArray;
    return arr.toDart.map((e) => (e! as JSString).toDart).toList();
  }

  JSAny? _callMethod(String name) {
    final fn = _obj.getProperty<JSFunction>(name.toJS);
    return fn.callAsFunction(_obj);
  }
}

// ============================================================================
// Data Models
// ============================================================================

class AgentIdentity {
  AgentIdentity({
    required this.agentName,
    required this.registeredAt,
    required this.lastActive,
  });

  factory AgentIdentity.fromJS(JSObject obj) {
    final name = obj.getProperty<JSString>('agentName'.toJS).toDart;
    final reg = obj.getProperty<JSNumber>('registeredAt'.toJS).toDartInt;
    final active = obj.getProperty<JSNumber>('lastActive'.toJS).toDartInt;
    return AgentIdentity(
      agentName: name,
      registeredAt: reg,
      lastActive: active,
    );
  }

  final String agentName;
  final int registeredAt;
  final int lastActive;
}

class FileLock {
  FileLock({
    required this.filePath,
    required this.agentName,
    required this.acquiredAt,
    required this.expiresAt,
    this.reason,
  });

  factory FileLock.fromJS(JSObject obj) {
    final path = obj.getProperty<JSString>('filePath'.toJS).toDart;
    final agent = obj.getProperty<JSString>('agentName'.toJS).toDart;
    final acq = obj.getProperty<JSNumber>('acquiredAt'.toJS).toDartInt;
    final exp = obj.getProperty<JSNumber>('expiresAt'.toJS).toDartInt;
    final reasonJS = obj.getProperty<JSString?>('reason'.toJS);
    return FileLock(
      filePath: path,
      agentName: agent,
      acquiredAt: acq,
      expiresAt: exp,
      reason: reasonJS?.toDart,
    );
  }

  final String filePath;
  final String agentName;
  final int acquiredAt;
  final int expiresAt;
  final String? reason;
}

class Message {
  Message({
    required this.id,
    required this.fromAgent,
    required this.toAgent,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  factory Message.fromJS(JSObject obj) {
    final id = obj.getProperty<JSString>('id'.toJS).toDart;
    final from = obj.getProperty<JSString>('fromAgent'.toJS).toDart;
    final to = obj.getProperty<JSString>('toAgent'.toJS).toDart;
    final content = obj.getProperty<JSString>('content'.toJS).toDart;
    final created = obj.getProperty<JSNumber>('createdAt'.toJS).toDartInt;
    final readJS = obj.getProperty<JSNumber?>('readAt'.toJS);
    return Message(
      id: id,
      fromAgent: from,
      toAgent: to,
      content: content,
      createdAt: created,
      readAt: readJS?.toDartInt,
    );
  }

  final String id;
  final String fromAgent;
  final String toAgent;
  final String content;
  final int createdAt;
  final int? readAt;
}

class AgentPlan {
  AgentPlan({
    required this.agentName,
    required this.goal,
    required this.currentTask,
    required this.updatedAt,
  });

  factory AgentPlan.fromJS(JSObject obj) {
    final agent = obj.getProperty<JSString>('agentName'.toJS).toDart;
    final goal = obj.getProperty<JSString>('goal'.toJS).toDart;
    final task = obj.getProperty<JSString>('currentTask'.toJS).toDart;
    final updated = obj.getProperty<JSNumber>('updatedAt'.toJS).toDartInt;
    return AgentPlan(
      agentName: agent,
      goal: goal,
      currentTask: task,
      updatedAt: updated,
    );
  }

  final String agentName;
  final String goal;
  final String currentTask;
  final int updatedAt;
}

class TreeItemSnapshot {
  TreeItemSnapshot({
    required this.label,
    this.description,
    this.children,
  });

  factory TreeItemSnapshot.fromJS(JSObject obj) {
    final labelStr = obj.getProperty<JSString>('label'.toJS).toDart;
    final descJS = obj.getProperty<JSString?>('description'.toJS);
    final childrenJS = obj.getProperty<JSArray?>('children'.toJS);
    List<TreeItemSnapshot>? children;
    if (childrenJS != null) {
      children = childrenJS.toDart
          .map((e) => TreeItemSnapshot.fromJS(e! as JSObject))
          .toList();
    }
    return TreeItemSnapshot(
      label: labelStr,
      description: descJS?.toDart,
      children: children,
    );
  }

  final String label;
  final String? description;
  final List<TreeItemSnapshot>? children;
}

class AgentDetails {
  AgentDetails({
    required this.agent,
    required this.locks,
    required this.sentMessages,
    required this.receivedMessages,
    this.plan,
  });

  factory AgentDetails.fromJS(JSObject obj) {
    final agentJS = obj.getProperty<JSObject>('agent'.toJS);
    final locksJS = obj.getProperty<JSArray>('locks'.toJS);
    final sentJS = obj.getProperty<JSArray>('sentMessages'.toJS);
    final recvJS = obj.getProperty<JSArray>('receivedMessages'.toJS);
    final planJS = obj.getProperty<JSObject?>('plan'.toJS);

    return AgentDetails(
      agent: AgentIdentity.fromJS(agentJS),
      locks: locksJS.toDart
          .map((e) => FileLock.fromJS(e! as JSObject))
          .toList(),
      sentMessages: sentJS.toDart
          .map((e) => Message.fromJS(e! as JSObject))
          .toList(),
      receivedMessages: recvJS.toDart
          .map((e) => Message.fromJS(e! as JSObject))
          .toList(),
      plan: planJS != null ? AgentPlan.fromJS(planJS) : null,
    );
  }

  final AgentIdentity agent;
  final List<FileLock> locks;
  final AgentPlan? plan;
  final List<Message> sentMessages;
  final List<Message> receivedMessages;
}
