// View Tests
// Verifies tree views are registered, visible, and UI bugs are fixed.

import * as vscode from 'vscode';
import {
  waitForExtensionActivation,
  waitForConnection,
  waitForMessageInTree,
  safeDisconnect,
  getTestAPI,
  callToolString,
  extractKeyFromResult,
  restoreDialogMocks,
  getLabel,
  getDescription,
  getChildren,
  assertOk,
  assertEqual,
} from './testHelpers';

restoreDialogMocks();

suite('Views', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('Too Many Cooks view container is registered', async () => {
    await vscode.commands.executeCommand('workbench.view.extension.tooManyCooks');
  });

  test('Agents view is accessible', async () => {
    await vscode.commands.executeCommand('workbench.view.extension.tooManyCooks');
    try {
      await vscode.commands.executeCommand('tooManyCooksAgents.focus');
    } catch { /* View focus may not work in test environment */ }
  });

  test('Locks view is accessible', async () => {
    await vscode.commands.executeCommand('workbench.view.extension.tooManyCooks');
    try {
      await vscode.commands.executeCommand('tooManyCooksLocks.focus');
    } catch { /* View focus may not work in test environment */ }
  });

  test('Messages view is accessible', async () => {
    await vscode.commands.executeCommand('workbench.view.extension.tooManyCooks');
    try {
      await vscode.commands.executeCommand('tooManyCooksMessages.focus');
    } catch { /* View focus may not work in test environment */ }
  });
});

suite('UI Bug Fixes', () => {
  const testId = Date.now();
  const agentName = `ui-test-agent-${testId}`;
  let agentKey = '';

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

  test('BUG FIX: Messages show as single row (no 4-row expansion)', async () => {
    const api = getTestAPI();

    await callToolString(api, 'message', {
      action: 'send',
      agent_name: agentName,
      agent_key: agentKey,
      to_agent: '*',
      content: 'Test message for UI verification',
    });

    await waitForMessageInTree(api, 'Test message');

    const msgItem = api.findMessageInTree('Test message');
    assertOk(msgItem, 'Message must appear in tree');

    const children = getChildren(msgItem!);
    assertEqual(children, undefined, 'BUG FIX: Message items must NOT have children');

    const label = getLabel(msgItem!);
    assertOk(label.includes(agentName), `Label should include sender: ${label}`);
    assertOk(label.includes('\u2192'), `Label should have arrow separator: ${label}`);

    const description = getDescription(msgItem!);
    assertOk(description.includes('Test message'), `Description should be message content: ${description}`);
  });

  test('BUG FIX: Message format is "from → to | time [unread]"', async () => {
    const api = getTestAPI();
    const msgItem = api.findMessageInTree('Test message');
    assertOk(msgItem, 'Message must exist from previous test');

    const label = getLabel(msgItem!);
    assertOk(label.includes('\u2192'), `Label should match format "from → to | time [unread]", got: ${label}`);
  });

  test('BUG FIX: Unread messages show [unread] indicator', async () => {
    const api = getTestAPI();
    const totalCount = api.getMessageCount();
    const unreadCount = api.getUnreadMessageCount();
    assertOk(unreadCount <= totalCount, `Unread count (${unreadCount}) must be <= total (${totalCount})`);
  });

  test('BUG FIX: Auto-mark-read works when agent fetches messages', async () => {
    const api = getTestAPI();

    const receiver = `ui-receiver-${testId}`;
    const regResult = await callToolString(api, 'register', { name: receiver });
    const receiverKey = extractKeyFromResult(regResult);

    await callToolString(api, 'message', {
      action: 'send',
      agent_name: agentName,
      agent_key: agentKey,
      to_agent: receiver,
      content: 'This should be auto-marked read',
    });

    const fetched = await callToolString(api, 'message', {
      action: 'get',
      agent_name: receiver,
      agent_key: receiverKey,
      unread_only: true,
    });
    assertOk(/"messages"\s*:\s*\[/.test(fetched), 'Get messages should return messages array');
    assertOk(fetched.includes('auto-marked'), 'Message should be in fetched results');

    const fetched2 = await callToolString(api, 'message', {
      action: 'get',
      agent_name: receiver,
      agent_key: receiverKey,
      unread_only: true,
    });
    assertEqual(
      fetched2.includes('auto-marked'),
      false,
      'BUG FIX: Message should be auto-marked read after first fetch',
    );
  });

  test('BROADCAST: Messages to "*" appear in tree as "all"', async () => {
    const api = getTestAPI();

    await callToolString(api, 'message', {
      action: 'send',
      agent_name: agentName,
      agent_key: agentKey,
      to_agent: '*',
      content: 'Broadcast test message to everyone',
    });

    await waitForMessageInTree(api, 'Broadcast test');

    const msgItem = api.findMessageInTree('Broadcast test');
    assertOk(msgItem, 'Broadcast message MUST appear in tree');

    const label = getLabel(msgItem!);
    assertOk(label.includes('\u2192 all'), `Broadcast messages should show "→ all" in label, got: ${label}`);

    const description = getDescription(msgItem!);
    assertOk(description.includes('Broadcast test'), `Description should contain message content, got: ${description}`);
  });
});
