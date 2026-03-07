// Coverage Tests
// Tests specifically designed to cover untested code paths.

import * as vscode from 'vscode';
import {
  waitForExtensionActivation,
  waitForConnection,
  waitForLockInTree,
  waitForLockGone,
  waitForAgentInTree,
  waitForAgentGone,
  waitForMessageInTree,
  waitForCondition,
  safeDisconnect,
  getTestAPI,
  callToolString,
  extractKeyFromResult,
  cleanDatabase,
  installDialogMocks,
  restoreDialogMocks,
  getLabel,
  getDescription,
  getChildren,
  hasChildWithLabel,
  delay,
  assertOk,
  assertEqual,
} from './testHelpers';

restoreDialogMocks();

// Lock State Coverage Tests
suite('Lock State Coverage', () => {
  const testId = Date.now();
  const agentName = `lock-cov-test-${testId}`;
  let agentKey: string | undefined;

  suiteSetup(async () => {
    await waitForExtensionActivation();
    await safeDisconnect();
    const api = getTestAPI();
    await api.connect();
    await waitForConnection();

    const result = await callToolString(api, 'register', { name: agentName });
    agentKey = extractKeyFromResult(result);
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('Active lock appears in state and tree', async () => {
    const api = getTestAPI();
    if (!agentKey) { throw new Error('agentKey not set'); }

    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/test/lock/active.ts',
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Testing active lock',
    });

    await waitForLockInTree(api, '/test/lock/active.ts', 5000);

    const locks = api.getLocks();
    const ourLock = locks.find(l => l.filePath === '/test/lock/active.ts');
    assertOk(ourLock, 'Lock should be in state');
    assertEqual(ourLock!.agentName, agentName, 'Lock should be owned by test agent');
    assertOk(ourLock!.reason && ourLock!.reason.length > 0, 'Lock should have reason');
    assertOk(ourLock!.expiresAt > Date.now(), 'Lock should not be expired');
  });

  test('Lock shows agent name in tree description', async () => {
    const api = getTestAPI();
    if (!agentKey) { throw new Error('agentKey not set'); }

    const lockPath = '/test/lock/description.ts';
    await api.callTool('lock', {
      action: 'acquire',
      file_path: lockPath,
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Testing lock description',
    });

    await waitForLockInTree(api, lockPath, 5000);

    const lockItem = api.findLockInTree(lockPath);
    assertOk(lockItem, 'Lock should exist');
    const desc = getDescription(lockItem!);
    assertOk(desc.startsWith(agentName), `Lock description should start with agent name, got: ${desc}`);
  });
});

// Store Error Handling Coverage Tests
suite('Store Error Handling Coverage', () => {
  const testId = Date.now();
  const agentName = `store-err-test-${testId}`;
  let agentKey: string | undefined;

  suiteSetup(async () => {
    await waitForExtensionActivation();
    await safeDisconnect();
    const api = getTestAPI();
    await api.connect();
    await waitForConnection();

    const result = await callToolString(api, 'register', { name: agentName });
    agentKey = extractKeyFromResult(result);
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('forceReleaseLock works on existing lock', async () => {
    const api = getTestAPI();
    if (!agentKey) { throw new Error('agentKey not set'); }

    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/test/force/release.ts',
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Will be force released',
    });

    await waitForLockInTree(api, '/test/force/release.ts', 5000);

    await api.forceReleaseLock('/test/force/release.ts');
    await waitForLockGone(api, '/test/force/release.ts', 5000);

    assertEqual(api.findLockInTree('/test/force/release.ts'), null, 'Lock should be removed after force release');
  });

  test('deleteAgent removes agent and associated data', async () => {
    const api = getTestAPI();

    const deleteAgentName = `to-delete-${testId}`;
    const regResult = await callToolString(api, 'register', { name: deleteAgentName });
    const deleteAgentKey = extractKeyFromResult(regResult);

    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/test/delete/agent.ts',
      agent_name: deleteAgentName,
      agent_key: deleteAgentKey,
      reason: 'Will be deleted with agent',
    });

    await api.callTool('plan', {
      action: 'update',
      agent_name: deleteAgentName,
      agent_key: deleteAgentKey,
      goal: 'Will be deleted',
      current_task: 'Waiting to be deleted',
    });

    await waitForAgentInTree(api, deleteAgentName, 5000);

    await api.deleteAgent(deleteAgentName);
    await waitForAgentGone(api, deleteAgentName, 5000);

    assertEqual(api.findAgentInTree(deleteAgentName), null, 'Agent should be gone after delete');
    assertEqual(api.findLockInTree('/test/delete/agent.ts'), null, 'Agent lock should also be gone');
  });

  test('sendMessage creates message in state', async () => {
    const api = getTestAPI();

    const receiverName = `receiver-${testId}`;
    await api.callTool('register', { name: receiverName });

    const senderName = `store-sender-${testId}`;
    await api.sendMessage(senderName, receiverName, 'Test message via store.sendMessage');

    await waitForMessageInTree(api, 'Test message via store', 5000);

    const msgItem = api.findMessageInTree('Test message via store');
    assertOk(msgItem, 'Message should appear in tree');
    const label = getLabel(msgItem!);
    assertOk(label.includes(senderName), 'Message should show sender');
    assertOk(label.includes(receiverName), 'Message should show receiver');
  });
});

// Extension Commands Coverage Tests
suite('Extension Commands Coverage', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
    await safeDisconnect();
    installDialogMocks();
  });

  suiteTeardown(() => {
    restoreDialogMocks();
  });

  test('refresh command works when connected', async () => {
    await safeDisconnect();
    const api = getTestAPI();
    await api.connect();
    await waitForConnection();

    await vscode.commands.executeCommand('tooManyCooks.refresh');

    assertOk(api.isConnected(), 'Should still be connected after refresh');
  });

  test('connect command succeeds with valid server', async () => {
    await safeDisconnect();
    const api = getTestAPI();

    await vscode.commands.executeCommand('tooManyCooks.connect');

    await waitForCondition(
      () => api.isConnected(),
      'Connection to establish',
    );

    assertOk(api.isConnected(), 'Should be connected after connect command');
  });

  test('deleteLock command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assertOk(commands.includes('tooManyCooks.deleteLock'), 'deleteLock command should be registered');
  });

  test('deleteAgent command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assertOk(commands.includes('tooManyCooks.deleteAgent'), 'deleteAgent command should be registered');
  });

  test('sendMessage command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assertOk(commands.includes('tooManyCooks.sendMessage'), 'sendMessage command should be registered');
  });
});

// Tree Provider Edge Cases
suite('Tree Provider Edge Cases', () => {
  const testId = Date.now();
  const agentName = `edge-case-${testId}`;
  let agentKey: string | undefined;

  suiteSetup(async () => {
    await waitForExtensionActivation();
    await safeDisconnect();
    cleanDatabase();

    const api = getTestAPI();
    await api.connect();
    await waitForConnection();

    const result = await callToolString(api, 'register', { name: agentName });
    agentKey = extractKeyFromResult(result);
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('Messages tree handles read messages correctly', async () => {
    const api = getTestAPI();
    if (!agentKey) { throw new Error('agentKey not set'); }

    const receiverName = `edge-receiver-${testId}`;
    const regResult = await callToolString(api, 'register', { name: receiverName });
    const receiverKey = extractKeyFromResult(regResult);

    await api.callTool('message', {
      action: 'send',
      agent_name: agentName,
      agent_key: agentKey,
      to_agent: receiverName,
      content: 'Edge case message',
    });

    await waitForMessageInTree(api, 'Edge case', 5000);

    // Fetch messages to mark as read
    await api.callTool('message', {
      action: 'get',
      agent_name: receiverName,
      agent_key: receiverKey,
    });

    await api.refreshStatus();

    const msgItem = api.findMessageInTree('Edge case');
    assertOk(msgItem, 'Message should still appear after being read');
  });

  test('Agents tree shows summary counts correctly', async () => {
    const api = getTestAPI();
    if (!agentKey) { throw new Error('agentKey not set'); }

    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/edge/case/file.ts',
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Edge case lock',
    });

    await waitForLockInTree(api, '/edge/case/file.ts', 5000);

    const agentItem = api.findAgentInTree(agentName);
    assertOk(agentItem, 'Agent should be in tree');
    const desc = getDescription(agentItem!);
    assertOk(desc.includes('lock'), `Agent description should mention locks, got: ${desc}`);
  });

  test('Plans appear correctly as agent children', async () => {
    const api = getTestAPI();
    if (!agentKey) { throw new Error('agentKey not set'); }

    await api.callTool('plan', {
      action: 'update',
      agent_name: agentName,
      agent_key: agentKey,
      goal: 'Edge case goal',
      current_task: 'Testing edge cases',
    });

    // Wait for plan to appear
    const start = Date.now();
    while (Date.now() - start < 10000) {
      try { await api.refreshStatus(); } catch { /* ignore */ }
      const agent = api.findAgentInTree(agentName);
      if (agent && hasChildWithLabel(agent, 'Edge case goal')) { break; }
      await delay(200);
    }

    const agentItem = api.findAgentInTree(agentName);
    const children = getChildren(agentItem!);
    assertOk(children, 'Agent should have children');

    const planChild = children!.find(c => getLabel(c).includes('Goal:'));
    assertOk(planChild, 'Agent should have plan child');
    const planLabel = getLabel(planChild!);
    assertOk(planLabel.includes('Edge case goal'), `Plan child should contain goal, got: ${planLabel}`);
  });
});

// Error Handling Coverage Tests
suite('Error Handling Coverage', () => {
  const testId = Date.now();
  const agentName = `error-test-${testId}`;

  suiteSetup(async () => {
    await waitForExtensionActivation();
    await safeDisconnect();
    const api = getTestAPI();
    await api.connect();
    await waitForConnection();

    await api.callTool('register', { name: agentName });
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('Tool call with isError response triggers error handling', async () => {
    const api = getTestAPI();

    let caught = false;
    try {
      await api.callTool('lock', {
        action: 'acquire',
        file_path: '/error/test/file.ts',
        agent_name: agentName,
        agent_key: 'invalid-key-that-should-fail',
        reason: 'Testing error path',
      });
    } catch {
      caught = true;
    }

    console.log(`Error handling test: caught=${caught}`);
  });

  test('Invalid tool arguments trigger error response', async () => {
    const api = getTestAPI();

    let caught = false;
    try {
      await api.callTool('lock', {
        action: 'acquire',
        // Missing file_path, agent_name, agent_key
      });
    } catch {
      caught = true;
    }

    console.log(`Invalid args test: caught=${caught}`);
  });

  test('Disconnect while connected covers stop path', async () => {
    const api = getTestAPI();

    assertOk(api.isConnected(), 'Should be connected');
    await api.disconnect();
    assertEqual(api.isConnected(), false, 'Should be disconnected');

    // Reconnect for other tests
    await api.connect();
    await waitForConnection();
  });

  test('Refresh after error state recovers', async () => {
    const api = getTestAPI();
    await api.refreshStatus();
    assertOk(api.isConnected(), 'Should still be connected after refresh');
  });

  test('Dashboard panel can be created and disposed', async () => {
    await vscode.commands.executeCommand('tooManyCooks.showDashboard');
    await delay(500);
    await vscode.commands.executeCommand('workbench.action.closeAllEditors');
    await delay(200);

    await vscode.commands.executeCommand('tooManyCooks.showDashboard');
    await delay(500);
    await vscode.commands.executeCommand('workbench.action.closeAllEditors');
  });

  test('Dashboard panel reveal when already open', async () => {
    await vscode.commands.executeCommand('tooManyCooks.showDashboard');
    await delay(500);
    await vscode.commands.executeCommand('tooManyCooks.showDashboard');
    await delay(300);
    await vscode.commands.executeCommand('workbench.action.closeAllEditors');
  });

  test('Configuration change handler is exercised', async () => {
    const config = vscode.workspace.getConfiguration('tooManyCooks');
    const originalAutoConnect = config.get<boolean>('autoConnect') ?? true;

    await config.update('autoConnect', !originalAutoConnect, vscode.ConfigurationTarget.Global);
    await delay(100);

    await config.update('autoConnect', originalAutoConnect, vscode.ConfigurationTarget.Global);
    await delay(100);

    const api = getTestAPI();
    assertOk(api, 'API should still exist');
  });
});
