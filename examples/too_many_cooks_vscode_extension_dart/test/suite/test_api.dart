/// TestAPI interface for accessing extension exports in integration tests.
///
/// This mirrors the TestAPI exposed by the Dart extension for testing.
library;

import 'dart:js_interop';

/// TestAPI wrapper for the extension's exported test interface.
extension type TestAPI(JSObject _) implements JSObject {
  // State getters
  external JSArray<JSObject> getAgents();
  external JSArray<JSObject> getLocks();
  external JSArray<JSObject> getMessages();
  external JSArray<JSObject> getPlans();
  external String getConnectionStatus();

  // Computed getters
  external int getAgentCount();
  external int getLockCount();
  external int getMessageCount();
  external int getUnreadMessageCount();
  external JSArray<JSObject> getAgentDetails();

  // Store actions
  external JSPromise<JSAny?> connect();
  external JSPromise<JSAny?> disconnect();
  external JSPromise<JSAny?> refreshStatus();
  external bool isConnected();
  external bool isConnecting();
  external JSPromise<JSString> callTool(String name, JSObject args);
  external JSPromise<JSAny?> forceReleaseLock(String filePath);
  external JSPromise<JSAny?> deleteAgent(String agentName);
  external JSPromise<JSAny?> sendMessage(
    String fromAgent,
    String toAgent,
    String content,
  );

  // Tree view queries
  external int getLockTreeItemCount();
  external int getMessageTreeItemCount();

  // Tree snapshots
  external JSArray<JSObject> getAgentsTreeSnapshot();
  external JSArray<JSObject> getLocksTreeSnapshot();
  external JSArray<JSObject> getMessagesTreeSnapshot();

  // Find in tree
  external JSObject? findAgentInTree(String agentName);
  external JSObject? findLockInTree(String filePath);
  external JSObject? findMessageInTree(String content);

  // Logging
  external JSArray<JSString> getLogMessages();
}

/// Helper to create JS object for tool arguments.
@JS('eval')
external JSObject _eval(String code);

JSObject createArgs(Map<String, Object?> args) {
  final obj = _eval('({})');
  for (final entry in args.entries) {
    _setProperty(obj, entry.key, entry.value.jsify());
  }
  return obj;
}

@JS('Reflect.set')
external void _setProperty(JSObject target, String key, JSAny? value);
