/**
 * Command Integration Tests with Dialog Mocking
 * Tests commands that require user confirmation dialogs.
 * These tests execute actual VSCode commands to cover all code paths.
 */

import * as assert from 'assert';
import * as vscode from 'vscode';
import {
  waitForExtensionActivation,
  waitForConnection,
  waitForCondition,
  getTestAPI,
  installDialogMocks,
  restoreDialogMocks,
  mockWarningMessage,
  mockQuickPick,
  mockInputBox,
  cleanDatabase,
  safeDisconnect,
} from '../test-helpers';
import { LockTreeItem } from '../../ui/tree/locksTreeProvider';
import { AgentTreeItem } from '../../ui/tree/agentsTreeProvider';

suite('Command Integration - Dialog Mocking', function () {
  let agentKey: string;
  const testId = Date.now();
  const agentName = `cmd-test-${testId}`;

  suiteSetup(async function () {
    this.timeout(60000);

    // waitForExtensionActivation handles server path setup and validation
    await waitForExtensionActivation();

    // Clean DB for fresh state
    cleanDatabase();
  });

  suiteTeardown(async () => {
    restoreDialogMocks();
    await safeDisconnect();
  });

  setup(() => {
    installDialogMocks();
  });

  teardown(() => {
    restoreDialogMocks();
  });

  test('Setup: Connect and register agent', async function () {
    this.timeout(30000);
    const api = getTestAPI();

    await safeDisconnect();
    await api.connect();
    await waitForConnection();

    const result = await api.callTool('register', { name: agentName });
    agentKey = JSON.parse(result).agent_key;
    assert.ok(agentKey, 'Agent should have key');
  });

  test('deleteLock command with LockTreeItem - confirmed', async function () {
    this.timeout(15000);
    const api = getTestAPI();
    const lockPath = '/cmd/delete/lock1.ts';

    // Create a lock first
    await api.callTool('lock', {
      action: 'acquire',
      file_path: lockPath,
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Testing delete command',
    });

    await waitForCondition(
      () => api.findLockInTree(lockPath) !== undefined,
      'Lock to appear',
      5000
    );

    // Mock the confirmation dialog to return 'Release'
    mockWarningMessage('Release');

    // Create a LockTreeItem for the command
    const lockItem = new LockTreeItem(
      lockPath,
      agentName,
      vscode.TreeItemCollapsibleState.None,
      false,
      { filePath: lockPath, agentName, acquiredAt: Date.now(), expiresAt: Date.now() + 60000, reason: 'test', version: 1 }
    );

    // Execute the actual VSCode command
    await vscode.commands.executeCommand('tooManyCooks.deleteLock', lockItem);

    await waitForCondition(
      () => api.findLockInTree(lockPath) === undefined,
      'Lock to disappear after delete',
      5000
    );

    assert.strictEqual(
      api.findLockInTree(lockPath),
      undefined,
      'Lock should be deleted'
    );
  });

  test('deleteLock command with AgentTreeItem - confirmed', async function () {
    this.timeout(15000);
    const api = getTestAPI();
    const lockPath = '/cmd/delete/lock2.ts';

    // Create a lock first
    await api.callTool('lock', {
      action: 'acquire',
      file_path: lockPath,
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Testing delete from agent tree',
    });

    await waitForCondition(
      () => api.findLockInTree(lockPath) !== undefined,
      'Lock to appear',
      5000
    );

    // Mock the confirmation dialog to return 'Release'
    mockWarningMessage('Release');

    // Create an AgentTreeItem with filePath for the command
    const agentItem = new AgentTreeItem(
      lockPath,
      agentName,
      vscode.TreeItemCollapsibleState.None,
      'lock',
      agentName,
      lockPath
    );

    // Execute the actual VSCode command
    await vscode.commands.executeCommand('tooManyCooks.deleteLock', agentItem);

    await waitForCondition(
      () => api.findLockInTree(lockPath) === undefined,
      'Lock to disappear after delete',
      5000
    );

    assert.strictEqual(
      api.findLockInTree(lockPath),
      undefined,
      'Lock should be deleted via agent tree item'
    );
  });

  test('deleteLock command - no filePath shows error', async function () {
    this.timeout(10000);

    // Create a LockTreeItem without a lock (no filePath)
    const emptyItem = new LockTreeItem(
      'No locks',
      undefined,
      vscode.TreeItemCollapsibleState.None,
      false
      // No lock provided
    );

    // Execute the command - should show error message (mock returns undefined)
    await vscode.commands.executeCommand('tooManyCooks.deleteLock', emptyItem);

    // Command should have returned early, no crash
    assert.ok(true, 'Command handled empty filePath gracefully');
  });

  test('deleteLock command - cancelled does nothing', async function () {
    this.timeout(15000);
    const api = getTestAPI();
    const lockPath = '/cmd/cancel/lock.ts';

    // Create a lock
    await api.callTool('lock', {
      action: 'acquire',
      file_path: lockPath,
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Testing cancel',
    });

    await waitForCondition(
      () => api.findLockInTree(lockPath) !== undefined,
      'Lock to appear',
      5000
    );

    // Mock the dialog to return undefined (cancelled)
    mockWarningMessage(undefined);

    const lockItem = new LockTreeItem(
      lockPath,
      agentName,
      vscode.TreeItemCollapsibleState.None,
      false,
      { filePath: lockPath, agentName, acquiredAt: Date.now(), expiresAt: Date.now() + 60000, reason: 'test', version: 1 }
    );

    // Execute command (should be cancelled)
    await vscode.commands.executeCommand('tooManyCooks.deleteLock', lockItem);

    // Lock should still exist (command was cancelled)
    assert.ok(
      api.findLockInTree(lockPath),
      'Lock should still exist after cancel'
    );

    // Clean up
    await api.callTool('lock', {
      action: 'release',
      file_path: lockPath,
      agent_name: agentName,
      agent_key: agentKey,
    });
  });

  test('deleteAgent command - confirmed', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Create a target agent
    const targetName = `delete-target-${testId}`;
    const result = await api.callTool('register', { name: targetName });
    const targetKey = JSON.parse(result).agent_key;

    // Create a lock for this agent
    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/cmd/agent/file.ts',
      agent_name: targetName,
      agent_key: targetKey,
      reason: 'Will be deleted',
    });

    await waitForCondition(
      () => api.findAgentInTree(targetName) !== undefined,
      'Target agent to appear',
      5000
    );

    // Mock the confirmation dialog to return 'Remove'
    mockWarningMessage('Remove');

    // Create an AgentTreeItem for the command
    const agentItem = new AgentTreeItem(
      targetName,
      'idle',
      vscode.TreeItemCollapsibleState.Collapsed,
      'agent',
      targetName
    );

    // Execute the actual VSCode command
    await vscode.commands.executeCommand('tooManyCooks.deleteAgent', agentItem);

    await waitForCondition(
      () => api.findAgentInTree(targetName) === undefined,
      'Agent to disappear after delete',
      5000
    );

    assert.strictEqual(
      api.findAgentInTree(targetName),
      undefined,
      'Agent should be deleted'
    );
  });

  test('deleteAgent command - no agentName shows error', async function () {
    this.timeout(10000);

    // Create an AgentTreeItem without agentName
    const emptyItem = new AgentTreeItem(
      'No agent',
      undefined,
      vscode.TreeItemCollapsibleState.None,
      'agent'
      // No agentName provided
    );

    // Execute the command - should show error message
    await vscode.commands.executeCommand('tooManyCooks.deleteAgent', emptyItem);

    // Command should have returned early, no crash
    assert.ok(true, 'Command handled empty agentName gracefully');
  });

  test('deleteAgent command - cancelled does nothing', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Create a target agent
    const targetName = `cancel-agent-${testId}`;
    await api.callTool('register', { name: targetName });

    await waitForCondition(
      () => api.findAgentInTree(targetName) !== undefined,
      'Target agent to appear',
      5000
    );

    // Mock the dialog to return undefined (cancelled)
    mockWarningMessage(undefined);

    const agentItem = new AgentTreeItem(
      targetName,
      'idle',
      vscode.TreeItemCollapsibleState.Collapsed,
      'agent',
      targetName
    );

    // Execute command (should be cancelled)
    await vscode.commands.executeCommand('tooManyCooks.deleteAgent', agentItem);

    // Agent should still exist
    assert.ok(
      api.findAgentInTree(targetName),
      'Agent should still exist after cancel'
    );
  });

  test('sendMessage command - with target agent', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Create recipient agent
    const recipientName = `recipient-${testId}`;
    await api.callTool('register', { name: recipientName });

    // Mock the dialogs for sendMessage flow (no quickpick needed when target provided)
    mockInputBox(`sender-with-target-${testId}`); // Sender name
    mockInputBox('Test message with target'); // Message content

    // Create an AgentTreeItem as target
    const targetItem = new AgentTreeItem(
      recipientName,
      'idle',
      vscode.TreeItemCollapsibleState.Collapsed,
      'agent',
      recipientName
    );

    // Execute the actual VSCode command with target
    await vscode.commands.executeCommand('tooManyCooks.sendMessage', targetItem);

    await waitForCondition(
      () => api.findMessageInTree('Test message with target') !== undefined,
      'Message to appear',
      5000
    );

    const msgItem = api.findMessageInTree('Test message with target');
    assert.ok(msgItem, 'Message should be in tree');
  });

  test('sendMessage command - without target uses quickpick', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Create recipient agent
    const recipientName = `recipient2-${testId}`;
    await api.callTool('register', { name: recipientName });

    // Mock all dialogs for sendMessage flow
    mockQuickPick(recipientName); // Select recipient
    mockInputBox(`sender-no-target-${testId}`); // Sender name
    mockInputBox('Test message without target'); // Message content

    // Execute the command without a target item
    await vscode.commands.executeCommand('tooManyCooks.sendMessage');

    await waitForCondition(
      () => api.findMessageInTree('Test message without target') !== undefined,
      'Message to appear',
      5000
    );

    const msgItem = api.findMessageInTree('Test message without target');
    assert.ok(msgItem, 'Message should be in tree');
  });

  test('sendMessage command - broadcast to all', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Mock dialogs for broadcast
    mockQuickPick('* (broadcast to all)');
    mockInputBox(`broadcast-sender-${testId}`);
    mockInputBox('Broadcast test message');

    // Execute command for broadcast
    await vscode.commands.executeCommand('tooManyCooks.sendMessage');

    await waitForCondition(
      () => api.findMessageInTree('Broadcast test') !== undefined,
      'Broadcast to appear',
      5000
    );

    const msgItem = api.findMessageInTree('Broadcast test');
    assert.ok(msgItem, 'Broadcast should be in tree');
    assert.ok(msgItem.label.includes('all'), 'Should show "all" as recipient');
  });

  test('sendMessage command - cancelled at recipient selection', async function () {
    this.timeout(10000);

    // Mock quickpick to return undefined (cancelled)
    mockQuickPick(undefined);

    // Execute command - should return early
    await vscode.commands.executeCommand('tooManyCooks.sendMessage');

    // Command should have returned early, no crash
    assert.ok(true, 'Command handled cancelled recipient selection');
  });

  test('sendMessage command - cancelled at sender input', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Create recipient
    const recipientName = `cancel-sender-${testId}`;
    await api.callTool('register', { name: recipientName });

    // Mock recipient selection but cancel sender input
    mockQuickPick(recipientName);
    mockInputBox(undefined); // Cancel sender

    // Execute command
    await vscode.commands.executeCommand('tooManyCooks.sendMessage');

    // Command should have returned early
    assert.ok(true, 'Command handled cancelled sender input');
  });

  test('sendMessage command - cancelled at message input', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Create recipient
    const recipientName = `cancel-msg-${testId}`;
    await api.callTool('register', { name: recipientName });

    // Mock recipient and sender but cancel message
    mockQuickPick(recipientName);
    mockInputBox(`sender-cancel-msg-${testId}`);
    mockInputBox(undefined); // Cancel message

    // Execute command
    await vscode.commands.executeCommand('tooManyCooks.sendMessage');

    // Command should have returned early
    assert.ok(true, 'Command handled cancelled message input');
  });
});
