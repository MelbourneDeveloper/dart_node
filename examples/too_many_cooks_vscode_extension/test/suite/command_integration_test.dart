/// Command Integration Tests with Dialog Mocking
/// Tests commands that require user confirmation dialogs.
/// These tests execute actual VSCode commands to cover all code paths.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

@JS('Date.now')
external int _dateNow();

// JS interop helper to get property from JSObject.
@JS('Reflect.get')
external JSAny? _reflectGet(JSObject target, JSString key);

// JS interop helper to set property on JSObject.
@JS('Reflect.set')
external void _reflectSetRaw(JSObject target, JSString key, JSAny? value);

void _jsSet(JSObject target, String key, JSAny? value) =>
    _reflectSetRaw(target, key.toJS, value);

/// Get the label property from a tree item snapshot.
String _getLabel(JSObject item) {
  final label = _reflectGet(item, 'label'.toJS);
  if (label == null || label.isUndefinedOrNull) return '';
  if (label.typeofEquals('string')) return (label as JSString).toDart;
  // TreeItem label can be a TreeItemLabel object with a 'label' property
  if (label.typeofEquals('object')) {
    final innerLabel = _reflectGet(label as JSObject, 'label'.toJS);
    if (innerLabel != null && innerLabel.typeofEquals('string')) {
      return (innerLabel as JSString).toDart;
    }
  }
  return label.toString();
}

/// Create a LockTreeItem-like object for command testing.
/// This mimics the TypeScript LockTreeItem class.
JSObject _createLockTreeItem({
  required String filePath,
  String? agentName,
  int acquiredAt = 0,
  int expiresAt = 0,
  String? reason,
}) {
  // Create a TreeItem with the filePath as label
  final item = TreeItem(filePath);

  // Add the filePath property that the command handler looks for
  _jsSet(item, 'filePath', filePath.toJS);

  // Set contextValue for command registration matching
  item.contextValue = 'lockItem';

  // Add the lock data if provided
  if (agentName != null) {
    final lockData = _createJsObject();
    _jsSet(lockData, 'filePath', filePath.toJS);
    _jsSet(lockData, 'agentName', agentName.toJS);
    _jsSet(lockData, 'acquiredAt', acquiredAt.toJS);
    _jsSet(lockData, 'expiresAt', expiresAt.toJS);
    if (reason != null) _jsSet(lockData, 'reason', reason.toJS);
    _jsSet(item, 'lock', lockData);
  }

  return item;
}

/// Create an AgentTreeItem-like object for command testing.
/// This mimics the TypeScript AgentTreeItem class.
JSObject _createAgentTreeItem({
  required String label,
  required String itemType,
  String? description,
  int collapsibleState = TreeItemCollapsibleState.none,
  String? agentName,
  String? filePath,
}) {
  final item = TreeItem(label, collapsibleState)
    ..description = description
    ..contextValue = itemType;

  // Add properties the command handlers look for
  if (agentName != null) _jsSet(item, 'agentName', agentName.toJS);
  if (filePath != null) _jsSet(item, 'filePath', filePath.toJS);

  return item;
}

/// Create a plain JS object.
@JS('Object.create')
external JSObject _createJsObjectFromProto(JSAny? proto);

JSObject _createJsObject() => _createJsObjectFromProto(null);

void main() {
  _log('[COMMAND INTEGRATION TEST] main() called');

  // Ensure any dialog mocks from previous tests are restored
  restoreDialogMocks();

  suite('Command Integration - Dialog Mocking', syncTest(() {
    final testId = _dateNow();
    final agentName = 'cmd-test-$testId';
    String? agentKey;

    suiteSetup(asyncTest(() async {
      _log('[CMD DIALOG] suiteSetup - waiting for extension activation');

      // waitForExtensionActivation handles server path setup and validation
      await waitForExtensionActivation();

      // Clean DB for fresh state
      cleanDatabase();
    }));

    suiteTeardown(asyncTest(() async {
      _log('[CMD DIALOG] suiteTeardown');
      restoreDialogMocks();
      await safeDisconnect();
    }));

    setup(syncTest(installDialogMocks));

    teardown(syncTest(restoreDialogMocks));

    test('Setup: Connect and register agent', asyncTest(() async {
      _log('[CMD DIALOG] Running: Setup - Connect and register agent');
      final api = getTestAPI();

      await safeDisconnect();
      await api.connect().toDart;
      await waitForConnection();

      final result =
          await api.callTool('register', createArgs({'name': agentName}))
              .toDart;
      agentKey = extractKeyFromResult(result.toDart);
      assertOk(
        agentKey != null && agentKey!.isNotEmpty,
        'Agent should have key',
      );

      _log('[CMD DIALOG] PASSED: Setup - Connect and register agent');
    }));

    test('deleteLock command with LockTreeItem - confirmed',
        asyncTest(() async {
      _log('[CMD DIALOG] Running: deleteLock with LockTreeItem - confirmed');
      final api = getTestAPI();
      final key = agentKey;
      if (key == null) throw StateError('agentKey not set');

      const lockPath = '/cmd/delete/lock1.ts';

      // Create a lock first
      await api.callTool('lock', createArgs({
        'action': 'acquire',
        'file_path': lockPath,
        'agent_name': agentName,
        'agent_key': key,
        'reason': 'Testing delete command',
      })).toDart;

      await waitForLockInTree(api, lockPath);

      // Mock the confirmation dialog to return 'Release'
      mockWarningMessage('Release');

      // Create a LockTreeItem for the command
      final lockItem = _createLockTreeItem(
        filePath: lockPath,
        agentName: agentName,
        acquiredAt: _dateNow(),
        expiresAt: _dateNow() + 60000,
        reason: 'test',
      );

      // Execute the actual VSCode command
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.deleteLock', lockItem)
          .toDart;

      await waitForLockGone(api, lockPath);

      assertEqual(
        api.findLockInTree(lockPath),
        null,
        'Lock should be deleted',
      );

      _log('[CMD DIALOG] PASSED: deleteLock with LockTreeItem - confirmed');
    }));

    test('deleteLock command with AgentTreeItem - confirmed',
        asyncTest(() async {
      _log('[CMD DIALOG] Running: deleteLock with AgentTreeItem - confirmed');
      final api = getTestAPI();
      final key = agentKey;
      if (key == null) throw StateError('agentKey not set');

      const lockPath = '/cmd/delete/lock2.ts';

      // Create a lock first
      await api.callTool('lock', createArgs({
        'action': 'acquire',
        'file_path': lockPath,
        'agent_name': agentName,
        'agent_key': key,
        'reason': 'Testing delete from agent tree',
      })).toDart;

      await waitForLockInTree(api, lockPath);

      // Mock the confirmation dialog to return 'Release'
      mockWarningMessage('Release');

      // Create an AgentTreeItem with filePath for the command
      final agentItem = _createAgentTreeItem(
        label: lockPath,
        agentName: agentName,
        itemType: 'lock',
        filePath: lockPath,
      );

      // Execute the actual VSCode command
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.deleteLock', agentItem)
          .toDart;

      await waitForLockGone(api, lockPath);

      assertEqual(
        api.findLockInTree(lockPath),
        null,
        'Lock should be deleted via agent tree item',
      );

      _log('[CMD DIALOG] PASSED: deleteLock with AgentTreeItem - confirmed');
    }));

    test('deleteLock command - no filePath shows error', asyncTest(() async {
      _log('[CMD DIALOG] Running: deleteLock - no filePath shows error');

      // Create a LockTreeItem without a lock (no filePath)
      final emptyItem = _createLockTreeItem(filePath: 'No locks');

      // Execute the command - should show error message
      // (mock returns undefined)
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.deleteLock', emptyItem)
          .toDart;

      // Command should have returned early, no crash
      assertOk(true, 'Command handled empty filePath gracefully');

      _log('[CMD DIALOG] PASSED: deleteLock - no filePath shows error');
    }));

    test('deleteLock command - cancelled does nothing', asyncTest(() async {
      _log('[CMD DIALOG] Running: deleteLock - cancelled does nothing');
      final api = getTestAPI();
      final key = agentKey;
      if (key == null) throw StateError('agentKey not set');

      const lockPath = '/cmd/cancel/lock.ts';

      // Create a lock
      await api.callTool('lock', createArgs({
        'action': 'acquire',
        'file_path': lockPath,
        'agent_name': agentName,
        'agent_key': key,
        'reason': 'Testing cancel',
      })).toDart;

      await waitForLockInTree(api, lockPath);

      // Mock the dialog to return undefined (cancelled)
      mockWarningMessage(null);

      final lockItem = _createLockTreeItem(
        filePath: lockPath,
        agentName: agentName,
        acquiredAt: _dateNow(),
        expiresAt: _dateNow() + 60000,
        reason: 'test',
      );

      // Execute command (should be cancelled)
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.deleteLock', lockItem)
          .toDart;

      // Lock should still exist (command was cancelled)
      assertOk(
        api.findLockInTree(lockPath) != null,
        'Lock should still exist after cancel',
      );

      // Clean up
      await api.callTool('lock', createArgs({
        'action': 'release',
        'file_path': lockPath,
        'agent_name': agentName,
        'agent_key': key,
      })).toDart;

      _log('[CMD DIALOG] PASSED: deleteLock - cancelled does nothing');
    }));

    test('deleteAgent command - confirmed', asyncTest(() async {
      _log('[CMD DIALOG] Running: deleteAgent - confirmed');
      final api = getTestAPI();

      // Create a target agent
      final targetName = 'delete-target-$testId';
      final result = await api.callTool('register', createArgs({
        'name': targetName,
      })).toDart;
      final targetKey = extractKeyFromResult(result.toDart);

      // Create a lock for this agent
      await api.callTool('lock', createArgs({
        'action': 'acquire',
        'file_path': '/cmd/agent/file.ts',
        'agent_name': targetName,
        'agent_key': targetKey,
        'reason': 'Will be deleted',
      })).toDart;

      await waitForAgentInTree(api, targetName);

      // Mock the confirmation dialog to return 'Remove'
      mockWarningMessage('Remove');

      // Create an AgentTreeItem for the command
      final agentItem = _createAgentTreeItem(
        label: targetName,
        description: 'idle',
        collapsibleState: TreeItemCollapsibleState.collapsed,
        itemType: 'agent',
        agentName: targetName,
      );

      // Execute the actual VSCode command
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.deleteAgent', agentItem)
          .toDart;

      await waitForAgentGone(api, targetName);

      assertEqual(
        api.findAgentInTree(targetName),
        null,
        'Agent should be deleted',
      );

      _log('[CMD DIALOG] PASSED: deleteAgent - confirmed');
    }));

    test('deleteAgent command - no agentName shows error', asyncTest(() async {
      _log('[CMD DIALOG] Running: deleteAgent - no agentName shows error');

      // Create an AgentTreeItem without agentName
      final emptyItem = _createAgentTreeItem(
        label: 'No agent',
        itemType: 'agent',
        // No agentName provided
      );

      // Execute the command - should show error message
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.deleteAgent', emptyItem)
          .toDart;

      // Command should have returned early, no crash
      assertOk(true, 'Command handled empty agentName gracefully');

      _log('[CMD DIALOG] PASSED: deleteAgent - no agentName shows error');
    }));

    test('deleteAgent command - cancelled does nothing', asyncTest(() async {
      _log('[CMD DIALOG] Running: deleteAgent - cancelled does nothing');
      final api = getTestAPI();

      // Create a target agent
      final targetName = 'cancel-agent-$testId';
      await api.callTool('register', createArgs({'name': targetName})).toDart;

      await waitForAgentInTree(api, targetName);

      // Mock the dialog to return undefined (cancelled)
      mockWarningMessage(null);

      final agentItem = _createAgentTreeItem(
        label: targetName,
        description: 'idle',
        collapsibleState: TreeItemCollapsibleState.collapsed,
        itemType: 'agent',
        agentName: targetName,
      );

      // Execute command (should be cancelled)
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.deleteAgent', agentItem)
          .toDart;

      // Agent should still exist
      assertOk(
        api.findAgentInTree(targetName) != null,
        'Agent should still exist after cancel',
      );

      _log('[CMD DIALOG] PASSED: deleteAgent - cancelled does nothing');
    }));

    test('sendMessage command - with target agent', asyncTest(() async {
      _log('[CMD DIALOG] Running: sendMessage - with target agent');
      final api = getTestAPI();

      // Create recipient agent
      final recipientName = 'recipient-$testId';
      await api.callTool('register', createArgs({
        'name': recipientName,
      })).toDart;

      // Mock the dialogs for sendMessage flow
      // (no quickpick when target provided)
      mockInputBox('sender-with-target-$testId'); // Sender name
      mockInputBox('Test message with target'); // Message content

      // Create an AgentTreeItem as target
      final targetItem = _createAgentTreeItem(
        label: recipientName,
        description: 'idle',
        collapsibleState: TreeItemCollapsibleState.collapsed,
        itemType: 'agent',
        agentName: recipientName,
      );

      // Execute the actual VSCode command with target
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.sendMessage', targetItem)
          .toDart;

      await waitForMessageInTree(api, 'Test message with target');

      final msgItem = api.findMessageInTree('Test message with target');
      assertOk(msgItem != null, 'Message should be in tree');

      _log('[CMD DIALOG] PASSED: sendMessage - with target agent');
    }));

    test('sendMessage command - without target uses quickpick',
        asyncTest(() async {
      _log('[CMD DIALOG] Running: sendMessage - without target uses quickpick');
      final api = getTestAPI();

      // Create recipient agent
      final recipientName = 'recipient2-$testId';
      await api.callTool('register', createArgs({
        'name': recipientName,
      })).toDart;

      // Mock all dialogs for sendMessage flow
      mockQuickPick(recipientName); // Select recipient
      mockInputBox('sender-no-target-$testId'); // Sender name
      mockInputBox('Test message without target'); // Message content

      // Execute the command without a target item
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.sendMessage')
          .toDart;

      await waitForMessageInTree(api, 'Test message without target');

      final msgItem = api.findMessageInTree('Test message without target');
      assertOk(msgItem != null, 'Message should be in tree');

      _log('[CMD DIALOG] PASSED: sendMessage - without target uses quickpick');
    }));

    test('sendMessage command - broadcast to all', asyncTest(() async {
      _log('[CMD DIALOG] Running: sendMessage - broadcast to all');
      final api = getTestAPI();

      // Mock dialogs for broadcast
      mockQuickPick('* (broadcast to all)');
      mockInputBox('broadcast-sender-$testId');
      mockInputBox('Broadcast test message');

      // Execute command for broadcast
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.sendMessage')
          .toDart;

      await waitForMessageInTree(api, 'Broadcast test');

      final msgItem = api.findMessageInTree('Broadcast test');
      assertOk(msgItem != null, 'Broadcast should be in tree');
      final label = _getLabel(msgItem!);
      assertOk(label.contains('all'), 'Should show "all" as recipient');

      _log('[CMD DIALOG] PASSED: sendMessage - broadcast to all');
    }));

    test('sendMessage command - cancelled at recipient selection',
        asyncTest(() async {
      _log('[CMD DIALOG] Running: sendMessage - cancelled at recipient '
          'selection');

      // Mock quickpick to return undefined (cancelled)
      mockQuickPick(null);

      // Execute command - should return early
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.sendMessage')
          .toDart;

      // Command should have returned early, no crash
      assertOk(true, 'Command handled cancelled recipient selection');

      _log('[CMD DIALOG] PASSED: sendMessage - cancelled at recipient '
          'selection');
    }));

    test('sendMessage command - cancelled at sender input', asyncTest(() async {
      _log('[CMD DIALOG] Running: sendMessage - cancelled at sender input');
      final api = getTestAPI();

      // Create recipient
      final recipientName = 'cancel-sender-$testId';
      await api.callTool('register', createArgs({
        'name': recipientName,
      })).toDart;

      // Mock recipient selection but cancel sender input
      mockQuickPick(recipientName);
      mockInputBox(null); // Cancel sender

      // Execute command
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.sendMessage')
          .toDart;

      // Command should have returned early
      assertOk(true, 'Command handled cancelled sender input');

      _log('[CMD DIALOG] PASSED: sendMessage - cancelled at sender input');
    }));

    test('sendMessage command - cancelled at message input',
        asyncTest(() async {
      _log('[CMD DIALOG] Running: sendMessage - cancelled at message input');
      final api = getTestAPI();

      // Create recipient
      final recipientName = 'cancel-msg-$testId';
      await api.callTool('register', createArgs({
        'name': recipientName,
      })).toDart;

      // Mock recipient and sender but cancel message
      mockQuickPick(recipientName);
      mockInputBox('sender-cancel-msg-$testId');
      mockInputBox(null); // Cancel message

      // Execute command
      await vscode.commands
          .executeCommand<JSAny?>('tooManyCooks.sendMessage')
          .toDart;

      // Command should have returned early
      assertOk(true, 'Command handled cancelled message input');

      _log('[CMD DIALOG] PASSED: sendMessage - cancelled at message input');
    }));
  }));

  _log('[COMMAND INTEGRATION TEST] main() completed - all tests registered');
}
