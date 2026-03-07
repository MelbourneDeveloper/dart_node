/// Test helpers for integration tests.
///
/// Provides utilities for testing with real database in temp directory.
/// Uses Node.js APIs instead of dart:io (which doesn't work on Node platform).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:too_many_cooks_vscode_extension/state/state.dart';
import 'package:too_many_cooks_vscode_extension/state/store.dart';

export 'package:too_many_cooks_vscode_extension/state/state.dart';
export 'package:too_many_cooks_vscode_extension/state/store.dart'
    show StoreManager;

/// Extract agent key from JSON response.
String extractKey(String jsonResponse) {
  final decoded = jsonDecode(jsonResponse);
  if (decoded case {'agent_key': final String key}) return key;
  throw StateError('No agent_key in response: $jsonResponse');
}

/// Create a StoreManager with a temp workspace for testing.
({StoreManager manager, String workspaceFolder}) createTestStore() {
  final os = requireModule('os') as JSObject;
  final fs = requireModule('fs') as JSObject;
  final tmpdir =
      (os['tmpdir']! as JSFunction).callAsFunction(os)! as JSString;
  final prefix = '${tmpdir.toDart}/tmc_test_';
  final tempDir =
      ((fs['mkdtempSync']! as JSFunction).callAsFunction(fs, prefix.toJS)!
              as JSString)
          .toDart;
  final manager = StoreManager(workspaceFolder: tempDir);
  return (manager: manager, workspaceFolder: tempDir);
}

/// Cleanup a test store and its temp directory.
Future<void> cleanupTestStore(String workspaceFolder) async {
  final fs = requireModule('fs') as JSObject;
  final existsSync = fs['existsSync']! as JSFunction;
  final exists =
      (existsSync.callAsFunction(fs, workspaceFolder.toJS)! as JSBoolean)
          .toDart;
  if (exists) {
    final rmSync = fs['rmSync']! as JSFunction;
    final opts = JSObject();
    opts['recursive'] = true.toJS;
    opts['force'] = true.toJS;
    rmSync.callAsFunction(fs, workspaceFolder.toJS, opts);
  }
}

/// Wait for a condition to be true, polling at regular intervals.
Future<void> waitForCondition(
  bool Function() condition, {
  String? message,
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(milliseconds: 100),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (condition()) return;
    await Future<void>.delayed(interval);
  }
  throw TimeoutException(message ?? 'Condition not met within timeout');
}

/// Wait for connection status to reach a specific state.
Future<void> waitForConnectionStatus(
  StoreManager manager,
  ConnectionStatus status, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  await waitForCondition(
    () => manager.state.connectionStatus == status,
    message:
        'Expected connection status $status, '
        'got ${manager.state.connectionStatus}',
    timeout: timeout,
  );
}

/// Wait for agents list to have at least n agents.
Future<void> waitForAgents(
  StoreManager manager,
  int count, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  await waitForCondition(
    () => manager.state.agents.length >= count,
    message:
        'Expected at least $count agents, '
        'got ${manager.state.agents.length}',
    timeout: timeout,
  );
}

/// Wait for locks list to have at least n locks.
Future<void> waitForLocks(
  StoreManager manager,
  int count, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  await waitForCondition(
    () => manager.state.locks.length >= count,
    message:
        'Expected at least $count locks, '
        'got ${manager.state.locks.length}',
    timeout: timeout,
  );
}

/// Wait for messages list to have at least n messages.
Future<void> waitForMessages(
  StoreManager manager,
  int count, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  await waitForCondition(
    () => manager.state.messages.length >= count,
    message:
        'Expected at least $count messages, '
        'got ${manager.state.messages.length}',
    timeout: timeout,
  );
}
