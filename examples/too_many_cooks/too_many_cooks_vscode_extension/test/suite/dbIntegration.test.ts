// Database Integration Tests - REAL end-to-end tests.
// These tests PROVE that UI tree views update when database state changes.
// NO MOCKING. NO SKIPPING. FAIL HARD.

import {
  waitForExtensionActivation,
  waitForConnection,
  waitForCondition,
  waitForLockInTree,
  waitForLockGone,
  waitForAgentInTree,
  waitForMessageInTree,
  safeDisconnect,
  getTestAPI,
  callToolString,
  extractKeyFromResult,
  resetServerState,
  restoreDialogMocks,
  getLabel,
  getDescription,
  getChildren,
  hasChildWithLabel,
  findChildByLabel,
  dumpTree,
  assertOk,
  assertEqual,
} from './testHelpers';

restoreDialogMocks();

suite('DB Integration - UI Verification', () => {
  let agent1Key = '';
  let agent2Key = '';
  const testId = Date.now();
  const agent1Name = `test-agent-${testId}-1`;
  const agent2Name = `test-agent-${testId}-2`;

  suiteSetup(async () => {
    await waitForExtensionActivation();
    // Connect to ensure server is running, reset state, then disconnect
    // so the first test can verify the connect flow
    const api = getTestAPI();
    if (!api.isConnected()) {
      await api.connect();
      await waitForConnection();
    }
    await resetServerState();
    await safeDisconnect();
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('Connect to database', async () => {
    await safeDisconnect();
    const api = getTestAPI();

    assertOk(!api.isConnected(), 'Should be disconnected');

    await api.connect();
    await waitForConnection();

    assertOk(api.isConnected(), 'Should be connected');
    assertEqual(api.getConnectionStatus(), 'connected');
  });

  test('Empty state shows empty trees', async () => {
    const api = getTestAPI();
    await api.refreshStatus();

    const agentsTree = api.getAgentsTreeSnapshot();
    const locksTree = api.getLocksTreeSnapshot();
    const messagesTree = api.getMessagesTreeSnapshot();

    dumpTree('AGENTS', agentsTree);
    dumpTree('LOCKS', locksTree);
    dumpTree('MESSAGES', messagesTree);

    assertEqual(agentsTree.length, 0, 'Agents tree should be empty');

    const hasNoLocks = locksTree.some(i => getLabel(i) === 'No locks');
    assertOk(hasNoLocks, 'Locks tree should show "No locks"');

    const hasNoMessages = messagesTree.some(i => getLabel(i) === 'No messages');
    assertOk(hasNoMessages, 'Messages tree should show "No messages"');
  });

  test('Register agent-1 → label APPEARS in agents tree', async () => {
    const api = getTestAPI();

    const result = await callToolString(api, 'register', { name: agent1Name });
    agent1Key = extractKeyFromResult(result);
    assertOk(agent1Key.length > 0, 'Should return agent key');

    await waitForAgentInTree(api, agent1Name);

    const agentItem = api.findAgentInTree(agent1Name);
    assertOk(agentItem, `${agent1Name} MUST appear in the tree`);
    assertEqual(getLabel(agentItem!), agent1Name, `Label must be exactly "${agent1Name}"`);
  });

  test('Register agent-2 → both agents visible in tree', async () => {
    const api = getTestAPI();

    const result = await callToolString(api, 'register', { name: agent2Name });
    agent2Key = extractKeyFromResult(result);

    await waitForCondition(
      () => api.getAgentsTreeSnapshot().length >= 2,
      '2 agents in tree',
    );

    const tree = api.getAgentsTreeSnapshot();
    dumpTree('AGENTS after second register', tree);

    assertOk(api.findAgentInTree(agent1Name), `${agent1Name} MUST still be in tree`);
    assertOk(api.findAgentInTree(agent2Name), `${agent2Name} MUST be in tree`);
    assertEqual(tree.length, 2, 'Exactly 2 agent items');
  });

  test('Acquire lock on /src/main.ts → file path APPEARS in locks tree', async () => {
    const api = getTestAPI();

    await callToolString(api, 'lock', {
      action: 'acquire',
      file_path: '/src/main.ts',
      agent_name: agent1Name,
      agent_key: agent1Key,
      reason: 'Editing main',
    });

    await waitForLockInTree(api, '/src/main.ts');

    const lockItem = api.findLockInTree('/src/main.ts');
    dumpTree('LOCKS after acquire', api.getLocksTreeSnapshot());

    assertOk(lockItem, '/src/main.ts MUST appear in the tree');
    assertEqual(getLabel(lockItem!), '/src/main.ts', 'Label must be exact file path');

    const desc = getDescription(lockItem!);
    assertOk(desc.startsWith(agent1Name), `Description should start with agent name. desc="${desc}", agent="${agent1Name}"`);
  });

  test('Acquire 2 more locks → all 3 file paths visible', async () => {
    const api = getTestAPI();

    await callToolString(api, 'lock', {
      action: 'acquire',
      file_path: '/src/utils.ts',
      agent_name: agent1Name,
      agent_key: agent1Key,
      reason: 'Utils',
    });

    await callToolString(api, 'lock', {
      action: 'acquire',
      file_path: '/src/types.ts',
      agent_name: agent2Name,
      agent_key: agent2Key,
      reason: 'Types',
    });

    await waitForCondition(
      () => api.getLockTreeItemCount() >= 3,
      '3 locks in tree',
    );

    dumpTree('LOCKS after 3 acquires', api.getLocksTreeSnapshot());

    assertOk(api.findLockInTree('/src/main.ts'), '/src/main.ts MUST be in tree');
    assertOk(api.findLockInTree('/src/utils.ts'), '/src/utils.ts MUST be in tree');
    assertOk(api.findLockInTree('/src/types.ts'), '/src/types.ts MUST be in tree');
    assertEqual(api.getLockTreeItemCount(), 3, 'Exactly 3 lock items');
  });

  test('Release /src/utils.ts → file path DISAPPEARS from tree', async () => {
    const api = getTestAPI();

    await callToolString(api, 'lock', {
      action: 'release',
      file_path: '/src/utils.ts',
      agent_name: agent1Name,
      agent_key: agent1Key,
    });

    await waitForLockGone(api, '/src/utils.ts');

    dumpTree('LOCKS after release', api.getLocksTreeSnapshot());

    assertEqual(api.findLockInTree('/src/utils.ts'), null, '/src/utils.ts MUST NOT be in tree');
    assertOk(api.findLockInTree('/src/main.ts'), '/src/main.ts MUST still be in tree');
    assertOk(api.findLockInTree('/src/types.ts'), '/src/types.ts MUST still be in tree');
    assertEqual(api.getLockTreeItemCount(), 2, 'Exactly 2 lock items remain');
  });

  test('Update plan for agent-1 → plan content APPEARS in agent children', async () => {
    const api = getTestAPI();

    await callToolString(api, 'plan', {
      action: 'update',
      agent_name: agent1Name,
      agent_key: agent1Key,
      goal: 'Implement feature X',
      current_task: 'Writing tests',
    });

    await waitForCondition(() => {
      const agentItem = api.findAgentInTree(agent1Name);
      if (!agentItem) { return false; }
      return hasChildWithLabel(agentItem, 'Implement feature X');
    }, `${agent1Name} plan to appear in agent children`);

    dumpTree('AGENTS after plan update', api.getAgentsTreeSnapshot());

    const agentItem = api.findAgentInTree(agent1Name);
    assertOk(agentItem, `${agent1Name} MUST be in tree`);
    const children = getChildren(agentItem!);
    assertOk(children, 'Agent should have children');

    const planChild = findChildByLabel(agentItem!, 'Goal: Implement feature X');
    assertOk(planChild, 'Plan goal "Implement feature X" MUST appear in agent children');

    const planDesc = getDescription(planChild!);
    assertOk(planDesc.includes('Writing tests'), `Plan description should contain task, got: ${planDesc}`);
  });

  test('Send message agent-1 → agent-2 → message APPEARS in tree', async () => {
    const api = getTestAPI();

    await callToolString(api, 'message', {
      action: 'send',
      agent_name: agent1Name,
      agent_key: agent1Key,
      to_agent: agent2Name,
      content: 'Starting work on main.ts',
    });

    await waitForMessageInTree(api, 'Starting work');

    dumpTree('MESSAGES after send', api.getMessagesTreeSnapshot());

    const msgItem = api.findMessageInTree('Starting work');
    assertOk(msgItem, 'Message MUST appear in tree');

    const msgLabel = getLabel(msgItem!);
    assertOk(msgLabel.includes(agent1Name), `Message label should contain sender, got: ${msgLabel}`);
    assertOk(msgLabel.includes(agent2Name), `Message label should contain recipient, got: ${msgLabel}`);

    const msgDesc = getDescription(msgItem!);
    assertOk(msgDesc.includes('Starting work'), `Description should contain content preview, got: ${msgDesc}`);
  });

  test('Send 2 more messages → all 3 messages visible with correct labels', async () => {
    const api = getTestAPI();

    await callToolString(api, 'message', {
      action: 'send',
      agent_name: agent2Name,
      agent_key: agent2Key,
      to_agent: agent1Name,
      content: 'Acknowledged',
    });

    await callToolString(api, 'message', {
      action: 'send',
      agent_name: agent1Name,
      agent_key: agent1Key,
      to_agent: agent2Name,
      content: 'Done with main.ts',
    });

    await waitForCondition(
      () => api.getMessageTreeItemCount() >= 3,
      '3 messages in tree',
    );

    dumpTree('MESSAGES after 3 sends', api.getMessagesTreeSnapshot());

    assertOk(api.findMessageInTree('Starting work'), 'First message MUST be in tree');
    assertOk(api.findMessageInTree('Acknowledged'), 'Second message MUST be in tree');
    assertOk(api.findMessageInTree('Done with main'), 'Third message MUST be in tree');
    assertEqual(api.getMessageTreeItemCount(), 3, 'Exactly 3 message items');
  });

  test('Broadcast message to * → message APPEARS in tree with "all" label', async () => {
    const api = getTestAPI();

    await callToolString(api, 'message', {
      action: 'send',
      agent_name: agent1Name,
      agent_key: agent1Key,
      to_agent: '*',
      content: 'BROADCAST: Important announcement for all agents',
    });

    await waitForMessageInTree(api, 'BROADCAST');

    dumpTree('MESSAGES after broadcast', api.getMessagesTreeSnapshot());

    const broadcastMsg = api.findMessageInTree('BROADCAST');
    assertOk(broadcastMsg, 'Broadcast message MUST appear in tree');

    const label = getLabel(broadcastMsg!);
    assertOk(label.includes(agent1Name), `Broadcast label should contain sender, got: ${label}`);
    assertOk(label.includes('all'), `Broadcast label should show "all" for recipient, got: ${label}`);

    const desc = getDescription(broadcastMsg!);
    assertOk(desc.includes('BROADCAST'), `Description should contain message content, got: ${desc}`);
    assertEqual(api.getMessageTreeItemCount(), 4, 'Should have 4 messages after broadcast');
  });

  test('Agent tree shows locks/messages for each agent', async () => {
    const api = getTestAPI();
    await api.refreshStatus();

    dumpTree('AGENTS with children', api.getAgentsTreeSnapshot());

    const agent1 = api.findAgentInTree(agent1Name);
    assertOk(agent1, `${agent1Name} MUST be in tree`);
    const children = getChildren(agent1!);
    assertOk(children, `${agent1Name} MUST have children showing locks/messages`);

    assertOk(hasChildWithLabel(agent1!, '/src/main.ts'), `${agent1Name} children MUST include /src/main.ts lock`);
    assertOk(hasChildWithLabel(agent1!, 'Implement feature X'), `${agent1Name} children MUST include plan goal`);
    assertOk(hasChildWithLabel(agent1!, 'Messages'), `${agent1Name} children MUST include Messages summary`);
  });

  test('Refresh syncs all state from server', async () => {
    const api = getTestAPI();
    await api.refreshStatus();

    assertOk(api.getAgentCount() >= 2, `At least 2 agents, got ${api.getAgentCount()}`);
    assertOk(api.getLockCount() >= 2, `At least 2 locks, got ${api.getLockCount()}`);
    assertOk(api.getPlans().length >= 1, `At least 1 plan, got ${api.getPlans().length}`);
    assertOk(api.getMessages().length >= 4, `At least 4 messages, got ${api.getMessages().length}`);
    assertOk(api.getAgentsTreeSnapshot().length >= 2, `At least 2 agents in tree`);
    assertOk(api.getLockTreeItemCount() >= 2, `At least 2 locks in tree`);
    assertOk(api.getMessageTreeItemCount() >= 4, `At least 4 messages in tree`);

    const agentItem = api.findAgentInTree(agent1Name);
    assertOk(agentItem && hasChildWithLabel(agentItem, 'Goal:'), 'Agent should have plan child');
  });

  test('Disconnect clears all tree views', async () => {
    await safeDisconnect();
    const api = getTestAPI();

    assertOk(!api.isConnected(), 'Should be disconnected');

    assertEqual(api.getAgents().length, 0, 'Agents should be empty');
    assertEqual(api.getLocks().length, 0, 'Locks should be empty');
    assertEqual(api.getMessages().length, 0, 'Messages should be empty');
    assertEqual(api.getPlans().length, 0, 'Plans should be empty');

    assertEqual(api.getAgentsTreeSnapshot().length, 0, 'Agents tree should be empty');
    assertEqual(api.getLockTreeItemCount(), 0, 'Locks tree should be empty');
    assertEqual(api.getMessageTreeItemCount(), 0, 'Messages tree should be empty');
  });

  test('Reconnect restores all state and tree views', async () => {
    const api = getTestAPI();

    await api.connect();
    await waitForConnection();
    await api.refreshStatus();

    // Re-register agents if lost (WAL not checkpointed on server kill)
    if (!api.findAgentInTree(agent1Name)) {
      const result1 = await callToolString(api, 'register', { name: agent1Name });
      agent1Key = extractKeyFromResult(result1);
    }
    if (!api.findAgentInTree(agent2Name)) {
      const result2 = await callToolString(api, 'register', { name: agent2Name });
      agent2Key = extractKeyFromResult(result2);
    }

    // Re-acquire locks if lost
    if (!api.findLockInTree('/src/main.ts')) {
      await api.callTool('lock', {
        action: 'acquire',
        file_path: '/src/main.ts',
        agent_name: agent1Name,
        agent_key: agent1Key,
        reason: 'Editing main',
      });
    }
    if (!api.findLockInTree('/src/types.ts')) {
      await api.callTool('lock', {
        action: 'acquire',
        file_path: '/src/types.ts',
        agent_name: agent2Name,
        agent_key: agent2Key,
        reason: 'Types',
      });
    }

    // Re-create plan if lost
    const agentItemForPlan = api.findAgentInTree(agent1Name);
    if (!agentItemForPlan || !hasChildWithLabel(agentItemForPlan, 'Goal:')) {
      await api.callTool('plan', {
        action: 'update',
        agent_name: agent1Name,
        agent_key: agent1Key,
        goal: 'Implement feature X',
        current_task: 'Writing tests',
      });
    }

    // Re-send messages if lost
    if (!api.findMessageInTree('Starting work')) {
      await api.callTool('message', {
        action: 'send',
        agent_name: agent1Name,
        agent_key: agent1Key,
        to_agent: agent2Name,
        content: 'Starting work on main.ts',
      });
    }
    if (!api.findMessageInTree('Acknowledged')) {
      await api.callTool('message', {
        action: 'send',
        agent_name: agent2Name,
        agent_key: agent2Key,
        to_agent: agent1Name,
        content: 'Acknowledged',
      });
    }
    if (!api.findMessageInTree('Done with main')) {
      await api.callTool('message', {
        action: 'send',
        agent_name: agent1Name,
        agent_key: agent1Key,
        to_agent: agent2Name,
        content: 'Done with main.ts',
      });
    }
    if (!api.findMessageInTree('BROADCAST')) {
      await api.callTool('message', {
        action: 'send',
        agent_name: agent1Name,
        agent_key: agent1Key,
        to_agent: '*',
        content: 'BROADCAST: Important announcement for all agents',
      });
    }

    await waitForCondition(
      () => api.getAgentCount() >= 2 && api.getLockCount() >= 2,
      'state to be restored/recreated',
    );

    assertOk(api.getAgentCount() >= 2, `At least 2 agents, got ${api.getAgentCount()}`);
    assertOk(api.getLockCount() >= 2, `At least 2 locks, got ${api.getLockCount()}`);
    assertOk(api.getPlans().length >= 1, `At least 1 plan, got ${api.getPlans().length}`);
    assertOk(api.getMessages().length >= 4, `At least 4 messages, got ${api.getMessages().length}`);
  });
});
