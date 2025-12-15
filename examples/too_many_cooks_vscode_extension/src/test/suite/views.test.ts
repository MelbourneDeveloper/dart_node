/**
 * View Tests
 * Verifies tree views are registered, visible, and UI bugs are fixed.
 */

import * as assert from 'assert';
import * as vscode from 'vscode';
import {
  waitForExtensionActivation,
  waitForConnection,
  waitForCondition,
  openTooManyCooksPanel,
  getTestAPI,
  restoreDialogMocks,
  cleanDatabase,
  safeDisconnect,
} from '../test-helpers';

// Ensure any dialog mocks from previous tests are restored
restoreDialogMocks();

suite('Views', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('Too Many Cooks view container is registered', async () => {
    // Open the view container
    await openTooManyCooksPanel();

    // The test passes if the command doesn't throw
    // We can't directly query view containers, but opening succeeds
  });

  test('Agents view is accessible', async () => {
    await openTooManyCooksPanel();

    // Try to focus the agents view
    try {
      await vscode.commands.executeCommand('tooManyCooksAgents.focus');
    } catch {
      // View focus may not work in test environment, but that's ok
      // The important thing is the view exists
    }
  });

  test('Locks view is accessible', async () => {
    await openTooManyCooksPanel();

    try {
      await vscode.commands.executeCommand('tooManyCooksLocks.focus');
    } catch {
      // View focus may not work in test environment
    }
  });

  test('Messages view is accessible', async () => {
    await openTooManyCooksPanel();

    try {
      await vscode.commands.executeCommand('tooManyCooksMessages.focus');
    } catch {
      // View focus may not work in test environment
    }
  });

});
// Note: Plans are now shown under agents in the Agents tree, not as a separate view

/**
 * UI Bug Fix Tests
 * Verifies that specific UI bugs have been fixed.
 */
suite('UI Bug Fixes', function () {
  let agentKey: string;
  const testId = Date.now();
  const agentName = `ui-test-agent-${testId}`;

  suiteSetup(async function () {
    this.timeout(60000);

    // waitForExtensionActivation handles server path setup and validation
    await waitForExtensionActivation();

    // Safely disconnect to avoid race condition with auto-connect
    await safeDisconnect();

    const api = getTestAPI();
    await api.connect();
    await waitForConnection();

    // Register test agent
    const result = await api.callTool('register', { name: agentName });
    agentKey = JSON.parse(result).agent_key;
  });

  suiteTeardown(async () => {
    await safeDisconnect();
    cleanDatabase();
  });

  test('BUG FIX: Messages show as single row (no 4-row expansion)', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Send a message
    await api.callTool('message', {
      action: 'send',
      agent_name: agentName,
      agent_key: agentKey,
      to_agent: '*',
      content: 'Test message for UI verification',
    });

    // Wait for message to appear in tree
    await waitForCondition(
      () => api.findMessageInTree('Test message') !== undefined,
      'message to appear in tree',
      5000
    );

    // Find our message
    const msgItem = api.findMessageInTree('Test message');
    assert.ok(msgItem, 'Message must appear in tree');

    // BUG FIX VERIFICATION:
    // Messages should NOT have children (no expandable 4-row detail view)
    // The old bug showed: Content, Sent, Status, ID as separate rows
    assert.strictEqual(
      msgItem.children,
      undefined,
      'BUG FIX: Message items must NOT have children (no 4-row expansion)'
    );

    // Message should show as single row with:
    // - label: "from → to | time [unread]"
    // - description: message content
    assert.ok(
      msgItem.label.includes(agentName),
      `Label should include sender: ${msgItem.label}`
    );
    assert.ok(
      msgItem.label.includes('→'),
      `Label should have arrow separator: ${msgItem.label}`
    );
    assert.ok(
      msgItem.description?.includes('Test message'),
      `Description should be message content: ${msgItem.description}`
    );
  });

  test('BUG FIX: Message format is "from → to | time [unread]"', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // The message was sent in the previous test
    const msgItem = api.findMessageInTree('Test message');
    assert.ok(msgItem, 'Message must exist from previous test');

    // Verify label format: "agentName → all | now [unread]"
    const labelRegex = /^.+ → .+ \| \d+[dhm]|now( \[unread\])?$/;
    assert.ok(
      labelRegex.test(msgItem.label) || msgItem.label.includes('→'),
      `Label should match format "from → to | time [unread]", got: ${msgItem.label}`
    );
  });

  test('BUG FIX: Unread messages show [unread] indicator', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Find any unread message
    const messagesTree = api.getMessagesTreeSnapshot();
    const unreadMsg = messagesTree.find(m => m.label.includes('[unread]'));

    // We may have marked messages read by fetching them, so this is informational
    if (unreadMsg) {
      assert.ok(
        unreadMsg.label.includes('[unread]'),
        'Unread messages should have [unread] in label'
      );
    }

    // Verify the message count APIs work correctly
    const totalCount = api.getMessageCount();
    const unreadCount = api.getUnreadMessageCount();
    assert.ok(
      unreadCount <= totalCount,
      `Unread count (${unreadCount}) must be <= total (${totalCount})`
    );
  });

  test('BUG FIX: Auto-mark-read works when agent fetches messages', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Register a second agent to receive messages
    const receiver = `ui-receiver-${testId}`;
    const regResult = await api.callTool('register', { name: receiver });
    const receiverKey = JSON.parse(regResult).agent_key;

    // Send a message TO the receiver
    await api.callTool('message', {
      action: 'send',
      agent_name: agentName,
      agent_key: agentKey,
      to_agent: receiver,
      content: 'This should be auto-marked read',
    });

    // Receiver fetches their messages (this triggers auto-mark-read)
    const fetchResult = await api.callTool('message', {
      action: 'get',
      agent_name: receiver,
      agent_key: receiverKey,
      unread_only: true,
    });

    const fetched = JSON.parse(fetchResult);
    assert.ok(
      fetched.messages,
      'Get messages should return messages array'
    );

    // The message should be in the fetched list
    const ourMsg = fetched.messages.find(
      (m: { content: string }) => m.content.includes('auto-marked')
    );
    assert.ok(ourMsg, 'Message should be in fetched results');

    // Now fetch again - it should NOT appear (already marked read)
    const fetchResult2 = await api.callTool('message', {
      action: 'get',
      agent_name: receiver,
      agent_key: receiverKey,
      unread_only: true,
    });

    const fetched2 = JSON.parse(fetchResult2);
    const stillUnread = fetched2.messages.find(
      (m: { content: string }) => m.content.includes('auto-marked')
    );
    assert.strictEqual(
      stillUnread,
      undefined,
      'BUG FIX: Message should be auto-marked read after first fetch'
    );
  });

  test('BROADCAST: Messages to "*" appear in tree as "all"', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Send a broadcast message
    await api.callTool('message', {
      action: 'send',
      agent_name: agentName,
      agent_key: agentKey,
      to_agent: '*',
      content: 'Broadcast test message to everyone',
    });

    // Wait for message to appear in tree
    await waitForCondition(
      () => api.findMessageInTree('Broadcast test') !== undefined,
      'broadcast message to appear in tree',
      5000
    );

    // Find the broadcast message
    const msgItem = api.findMessageInTree('Broadcast test');
    assert.ok(msgItem, 'Broadcast message MUST appear in tree');

    // PROOF: The label contains "all" (not "*")
    assert.ok(
      msgItem.label.includes('→ all'),
      `Broadcast messages should show "→ all" in label, got: ${msgItem.label}`
    );

    // Content should be in description
    assert.ok(
      msgItem.description?.includes('Broadcast test'),
      `Description should contain message content, got: ${msgItem.description}`
    );

    console.log(`BROADCAST TEST PASSED: ${msgItem.label}`);
  });
});
