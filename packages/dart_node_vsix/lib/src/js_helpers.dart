/// JavaScript interop helpers for VSCode extension tests.
///
/// This module centralizes common JS interop patterns so test files
/// don't need to repeat `@JS()` declarations and helper functions.
library;

import 'dart:js_interop';

// =============================================================================
// Core JS Interop - Reflect API
// =============================================================================

/// Get a property from a JS object using Reflect.get.
@JS('Reflect.get')
external JSAny? reflectGet(JSObject target, String key);

/// Set a property on a JS object using Reflect.set.
@JS('Reflect.set')
external void reflectSet(JSObject target, String key, JSAny? value);

// =============================================================================
// Console API
// =============================================================================

/// console.log - logs a message to the console.
@JS('console.log')
external void consoleLog(String message);

/// console.error - logs an error message to the console.
@JS('console.error')
external void consoleError(String message);

/// console.warn - logs a warning message to the console.
@JS('console.warn')
external void consoleWarn(String message);

// =============================================================================
// Date API
// =============================================================================

/// Date.now() - returns current timestamp in milliseconds.
@JS('Date.now')
external int dateNow();

// =============================================================================
// Promise API
// =============================================================================

/// Create a resolved Promise with a value.
@JS('Promise.resolve')
external JSPromise<T> promiseResolve<T extends JSAny?>(T? value);

// =============================================================================
// Global Objects
// =============================================================================

/// globalThis reference.
@JS('globalThis')
external JSObject get globalThis;

/// __dirname (may be null in some environments).
@JS('__dirname')
external String? get dirname;

// =============================================================================
// Evaluation (for creating plain JS objects)
// =============================================================================

/// Create a plain JS object via eval.
/// Usage: `final obj = evalCreateObject('({})');`
@JS('eval')
external JSObject evalCreateObject(String code);

// =============================================================================
// Property Access Helpers
// =============================================================================

/// Gets a string property from a JS object, returns empty string if not found.
String getStringProp(JSObject obj, String key) {
  final value = reflectGet(obj, key);
  if (value == null || value.isUndefinedOrNull) return '';
  if (value.typeofEquals('string')) return (value as JSString).toDart;
  return value.dartify()?.toString() ?? '';
}

/// Gets an int property from a JS object, returns 0 if not found.
int getIntProp(JSObject obj, String key) {
  final value = reflectGet(obj, key);
  if (value == null || value.isUndefinedOrNull) return 0;
  if (value.typeofEquals('number')) return (value as JSNumber).toDartInt;
  return 0;
}

/// Gets a bool property from a JS object, returns false if not found.
bool getBoolProp(JSObject obj, String key) {
  final value = reflectGet(obj, key);
  if (value == null || value.isUndefinedOrNull) return false;
  if (value.typeofEquals('boolean')) return (value as JSBoolean).toDart;
  return false;
}

/// Gets an optional string property from a JS object.
String? getStringPropOrNull(JSObject obj, String key) {
  final value = reflectGet(obj, key);
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.typeofEquals('string')) return (value as JSString).toDart;
  return value.dartify()?.toString();
}

/// Gets an array property from a JS object, returns null if not found.
JSArray<JSObject>? getArrayProp(JSObject obj, String key) {
  final value = reflectGet(obj, key);
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.typeofEquals('object') && value.instanceOfString('Array')) {
    return value as JSArray<JSObject>;
  }
  return null;
}

/// Gets a JSObject property, returns null if not found.
JSObject? getObjectProp(JSObject obj, String key) {
  final value = reflectGet(obj, key);
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.typeofEquals('object')) return value as JSObject;
  return null;
}

// =============================================================================
// Tree Item Helpers (for VSCode TreeView testing)
// =============================================================================

/// Get the label from a tree item snapshot.
String getTreeItemLabel(JSObject item) => getStringProp(item, 'label');

/// Get the description from a tree item snapshot.
String? getTreeItemDescription(JSObject item) =>
    getStringPropOrNull(item, 'description');

/// Get the children from a tree item snapshot.
JSArray<JSObject>? getTreeItemChildren(JSObject item) =>
    getArrayProp(item, 'children');

/// Check if a tree item has a child with label containing text.
bool treeItemHasChildWithLabel(JSObject item, String text) {
  final children = getTreeItemChildren(item);
  if (children == null) return false;
  for (var i = 0; i < children.length; i++) {
    if (getTreeItemLabel(children[i]).contains(text)) return true;
  }
  return false;
}

/// Find a child item by label content.
JSObject? findTreeItemChildByLabel(JSObject item, String text) {
  final children = getTreeItemChildren(item);
  if (children == null) return null;
  for (var i = 0; i < children.length; i++) {
    final child = children[i];
    if (getTreeItemLabel(child).contains(text)) return child;
  }
  return null;
}

/// Count children matching a predicate.
int countTreeItemChildren(JSObject item, bool Function(JSObject) predicate) {
  final children = getTreeItemChildren(item);
  if (children == null) return 0;
  var count = 0;
  for (var i = 0; i < children.length; i++) {
    if (predicate(children[i])) count++;
  }
  return count;
}

/// Dump a tree snapshot for debugging.
void dumpTreeSnapshot(String name, JSArray<JSObject> items) {
  consoleLog('\n=== $name TREE ===');
  void dump(JSArray<JSObject> items, int indent) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final prefix = '  ' * indent;
      final label = getTreeItemLabel(item);
      final desc = getTreeItemDescription(item);
      final descStr = desc != null ? ' [$desc]' : '';
      consoleLog('$prefix- $label$descStr');
      final children = getTreeItemChildren(item);
      if (children != null) dump(children, indent + 1);
    }
  }
  dump(items, 0);
  consoleLog('=== END ===\n');
}

// =============================================================================
// Object Creation Helpers
// =============================================================================

/// Create a JSObject from a Map for tool call arguments.
JSObject createJsObject(Map<String, Object> args) {
  final obj = evalCreateObject('({})');
  for (final entry in args.entries) {
    reflectSet(obj, entry.key, entry.value.jsify());
  }
  return obj;
}

// =============================================================================
// Parsing Helpers
// =============================================================================

/// Extract agent key from MCP register result JSON.
/// Result is JSON like: {"agent_key": "xxx", ...}
String extractAgentKeyFromResult(String result) {
  final match = RegExp(r'"agent_key"\s*:\s*"([^"]+)"').firstMatch(result);
  if (match == null) {
    throw StateError('Could not extract agent_key from result: $result');
  }
  return match.group(1)!;
}

/// Extract message ID from MCP message result JSON.
String? extractMessageIdFromResult(String result) {
  final match = RegExp(r'"id"\s*:\s*(\d+)').firstMatch(result);
  return match?.group(1);
}

// =============================================================================
// Typed Extension Types - Mirror TypeScript interfaces for VSCode/MCP
// =============================================================================

/// Serializable tree item snapshot for test assertions.
/// Proves what appears in the UI - matches TypeScript `TreeItemSnapshot`.
/// Note: This is a JS interop type wrapping raw JSObject from TestAPI.
extension type JSTreeItemSnapshot._(JSObject _) implements JSObject {
  /// The label of this tree item.
  String get label => getStringProp(this, 'label');

  /// The description of this tree item (optional).
  String? get description => getStringPropOrNull(this, 'description');

  /// Child items (optional, for expandable items).
  JSArray<JSTreeItemSnapshot>? get children {
    final value = reflectGet(this, 'children');
    if (value == null || value.isUndefinedOrNull) return null;
    if (value.typeofEquals('object') && value.instanceOfString('Array')) {
      return value as JSArray<JSTreeItemSnapshot>;
    }
    return null;
  }

  /// Check if this item has a child with label containing text.
  bool hasChildWithLabel(String text) {
    final c = children;
    if (c == null) return false;
    for (var i = 0; i < c.length; i++) {
      if (c[i].label.contains(text)) return true;
    }
    return false;
  }

  /// Find a child item by label content.
  JSTreeItemSnapshot? findChildByLabel(String text) {
    final c = children;
    if (c == null) return null;
    for (var i = 0; i < c.length; i++) {
      if (c[i].label.contains(text)) return c[i];
    }
    return null;
  }

  /// Count children matching a predicate.
  int countChildrenMatching(bool Function(JSTreeItemSnapshot) predicate) {
    final c = children;
    if (c == null) return 0;
    var count = 0;
    for (var i = 0; i < c.length; i++) {
      if (predicate(c[i])) count++;
    }
    return count;
  }
}

/// Agent identity (public info only - no key).
/// Matches TypeScript `AgentIdentity` interface.
/// Note: This is a JS interop type wrapping raw JSObject from TestAPI.
extension type JSAgentIdentity._(JSObject _) implements JSObject {
  /// The agent's unique name.
  String get agentName => getStringProp(this, 'agentName');

  /// Timestamp when the agent was registered (ms since epoch).
  int get registeredAt => getIntProp(this, 'registeredAt');

  /// Timestamp of the agent's last activity (ms since epoch).
  int get lastActive => getIntProp(this, 'lastActive');
}

/// File lock info.
/// Matches TypeScript `FileLock` interface.
/// Note: This is a JS interop type wrapping raw JSObject from TestAPI.
extension type JSFileLock._(JSObject _) implements JSObject {
  /// The locked file path.
  String get filePath => getStringProp(this, 'filePath');

  /// The name of the agent holding the lock.
  String get agentName => getStringProp(this, 'agentName');

  /// Timestamp when the lock was acquired (ms since epoch).
  int get acquiredAt => getIntProp(this, 'acquiredAt');

  /// Timestamp when the lock expires (ms since epoch).
  int get expiresAt => getIntProp(this, 'expiresAt');

  /// Optional reason for acquiring the lock.
  String? get reason => getStringPropOrNull(this, 'reason');

  /// Lock version for optimistic concurrency.
  int get version => getIntProp(this, 'version');

  /// Whether the lock is currently active (not expired).
  bool get isActive => expiresAt > dateNow();
}

/// Inter-agent message.
/// Matches TypeScript `Message` interface.
/// Note: This is a JS interop type wrapping raw JSObject from TestAPI.
extension type JSMessage._(JSObject _) implements JSObject {
  /// Unique message ID.
  String get id => getStringProp(this, 'id');

  /// Name of the sending agent.
  String get fromAgent => getStringProp(this, 'fromAgent');

  /// Name of the receiving agent (or '*' for broadcast).
  String get toAgent => getStringProp(this, 'toAgent');

  /// Message content.
  String get content => getStringProp(this, 'content');

  /// Timestamp when the message was created (ms since epoch).
  int get createdAt => getIntProp(this, 'createdAt');

  /// Timestamp when the message was read (ms since epoch), or null if unread.
  int? get readAt {
    final value = reflectGet(this, 'readAt');
    if (value == null || value.isUndefinedOrNull) return null;
    if (value.typeofEquals('number')) return (value as JSNumber).toDartInt;
    return null;
  }

  /// Whether the message has been read.
  bool get isRead => readAt != null;

  /// Whether this is a broadcast message.
  bool get isBroadcast => toAgent == '*';
}

/// Agent plan.
/// Matches TypeScript `AgentPlan` interface.
/// Note: This is a JS interop type wrapping raw JSObject from TestAPI.
extension type JSAgentPlan._(JSObject _) implements JSObject {
  /// Name of the agent with this plan.
  String get agentName => getStringProp(this, 'agentName');

  /// The agent's goal.
  String get goal => getStringProp(this, 'goal');

  /// The agent's current task.
  String get currentTask => getStringProp(this, 'currentTask');

  /// Timestamp when the plan was last updated (ms since epoch).
  int get updatedAt => getIntProp(this, 'updatedAt');
}

/// Agent details (agent + their locks, messages, plan).
/// Matches TypeScript `AgentDetails` interface.
/// Note: This is a JS interop type wrapping raw JSObject from TestAPI.
extension type JSAgentDetails._(JSObject _) implements JSObject {
  /// The agent identity.
  JSAgentIdentity get agent {
    final value = reflectGet(this, 'agent');
    return JSAgentIdentity._(value! as JSObject);
  }

  /// Locks held by this agent.
  JSArray<JSFileLock> get locks {
    final value = reflectGet(this, 'locks');
    return value! as JSArray<JSFileLock>;
  }

  /// Messages involving this agent.
  JSArray<JSMessage> get messages {
    final value = reflectGet(this, 'messages');
    return value! as JSArray<JSMessage>;
  }

  /// The agent's plan (if any).
  JSAgentPlan? get plan {
    final value = reflectGet(this, 'plan');
    if (value == null || value.isUndefinedOrNull) return null;
    return JSAgentPlan._(value as JSObject);
  }
}
