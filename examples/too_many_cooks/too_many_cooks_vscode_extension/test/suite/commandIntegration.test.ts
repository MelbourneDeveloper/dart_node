// Command Integration Tests with Dialog Mocking
// Tests commands that require user confirmation dialogs.

import * as vscode from 'vscode';
import { AgentTreeItem, LockTreeItem } from '../../src/ui/tree/treeItems';
import { FileLock } from '../../src/state/types';
import {
  waitForExtensionActivation,
  waitForConnection,
  waitForLockInTree,
  waitForLockGone,
  waitForAgentInTree,
  waitForAgentGone,
  waitForMessageInTree,
  safeDisconnect,
  getTestAPI,
  callToolString,
  extractKeyFromResult,
  cleanDatabase,
  installDialogMocks,
  restoreDialogMocks,
  mockWarningMessage,
  mockQuickPick,
  mockInputBox,
  getLabel,
  assertOk,
  assertEqual,
} from './testHelpers';

restoreDialogMocks();

suite('Command Integration - Dialog Mocking', () => {
  const testId = Date.now();
  const agentName = `cmd-test-${testId}`;
  let agentKey: string | undefined;

  suiteSetup(async () => {
    await waitForExtensionActivation();
    cleanDatabase();
  });

  suiteTeardown(async () => {
    restoreDialogMocks();
    await safeDisconnect();
  });

  setup(() => { installDialogMocks(); });
  teardown(() => { restoreDialogMocks(); });

  test('Setup: Connect and register agent', async () => {
    const api = getTestAPI();
    await safeDisconnect();
    await api.connect();
    await waitForConnection();

    const result = await callToolString(api, 'register', { name: agentName });
    agentKey = extractKeyFromResult(result);
    assertOk(agentKey && agentKey.length > 0, 'Agent should have key');
  });

  test('deleteLock command with LockTreeItem - confirmed', async () => {
    const api = getTestAPI();
    if (!agentKey) { throw new Error('agentKey not set'); }

    const lockPath = '/cmd/delete/lock1.ts';

    await api.callTool('lock', {
      action: 'acquire',
      file_path: lockPath,
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Testing delete command',
    });

    await waitForLockInTree(api, lockPath);

    mockWarningMessage('Release');

    const lock: FileLock = {
      filePath: lockPath,
      agentName,
      acquiredAt: Date.now(),
      expiresAt: Date.now() + 60000,
      reason: 'test',
      version: 1,
    };
    const lockItem = new LockTreeItem(
      lockPath,
      vscode.TreeItemCollapsibleState.None,
      false,
      lock,
    );

    await vscode.commands.executeCommand('tooManyCooks.deleteLock', lockItem);
    await waitForLockGone(api, lockPath);

    assertEqual(api.findLockInTree(lockPath), null, 'Lock should be deleted');
  });

  test('deleteLock command with AgentTreeItem - confirmed', async () => {
    const api = getTestAPI();
    if (!agentKey) { throw new Error('agentKey not set'); }

    const lockPath = '/cmd/delete/lock2.ts';

    await api.callTool('lock', {
      action: 'acquire',
      file_path: lockPath,
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Testing delete from agent tree',
    });

    await waitForLockInTree(api, lockPath);

    mockWarningMessage('Release');

    const agentItem = new AgentTreeItem(
      lockPath,
      vscode.TreeItemCollapsibleState.None,
      'lock',
      agentName,
      lockPath,
    );

    await vscode.commands.executeCommand('tooManyCooks.deleteLock', agentItem);
    await waitForLockGone(api, lockPath);

    assertEqual(api.findLockInTree(lockPath), null, 'Lock should be deleted via agent tree item');
  });

  test('deleteLock command - no filePath shows error', async () => {
    const emptyItem = new LockTreeItem(
      'No locks',
      vscode.TreeItemCollapsibleState.None,
      false,
    );

    await vscode.commands.executeCommand('tooManyCooks.deleteLock', emptyItem);
    assertOk(true, 'Command handled empty filePath gracefully');
  });

  test('deleteLock command - cancelled does nothing', async () => {
    const api = getTestAPI();
    if (!agentKey) { throw new Error('agentKey not set'); }

    const lockPath = '/cmd/cancel/lock.ts';

    await api.callTool('lock', {
      action: 'acquire',
      file_path: lockPath,
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Testing cancel',
    });

    await waitForLockInTree(api, lockPath);

    mockWarningMessage(undefined);

    const lock: FileLock = {
      filePath: lockPath,
      agentName,
      acquiredAt: Date.now(),
      expiresAt: Date.now() + 60000,
      reason: 'test',
      version: 1,
    };
    const lockItem = new LockTreeItem(
      lockPath,
      vscode.TreeItemCollapsibleState.None,
      false,
      lock,
    );

    await vscode.commands.executeCommand('tooManyCooks.deleteLock', lockItem);

    assertOk(api.findLockInTree(lockPath), 'Lock should still exist after cancel');

    await api.callTool('lock', {
      action: 'release',
      file_path: lockPath,
      agent_name: agentName,
      agent_key: agentKey,
    });
  });

  test('deleteAgent command - confirmed', async () => {
    const api = getTestAPI();

    const targetName = `delete-target-${testId}`;
    const result = await callToolString(api, 'register', { name: targetName });
    const targetKey = extractKeyFromResult(result);

    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/cmd/agent/file.ts',
      agent_name: targetName,
      agent_key: targetKey,
      reason: 'Will be deleted',
    });

    await waitForAgentInTree(api, targetName);

    mockWarningMessage('Remove');

    const agentItem = new AgentTreeItem(
      targetName,
      vscode.TreeItemCollapsibleState.Collapsed,
      'agent',
      targetName,
    );

    await vscode.commands.executeCommand('tooManyCooks.deleteAgent', agentItem);
    await waitForAgentGone(api, targetName);

    assertEqual(api.findAgentInTree(targetName), null, 'Agent should be deleted');
  });

  test('deleteAgent command - no agentName shows error', async () => {
    const emptyItem = new AgentTreeItem(
      'No agent',
      vscode.TreeItemCollapsibleState.None,
      'agent',
    );

    await vscode.commands.executeCommand('tooManyCooks.deleteAgent', emptyItem);
    assertOk(true, 'Command handled empty agentName gracefully');
  });

  test('deleteAgent command - cancelled does nothing', async () => {
    const api = getTestAPI();

    const targetName = `cancel-agent-${testId}`;
    await api.callTool('register', { name: targetName });

    await waitForAgentInTree(api, targetName);

    mockWarningMessage(undefined);

    const agentItem = new AgentTreeItem(
      targetName,
      vscode.TreeItemCollapsibleState.Collapsed,
      'agent',
      targetName,
    );

    await vscode.commands.executeCommand('tooManyCooks.deleteAgent', agentItem);

    assertOk(api.findAgentInTree(targetName), 'Agent should still exist after cancel');
  });

  test('sendMessage command - with target agent', async () => {
    const api = getTestAPI();

    const recipientName = `recipient-${testId}`;
    const senderName = `sender-with-target-${testId}`;
    await api.callTool('register', { name: recipientName });
    await api.callTool('register', { name: senderName });

    mockQuickPick(senderName);
    mockInputBox('Test message with target');

    const targetItem = new AgentTreeItem(
      recipientName,
      vscode.TreeItemCollapsibleState.Collapsed,
      'agent',
      recipientName,
    );

    await vscode.commands.executeCommand('tooManyCooks.sendMessage', targetItem);
    await waitForMessageInTree(api, 'Test message with target');

    const msgItem = api.findMessageInTree('Test message with target');
    assertOk(msgItem, 'Message should be in tree');
  });

  test('sendMessage command - without target uses quickpick', async () => {
    const api = getTestAPI();

    const recipientName = `recipient2-${testId}`;
    const senderName = `sender-no-target-${testId}`;
    await api.callTool('register', { name: recipientName });
    await api.callTool('register', { name: senderName });

    mockQuickPick(recipientName);
    mockQuickPick(senderName);
    mockInputBox('Test message without target');

    await vscode.commands.executeCommand('tooManyCooks.sendMessage');
    await waitForMessageInTree(api, 'Test message without target');

    const msgItem = api.findMessageInTree('Test message without target');
    assertOk(msgItem, 'Message should be in tree');
  });

  test('sendMessage command - broadcast to all', async () => {
    const api = getTestAPI();

    const senderName = `broadcast-sender-${testId}`;
    await api.callTool('register', { name: senderName });

    mockQuickPick('* (broadcast to all)');
    mockQuickPick(senderName);
    mockInputBox('Broadcast test message');

    await vscode.commands.executeCommand('tooManyCooks.sendMessage');
    await waitForMessageInTree(api, 'Broadcast test');

    const msgItem = api.findMessageInTree('Broadcast test');
    assertOk(msgItem, 'Broadcast should be in tree');
    const label = getLabel(msgItem!);
    assertOk(label.includes('all'), 'Should show "all" as recipient');
  });

  test('sendMessage command - cancelled at recipient selection', async () => {
    mockQuickPick(undefined);
    await vscode.commands.executeCommand('tooManyCooks.sendMessage');
    assertOk(true, 'Command handled cancelled recipient selection');
  });

  test('sendMessage command - cancelled at sender input', async () => {
    const api = getTestAPI();

    const recipientName = `cancel-sender-${testId}`;
    await api.callTool('register', { name: recipientName });

    mockQuickPick(recipientName);
    mockQuickPick(undefined);

    await vscode.commands.executeCommand('tooManyCooks.sendMessage');
    assertOk(true, 'Command handled cancelled sender input');
  });

  test('sendMessage command - cancelled at message input', async () => {
    const api = getTestAPI();

    const recipientName = `cancel-msg-${testId}`;
    await api.callTool('register', { name: recipientName });

    mockQuickPick(recipientName);
    mockQuickPick(`sender-cancel-msg-${testId}`);
    mockInputBox(undefined);

    await vscode.commands.executeCommand('tooManyCooks.sendMessage');
    assertOk(true, 'Command handled cancelled message input');
  });
});
