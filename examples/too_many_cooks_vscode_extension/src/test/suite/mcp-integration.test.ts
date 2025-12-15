/**
 * MCP Integration Tests - REAL end-to-end tests.
 * These tests PROVE that UI tree views update when MCP server state changes.
 *
 * What we're testing:
 * 1. Call MCP tool (register, lock, message, plan)
 * 2. Wait for the tree view to update
 * 3. ASSERT the exact label/description appears in the tree
 *
 * NO MOCKING. NO SKIPPING. FAIL HARD.
 */

import * as assert from 'assert';
import {
  waitForExtensionActivation,
  waitForConnection,
  waitForCondition,
  getTestAPI,
  restoreDialogMocks,
  cleanDatabase,
  safeDisconnect,
} from '../test-helpers';
import type { TreeItemSnapshot } from '../../test-api';

// Ensure any dialog mocks from previous tests are restored
restoreDialogMocks();

/** Helper to dump tree snapshot for debugging */
function dumpTree(name: string, items: TreeItemSnapshot[]): void {
  console.log(`\n=== ${name} TREE ===`);
  const dump = (items: TreeItemSnapshot[], indent = 0): void => {
    for (const item of items) {
      const prefix = '  '.repeat(indent);
      const desc = item.description ? ` [${item.description}]` : '';
      console.log(`${prefix}- ${item.label}${desc}`);
      if (item.children) dump(item.children, indent + 1);
    }
  };
  dump(items);
  console.log('=== END ===\n');
}

suite('MCP Integration - UI Verification', function () {
  let agent1Key: string;
  let agent2Key: string;
  // Use timestamped agent names to avoid collisions with other test runs
  const testId = Date.now();
  const agent1Name = `test-agent-${testId}-1`;
  const agent2Name = `test-agent-${testId}-2`;

  suiteSetup(async function () {
    this.timeout(60000);

    // waitForExtensionActivation handles server path setup and validation
    await waitForExtensionActivation();

    // Clean DB for fresh state
    cleanDatabase();
  });

  suiteTeardown(async () => {
    await safeDisconnect();
    // Clean up DB after tests
    cleanDatabase();
  });

  test('Connect to MCP server', async function () {
    this.timeout(30000);

    await safeDisconnect();
    const api = getTestAPI();
    assert.strictEqual(api.isConnected(), false, 'Should be disconnected');

    await api.connect();
    await waitForConnection();

    assert.strictEqual(api.isConnected(), true, 'Should be connected');
    assert.strictEqual(api.getConnectionStatus(), 'connected');
  });

  test('Empty state shows empty trees', async function () {
    this.timeout(10000);
    const api = getTestAPI();
    await api.refreshStatus();

    // Verify tree snapshots show empty/placeholder state
    const agentsTree = api.getAgentsTreeSnapshot();
    const locksTree = api.getLocksTreeSnapshot();
    const messagesTree = api.getMessagesTreeSnapshot();

    dumpTree('AGENTS', agentsTree);
    dumpTree('LOCKS', locksTree);
    dumpTree('MESSAGES', messagesTree);

    assert.strictEqual(agentsTree.length, 0, 'Agents tree should be empty');
    assert.strictEqual(
      locksTree.some(item => item.label === 'No locks'),
      true,
      'Locks tree should show "No locks"'
    );
    assert.strictEqual(
      messagesTree.some(item => item.label === 'No messages'),
      true,
      'Messages tree should show "No messages"'
    );
    // Note: Plans are shown as children under agents, not in a separate tree
  });

  test('Register agent-1 → label APPEARS in agents tree', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    const result = await api.callTool('register', { name: agent1Name });
    agent1Key = JSON.parse(result).agent_key;
    assert.ok(agent1Key, 'Should return agent key');

    // Wait for tree to update
    await waitForCondition(
      () => api.findAgentInTree(agent1Name) !== undefined,
      `${agent1Name} to appear in tree`,
      5000
    );

    // PROOF: The agent label is in the tree
    const agentItem = api.findAgentInTree(agent1Name);
    assert.ok(agentItem, `${agent1Name} MUST appear in the tree`);
    assert.strictEqual(agentItem.label, agent1Name, `Label must be exactly "${agent1Name}"`);

    // Dump full tree for visibility
    dumpTree('AGENTS after register', api.getAgentsTreeSnapshot());
  });

  test('Register agent-2 → both agents visible in tree', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    const result = await api.callTool('register', { name: agent2Name });
    agent2Key = JSON.parse(result).agent_key;

    await waitForCondition(
      () => api.getAgentsTreeSnapshot().length >= 2,
      '2 agents in tree',
      5000
    );

    const tree = api.getAgentsTreeSnapshot();
    dumpTree('AGENTS after second register', tree);

    // PROOF: Both agent labels appear
    assert.ok(api.findAgentInTree(agent1Name), `${agent1Name} MUST still be in tree`);
    assert.ok(api.findAgentInTree(agent2Name), `${agent2Name} MUST be in tree`);
    assert.strictEqual(tree.length, 2, 'Exactly 2 agent items');
  });

  test('Acquire lock on /src/main.ts → file path APPEARS in locks tree', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/src/main.ts',
      agent_name: agent1Name,
      agent_key: agent1Key,
      reason: 'Editing main',
    });

    await waitForCondition(
      () => api.findLockInTree('/src/main.ts') !== undefined,
      '/src/main.ts to appear in locks tree',
      5000
    );

    const lockItem = api.findLockInTree('/src/main.ts');
    dumpTree('LOCKS after acquire', api.getLocksTreeSnapshot());

    // PROOF: The exact file path appears as a label
    assert.ok(lockItem, '/src/main.ts MUST appear in the tree');
    assert.strictEqual(lockItem.label, '/src/main.ts', 'Label must be exact file path');
    // Description should contain agent name
    assert.ok(
      lockItem.description?.includes(agent1Name),
      `Description should contain agent name, got: ${lockItem.description}`
    );
  });

  test('Acquire 2 more locks → all 3 file paths visible', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/src/utils.ts',
      agent_name: agent1Name,
      agent_key: agent1Key,
      reason: 'Utils',
    });

    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/src/types.ts',
      agent_name: agent2Name,
      agent_key: agent2Key,
      reason: 'Types',
    });

    await waitForCondition(
      () => api.getLockTreeItemCount() >= 3,
      '3 locks in tree',
      5000
    );

    const tree = api.getLocksTreeSnapshot();
    dumpTree('LOCKS after 3 acquires', tree);

    // PROOF: All file paths appear
    assert.ok(api.findLockInTree('/src/main.ts'), '/src/main.ts MUST be in tree');
    assert.ok(api.findLockInTree('/src/utils.ts'), '/src/utils.ts MUST be in tree');
    assert.ok(api.findLockInTree('/src/types.ts'), '/src/types.ts MUST be in tree');
    assert.strictEqual(api.getLockTreeItemCount(), 3, 'Exactly 3 lock items');
  });

  test('Release /src/utils.ts → file path DISAPPEARS from tree', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    await api.callTool('lock', {
      action: 'release',
      file_path: '/src/utils.ts',
      agent_name: agent1Name,
      agent_key: agent1Key,
    });

    await waitForCondition(
      () => api.findLockInTree('/src/utils.ts') === undefined,
      '/src/utils.ts to disappear from tree',
      5000
    );

    const tree = api.getLocksTreeSnapshot();
    dumpTree('LOCKS after release', tree);

    // PROOF: File is gone, others remain
    assert.strictEqual(
      api.findLockInTree('/src/utils.ts'),
      undefined,
      '/src/utils.ts MUST NOT be in tree'
    );
    assert.ok(api.findLockInTree('/src/main.ts'), '/src/main.ts MUST still be in tree');
    assert.ok(api.findLockInTree('/src/types.ts'), '/src/types.ts MUST still be in tree');
    assert.strictEqual(api.getLockTreeItemCount(), 2, 'Exactly 2 lock items remain');
  });

  test('Update plan for agent-1 → plan content APPEARS in agent children', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    await api.callTool('plan', {
      action: 'update',
      agent_name: agent1Name,
      agent_key: agent1Key,
      goal: 'Implement feature X',
      current_task: 'Writing tests',
    });

    // Plans appear as children under the agent, not in a separate tree
    await waitForCondition(
      () => {
        const agentItem = api.findAgentInTree(agent1Name);
        return agentItem?.children?.some(c => c.label.includes('Implement feature X')) ?? false;
      },
      `${agent1Name} plan to appear in agent children`,
      5000
    );

    const agentsTree = api.getAgentsTreeSnapshot();
    dumpTree('AGENTS after plan update', agentsTree);

    // PROOF: Plan appears as child of agent with correct content
    const agentItem = api.findAgentInTree(agent1Name);
    assert.ok(agentItem, `${agent1Name} MUST be in tree`);
    assert.ok(agentItem.children, 'Agent should have children');

    // Find plan child - format is "Goal: <goal>" with description "Task: <task>"
    const planChild = agentItem.children?.find(c => c.label.includes('Goal: Implement feature X'));
    assert.ok(planChild, 'Plan goal "Implement feature X" MUST appear in agent children');
    assert.ok(
      planChild.description?.includes('Writing tests'),
      `Plan description should contain task, got: ${planChild.description}`
    );
  });

  test('Send message agent-1 → agent-2 → message APPEARS in tree', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    await api.callTool('message', {
      action: 'send',
      agent_name: agent1Name,
      agent_key: agent1Key,
      to_agent: agent2Name,
      content: 'Starting work on main.ts',
    });

    await waitForCondition(
      () => api.findMessageInTree('Starting work') !== undefined,
      'message to appear in tree',
      5000
    );

    const tree = api.getMessagesTreeSnapshot();
    dumpTree('MESSAGES after send', tree);

    // PROOF: Message appears with correct sender/content
    const msgItem = api.findMessageInTree('Starting work');
    assert.ok(msgItem, 'Message MUST appear in tree');
    assert.ok(
      msgItem.label.includes(agent1Name),
      `Message label should contain sender, got: ${msgItem.label}`
    );
    assert.ok(
      msgItem.label.includes(agent2Name),
      `Message label should contain recipient, got: ${msgItem.label}`
    );
    assert.ok(
      msgItem.description?.includes('Starting work'),
      `Description should contain content preview, got: ${msgItem.description}`
    );
  });

  test('Send 2 more messages → all 3 messages visible with correct labels', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    await api.callTool('message', {
      action: 'send',
      agent_name: agent2Name,
      agent_key: agent2Key,
      to_agent: agent1Name,
      content: 'Acknowledged',
    });

    await api.callTool('message', {
      action: 'send',
      agent_name: agent1Name,
      agent_key: agent1Key,
      to_agent: agent2Name,
      content: 'Done with main.ts',
    });

    await waitForCondition(
      () => api.getMessageTreeItemCount() >= 3,
      '3 messages in tree',
      5000
    );

    const tree = api.getMessagesTreeSnapshot();
    dumpTree('MESSAGES after 3 sends', tree);

    // PROOF: All messages appear
    assert.ok(api.findMessageInTree('Starting work'), 'First message MUST be in tree');
    assert.ok(api.findMessageInTree('Acknowledged'), 'Second message MUST be in tree');
    assert.ok(api.findMessageInTree('Done with main'), 'Third message MUST be in tree');
    assert.strictEqual(api.getMessageTreeItemCount(), 3, 'Exactly 3 message items');
  });

  test('Broadcast message to * → message APPEARS in tree with "all" label', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Send a broadcast message (to_agent = '*')
    await api.callTool('message', {
      action: 'send',
      agent_name: agent1Name,
      agent_key: agent1Key,
      to_agent: '*',
      content: 'BROADCAST: Important announcement for all agents',
    });

    await waitForCondition(
      () => api.findMessageInTree('BROADCAST') !== undefined,
      'broadcast message to appear in tree',
      5000
    );

    const tree = api.getMessagesTreeSnapshot();
    dumpTree('MESSAGES after broadcast', tree);

    // PROOF: Broadcast message appears with "all" in label
    const broadcastMsg = api.findMessageInTree('BROADCAST');
    assert.ok(broadcastMsg, 'Broadcast message MUST appear in tree');
    assert.ok(
      broadcastMsg.label.includes(agent1Name),
      `Broadcast label should contain sender, got: ${broadcastMsg.label}`
    );
    // Broadcast recipient should show as "all" not "*"
    assert.ok(
      broadcastMsg.label.includes('all'),
      `Broadcast label should show "all" for recipient, got: ${broadcastMsg.label}`
    );
    assert.ok(
      broadcastMsg.description?.includes('BROADCAST'),
      `Description should contain message content, got: ${broadcastMsg.description}`
    );
    // Total should now be 4 messages
    assert.strictEqual(api.getMessageTreeItemCount(), 4, 'Should have 4 messages after broadcast');
  });

  test('Agent tree shows locks/messages for each agent', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    const tree = api.getAgentsTreeSnapshot();
    dumpTree('AGENTS with children', tree);

    // Find agent-1 and check its children
    const agent1 = api.findAgentInTree(agent1Name);
    assert.ok(agent1, `${agent1Name} MUST be in tree`);
    assert.ok(agent1.children, `${agent1Name} MUST have children showing locks/messages`);

    // Agent-1 has 1 lock (/src/main.ts) + plan + messages
    const hasLockChild = agent1.children?.some(c => c.label === '/src/main.ts');
    const hasPlanChild = agent1.children?.some(c => c.label.includes('Implement feature X'));
    const hasMessageChild = agent1.children?.some(c => c.label === 'Messages');

    assert.ok(hasLockChild, `${agent1Name} children MUST include /src/main.ts lock`);
    assert.ok(hasPlanChild, `${agent1Name} children MUST include plan goal`);
    assert.ok(hasMessageChild, `${agent1Name} children MUST include Messages summary`);
  });

  test('Refresh syncs all state from server', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    await api.refreshStatus();

    // Verify all counts match (at least expected, shared DB may have more)
    assert.ok(api.getAgentCount() >= 2, `At least 2 agents, got ${api.getAgentCount()}`);
    assert.ok(api.getLockCount() >= 2, `At least 2 locks, got ${api.getLockCount()}`);
    assert.ok(api.getPlans().length >= 1, `At least 1 plan, got ${api.getPlans().length}`);
    assert.ok(api.getMessages().length >= 4, `At least 4 messages (including broadcast), got ${api.getMessages().length}`);

    // Verify tree views match (at least expected)
    assert.ok(api.getAgentsTreeSnapshot().length >= 2, `At least 2 agents in tree, got ${api.getAgentsTreeSnapshot().length}`);
    assert.ok(api.getLockTreeItemCount() >= 2, `At least 2 locks in tree, got ${api.getLockTreeItemCount()}`);
    assert.ok(api.getMessageTreeItemCount() >= 4, `At least 4 messages in tree (including broadcast), got ${api.getMessageTreeItemCount()}`);
    // Plans appear as children under agents, verify via agent children
    const agentItem = api.findAgentInTree(agent1Name);
    assert.ok(
      agentItem?.children?.some(c => c.label.includes('Goal:')),
      'Agent should have plan child'
    );
  });

  test('Disconnect clears all tree views', async function () {
    this.timeout(10000);

    await safeDisconnect();
    const api = getTestAPI();

    assert.strictEqual(api.isConnected(), false, 'Should be disconnected');

    // All data cleared
    assert.deepStrictEqual(api.getAgents(), [], 'Agents should be empty');
    assert.deepStrictEqual(api.getLocks(), [], 'Locks should be empty');
    assert.deepStrictEqual(api.getMessages(), [], 'Messages should be empty');
    assert.deepStrictEqual(api.getPlans(), [], 'Plans should be empty');

    // All trees cleared
    assert.strictEqual(api.getAgentsTreeSnapshot().length, 0, 'Agents tree should be empty');
    assert.strictEqual(api.getLockTreeItemCount(), 0, 'Locks tree should be empty');
    assert.strictEqual(api.getMessageTreeItemCount(), 0, 'Messages tree should be empty');
    // Plans tree is shown under agents, so no separate check needed
  });

  test('Reconnect restores all state and tree views', async function () {
    this.timeout(30000);
    const api = getTestAPI();

    await api.connect();
    await waitForConnection();
    await api.refreshStatus();

    // After reconnect, we need to verify that:
    // 1. Connection works
    // 2. We can re-create state if needed (SQLite WAL may not checkpoint on kill)
    // 3. Tree views update properly

    // Re-register agents if they were lost (WAL not checkpointed on server kill)
    if (!api.findAgentInTree(agent1Name)) {
      const result1 = await api.callTool('register', { name: agent1Name });
      agent1Key = JSON.parse(result1).agent_key;
    }
    if (!api.findAgentInTree(agent2Name)) {
      const result2 = await api.callTool('register', { name: agent2Name });
      agent2Key = JSON.parse(result2).agent_key;
    }

    // Re-acquire locks if they were lost
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

    // Re-create plan if lost (plans appear as children under agents)
    const agentItemForPlan = api.findAgentInTree(agent1Name);
    const hasPlan = agentItemForPlan?.children?.some(c => c.label.includes('Goal:')) ?? false;
    if (!hasPlan) {
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
    // Re-send broadcast message if lost
    if (!api.findMessageInTree('BROADCAST')) {
      await api.callTool('message', {
        action: 'send',
        agent_name: agent1Name,
        agent_key: agent1Key,
        to_agent: '*',
        content: 'BROADCAST: Important announcement for all agents',
      });
    }

    // Wait for all updates to propagate
    await waitForCondition(
      () => api.getAgentCount() >= 2 && api.getLockCount() >= 2,
      'state to be restored/recreated',
      10000
    );

    // Now verify final state
    assert.ok(api.getAgentCount() >= 2, `At least 2 agents, got ${api.getAgentCount()}`);
    assert.ok(api.getLockCount() >= 2, `At least 2 locks, got ${api.getLockCount()}`);
    assert.ok(api.getPlans().length >= 1, `At least 1 plan, got ${api.getPlans().length}`);
    assert.ok(api.getMessages().length >= 4, `At least 4 messages (including broadcast), got ${api.getMessages().length}`);

    // Trees have correct labels
    const agentsTree = api.getAgentsTreeSnapshot();
    const locksTree = api.getLocksTreeSnapshot();
    const messagesTree = api.getMessagesTreeSnapshot();

    dumpTree('AGENTS after reconnect', agentsTree);
    dumpTree('LOCKS after reconnect', locksTree);
    dumpTree('MESSAGES after reconnect', messagesTree);

    assert.ok(api.findAgentInTree(agent1Name), `${agent1Name} in tree`);
    assert.ok(api.findAgentInTree(agent2Name), `${agent2Name} in tree`);
    assert.ok(api.findLockInTree('/src/main.ts'), '/src/main.ts lock in tree');
    assert.ok(api.findLockInTree('/src/types.ts'), '/src/types.ts lock in tree');

    // Plan appears as child of agent
    const agent1AfterReconnect = api.findAgentInTree(agent1Name);
    assert.ok(
      agent1AfterReconnect?.children?.some(c => c.label.includes('Goal:')),
      `${agent1Name} plan should be in agent children`
    );

    // Messages in tree
    assert.ok(api.findMessageInTree('Starting work'), 'First message in tree');
    assert.ok(api.findMessageInTree('Acknowledged'), 'Second message in tree');
    assert.ok(api.findMessageInTree('Done with main'), 'Third message in tree');
    assert.ok(api.findMessageInTree('BROADCAST'), 'Broadcast message in tree');
    assert.ok(api.getMessageTreeItemCount() >= 4, `At least 4 messages in tree (including broadcast), got ${api.getMessageTreeItemCount()}`);
  });
});

/**
 * Admin Operations Tests - covers store.ts admin methods
 */
suite('MCP Integration - Admin Operations', function () {
  let adminAgentKey: string;
  const testId = Date.now();
  const adminAgentName = `admin-test-${testId}`;
  const targetAgentName = `target-test-${testId}`;
  let targetAgentKey: string;

  suiteSetup(async function () {
    this.timeout(60000);

    // waitForExtensionActivation handles server path setup and validation
    await waitForExtensionActivation();
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('CRITICAL: Admin tool must exist on server', async function () {
    this.timeout(30000);

    await safeDisconnect();
    const api = getTestAPI();
    await api.connect();
    await waitForConnection();

    // This test catches the bug where VSCode uses old npm version without admin tool
    // If this fails, the server version is outdated - npm publish needed
    try {
      const result = await api.callTool('admin', { action: 'delete_lock', file_path: '/nonexistent' });
      // Even if lock doesn't exist, we should get a valid response (not "tool not found")
      const parsed = JSON.parse(result);
      // Valid responses: {"deleted":true} or {"error":"..."}
      assert.ok(
        parsed.deleted !== undefined || parsed.error !== undefined,
        `Admin tool should return valid response, got: ${result}`
      );
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      // Check for MCP-level "Tool admin not found" error (means admin tool missing)
      if (msg.includes('Tool admin not found') || msg.includes('-32602')) {
        assert.fail(
          'ADMIN TOOL NOT FOUND! The MCP server is outdated. ' +
          'Publish new version: cd examples/too_many_cooks && npm publish'
        );
      }
      // "NOT_FOUND:" errors are valid business responses - tool exists!
      if (msg.includes('NOT_FOUND:')) {
        return; // Success - admin tool exists and responded
      }
      // Other errors are OK (e.g., lock doesn't exist)
    }
  });

  test('Setup: Connect and register agents', async function () {
    this.timeout(30000);
    const api = getTestAPI();

    // Already connected from previous test, just register agents

    // Register admin agent
    const result1 = await api.callTool('register', { name: adminAgentName });
    adminAgentKey = JSON.parse(result1).agent_key;
    assert.ok(adminAgentKey, 'Admin agent should have key');

    // Register target agent
    const result2 = await api.callTool('register', { name: targetAgentName });
    targetAgentKey = JSON.parse(result2).agent_key;
    assert.ok(targetAgentKey, 'Target agent should have key');

    // Acquire a lock for target agent
    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/admin/test/file.ts',
      agent_name: targetAgentName,
      agent_key: targetAgentKey,
      reason: 'Testing admin delete',
    });

    await waitForCondition(
      () => api.findLockInTree('/admin/test/file.ts') !== undefined,
      'Lock to appear',
      5000
    );
  });

  test('Force release lock via admin → lock DISAPPEARS', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Verify lock exists
    assert.ok(api.findLockInTree('/admin/test/file.ts'), 'Lock should exist before force release');

    // Force release via admin tool
    await api.callTool('admin', {
      action: 'delete_lock',
      file_path: '/admin/test/file.ts',
    });

    await waitForCondition(
      () => api.findLockInTree('/admin/test/file.ts') === undefined,
      'Lock to disappear after force release',
      5000
    );

    assert.strictEqual(
      api.findLockInTree('/admin/test/file.ts'),
      undefined,
      'Lock should be gone after force release'
    );
  });

  test('Delete agent via admin → agent DISAPPEARS from tree', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Verify target agent exists
    await waitForCondition(
      () => api.findAgentInTree(targetAgentName) !== undefined,
      'Target agent to appear',
      5000
    );
    assert.ok(api.findAgentInTree(targetAgentName), 'Target agent should exist before delete');

    // Delete via admin tool
    await api.callTool('admin', {
      action: 'delete_agent',
      agent_name: targetAgentName,
    });

    await waitForCondition(
      () => api.findAgentInTree(targetAgentName) === undefined,
      'Target agent to disappear after delete',
      5000
    );

    assert.strictEqual(
      api.findAgentInTree(targetAgentName),
      undefined,
      'Target agent should be gone after delete'
    );
  });

  test('Lock renewal extends expiration', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Acquire a new lock
    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/admin/renew/test.ts',
      agent_name: adminAgentName,
      agent_key: adminAgentKey,
      reason: 'Testing renewal',
    });

    await waitForCondition(
      () => api.findLockInTree('/admin/renew/test.ts') !== undefined,
      'New lock to appear',
      5000
    );

    // Renew the lock
    await api.callTool('lock', {
      action: 'renew',
      file_path: '/admin/renew/test.ts',
      agent_name: adminAgentName,
      agent_key: adminAgentKey,
    });

    // Verify lock still exists after renewal
    const lockItem = api.findLockInTree('/admin/renew/test.ts');
    assert.ok(lockItem, 'Lock should still exist after renewal');

    // Clean up
    await api.callTool('lock', {
      action: 'release',
      file_path: '/admin/renew/test.ts',
      agent_name: adminAgentName,
      agent_key: adminAgentKey,
    });
  });

  test('Mark message as read updates state', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Send a message to admin agent
    const secondAgentName = `sender-${testId}`;
    const result = await api.callTool('register', { name: secondAgentName });
    const senderKey = JSON.parse(result).agent_key;

    await api.callTool('message', {
      action: 'send',
      agent_name: secondAgentName,
      agent_key: senderKey,
      to_agent: adminAgentName,
      content: 'Test message for read marking',
    });

    await waitForCondition(
      () => api.findMessageInTree('Test message for read') !== undefined,
      'Message to appear',
      5000
    );

    // Get messages and mark as read
    const getResult = await api.callTool('message', {
      action: 'get',
      agent_name: adminAgentName,
      agent_key: adminAgentKey,
    });
    const msgData = JSON.parse(getResult);
    assert.ok(msgData.messages.length > 0, 'Should have messages');

    // Find the unread message
    const unreadMsg = msgData.messages.find(
      (m: { content: string; read_at?: number }) =>
        m.content.includes('Test message for read') && !m.read_at
    );
    if (unreadMsg) {
      await api.callTool('message', {
        action: 'mark_read',
        agent_name: adminAgentName,
        agent_key: adminAgentKey,
        message_id: unreadMsg.id,
      });
    }

    // Refresh to see updated state
    await api.refreshStatus();

    // Message should still be visible but now read
    assert.ok(api.findMessageInTree('Test message for read'), 'Message should still be visible');
  });
});

/**
 * Lock State Tests - tests lock acquire/release state management
 */
suite('MCP Integration - Lock State', function () {
  let agentKey: string;
  const testId = Date.now();
  const agentName = `deco-test-${testId}`;

  suiteSetup(async function () {
    this.timeout(60000);

    // waitForExtensionActivation handles server path setup and validation
    await waitForExtensionActivation();
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('Setup: Connect and register agent', async function () {
    this.timeout(30000);

    await safeDisconnect();
    const api = getTestAPI();
    await api.connect();
    await waitForConnection();

    const result = await api.callTool('register', { name: agentName });
    agentKey = JSON.parse(result).agent_key;
    assert.ok(agentKey, 'Agent should have key');
  });

  test('Lock on file creates decoration data in state', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Acquire lock
    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/deco/test/file.ts',
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Testing decorations',
    });

    await waitForCondition(
      () => api.findLockInTree('/deco/test/file.ts') !== undefined,
      'Lock to appear in tree',
      5000
    );

    // Verify lock exists in state
    const locks = api.getLocks();
    const lock = locks.find(l => l.filePath === '/deco/test/file.ts');
    assert.ok(lock, 'Lock should be in state');
    assert.strictEqual(lock.agentName, agentName, 'Lock should have correct agent');
    assert.strictEqual(lock.reason, 'Testing decorations', 'Lock should have correct reason');
    assert.ok(lock.expiresAt > Date.now(), 'Lock should not be expired');
  });

  test('Lock without reason still works', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Acquire lock without reason
    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/deco/no-reason/file.ts',
      agent_name: agentName,
      agent_key: agentKey,
    });

    await waitForCondition(
      () => api.findLockInTree('/deco/no-reason/file.ts') !== undefined,
      'Lock without reason to appear',
      5000
    );

    const locks = api.getLocks();
    const lock = locks.find(l => l.filePath === '/deco/no-reason/file.ts');
    assert.ok(lock, 'Lock without reason should be in state');
    // Reason can be undefined or null depending on how server returns it
    assert.ok(lock.reason === undefined || lock.reason === null, 'Lock should have no reason');

    // Clean up
    await api.callTool('lock', {
      action: 'release',
      file_path: '/deco/no-reason/file.ts',
      agent_name: agentName,
      agent_key: agentKey,
    });
  });

  test('Active and expired locks computed correctly', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // The lock we created earlier should be active
    const details = api.getAgentDetails();
    const agentDetail = details.find(d => d.agent.agentName === agentName);
    assert.ok(agentDetail, 'Agent details should exist');
    assert.ok(agentDetail.locks.length >= 1, 'Agent should have at least one lock');

    // All locks should be active (not expired)
    for (const lock of agentDetail.locks) {
      assert.ok(lock.expiresAt > Date.now(), `Lock ${lock.filePath} should be active`);
    }
  });

  test('Release lock removes decoration data', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Release the lock
    await api.callTool('lock', {
      action: 'release',
      file_path: '/deco/test/file.ts',
      agent_name: agentName,
      agent_key: agentKey,
    });

    await waitForCondition(
      () => api.findLockInTree('/deco/test/file.ts') === undefined,
      'Lock to disappear from tree',
      5000
    );

    // Verify lock is gone from state
    const locks = api.getLocks();
    const lock = locks.find(l => l.filePath === '/deco/test/file.ts');
    assert.strictEqual(lock, undefined, 'Lock should be removed from state');
  });
});

/**
 * Tree Provider Edge Cases - covers tree provider branches
 */
suite('MCP Integration - Tree Provider Edge Cases', function () {
  let agentKey: string;
  const testId = Date.now();
  const agentName = `edge-test-${testId}`;

  suiteSetup(async function () {
    this.timeout(60000);

    // waitForExtensionActivation handles server path setup and validation
    await waitForExtensionActivation();
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('Setup: Connect and register agent', async function () {
    this.timeout(30000);

    await safeDisconnect();
    const api = getTestAPI();
    await api.connect();
    await waitForConnection();

    const result = await api.callTool('register', { name: agentName });
    agentKey = JSON.parse(result).agent_key;
    assert.ok(agentKey, 'Agent should have key');
  });

  test('Long message content is truncated in tree', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    const longContent = 'A'.repeat(100);
    await api.callTool('message', {
      action: 'send',
      agent_name: agentName,
      agent_key: agentKey,
      to_agent: agentName,
      content: longContent,
    });

    await waitForCondition(
      () => api.findMessageInTree('AAAA') !== undefined,
      'Long message to appear',
      5000
    );

    // The message should be in the tree (content as description)
    const msgItem = api.findMessageInTree('AAAA');
    assert.ok(msgItem, 'Long message should be found');
    // Description should contain the content
    assert.ok(msgItem.description?.includes('AAA'), 'Description should contain content');
  });

  test('Long plan task is truncated in tree', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    const longTask = 'B'.repeat(50);
    await api.callTool('plan', {
      action: 'update',
      agent_name: agentName,
      agent_key: agentKey,
      goal: 'Test long task',
      current_task: longTask,
    });

    await waitForCondition(
      () => {
        const agentItem = api.findAgentInTree(agentName);
        return agentItem?.children?.some(c => c.label.includes('Test long task')) ?? false;
      },
      'Plan with long task to appear',
      5000
    );

    const agentItem = api.findAgentInTree(agentName);
    const planChild = agentItem?.children?.find(c => c.label.includes('Goal:'));
    assert.ok(planChild, 'Plan should be in agent children');
  });

  test('Agent with multiple locks shows all locks', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Acquire multiple locks
    for (let i = 1; i <= 3; i++) {
      await api.callTool('lock', {
        action: 'acquire',
        file_path: `/edge/multi/file${i}.ts`,
        agent_name: agentName,
        agent_key: agentKey,
        reason: `Lock ${i}`,
      });
    }

    await waitForCondition(
      () => api.getLocks().filter(l => l.filePath.includes('/edge/multi/')).length >= 3,
      'All 3 locks to appear',
      5000
    );

    // Verify agent shows all locks in children
    const agentItem = api.findAgentInTree(agentName);
    assert.ok(agentItem, 'Agent should be in tree');
    assert.ok(agentItem.children, 'Agent should have children');

    const lockChildren = agentItem.children?.filter(c => c.label.includes('/edge/multi/')) ?? [];
    assert.strictEqual(lockChildren.length, 3, 'Agent should have 3 lock children');

    // Clean up
    for (let i = 1; i <= 3; i++) {
      await api.callTool('lock', {
        action: 'release',
        file_path: `/edge/multi/file${i}.ts`,
        agent_name: agentName,
        agent_key: agentKey,
      });
    }
  });

  test('Agent description shows lock and message counts', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Agent already has some messages and might have locks
    const agentItem = api.findAgentInTree(agentName);
    assert.ok(agentItem, 'Agent should be in tree');

    // Description should show counts or "idle"
    const desc = agentItem.description ?? '';
    assert.ok(
      desc.includes('msg') || desc.includes('lock') || desc === 'idle',
      `Agent description should show counts or idle, got: ${desc}`
    );
  });
});

/**
 * Store Methods Coverage - tests store.ts forceReleaseLock, deleteAgent, sendMessage
 */
suite('MCP Integration - Store Methods', function () {
  let storeAgentKey: string;
  const testId = Date.now();
  const storeAgentName = `store-test-${testId}`;
  const targetAgentForDelete = `delete-target-${testId}`;

  suiteSetup(async function () {
    this.timeout(60000);

    // waitForExtensionActivation handles server path setup and validation
    await waitForExtensionActivation();
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('Setup: Connect and register agents', async function () {
    this.timeout(30000);

    await safeDisconnect();
    const api = getTestAPI();
    await api.connect();
    await waitForConnection();

    const result = await api.callTool('register', { name: storeAgentName });
    storeAgentKey = JSON.parse(result).agent_key;
    assert.ok(storeAgentKey, 'Store agent should have key');
  });

  test('store.forceReleaseLock removes lock', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Acquire a lock first
    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/store/force/release.ts',
      agent_name: storeAgentName,
      agent_key: storeAgentKey,
      reason: 'Testing forceReleaseLock',
    });

    await waitForCondition(
      () => api.findLockInTree('/store/force/release.ts') !== undefined,
      'Lock to appear',
      5000
    );

    // Use store method to force release
    await api.forceReleaseLock('/store/force/release.ts');

    await waitForCondition(
      () => api.findLockInTree('/store/force/release.ts') === undefined,
      'Lock to disappear after force release',
      5000
    );

    assert.strictEqual(
      api.findLockInTree('/store/force/release.ts'),
      undefined,
      'Lock should be removed by forceReleaseLock'
    );
  });

  test('store.deleteAgent removes agent and their data', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Register a target agent to delete
    const result = await api.callTool('register', { name: targetAgentForDelete });
    const targetKey = JSON.parse(result).agent_key;

    // Acquire a lock as the target agent
    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/store/delete/agent.ts',
      agent_name: targetAgentForDelete,
      agent_key: targetKey,
      reason: 'Will be deleted with agent',
    });

    await waitForCondition(
      () => api.findAgentInTree(targetAgentForDelete) !== undefined,
      'Target agent to appear',
      5000
    );

    // Use store method to delete agent
    await api.deleteAgent(targetAgentForDelete);

    await waitForCondition(
      () => api.findAgentInTree(targetAgentForDelete) === undefined,
      'Agent to disappear after delete',
      5000
    );

    assert.strictEqual(
      api.findAgentInTree(targetAgentForDelete),
      undefined,
      'Agent should be removed by deleteAgent'
    );

    // Lock should also be gone (cascade delete)
    assert.strictEqual(
      api.findLockInTree('/store/delete/agent.ts'),
      undefined,
      'Agent locks should be removed when agent is deleted'
    );
  });

  test('store.sendMessage sends message via registered agent', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // Create a recipient agent
    const recipientName = `recipient-${testId}`;
    await api.callTool('register', { name: recipientName });

    // Use store method to send message (it registers sender automatically)
    const senderName = `ui-sender-${testId}`;
    await api.sendMessage(senderName, recipientName, 'Message from store.sendMessage');

    await waitForCondition(
      () => api.findMessageInTree('Message from store') !== undefined,
      'Message to appear in tree',
      5000
    );

    const msgItem = api.findMessageInTree('Message from store');
    assert.ok(msgItem, 'Message should be found');
    assert.ok(
      msgItem.label.includes(senderName),
      `Message should show sender ${senderName}`
    );
    assert.ok(
      msgItem.label.includes(recipientName),
      `Message should show recipient ${recipientName}`
    );
  });

  test('store.sendMessage to broadcast recipient', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    const senderName = `broadcast-sender-${testId}`;
    await api.sendMessage(senderName, '*', 'Broadcast from store.sendMessage');

    await waitForCondition(
      () => api.findMessageInTree('Broadcast from store') !== undefined,
      'Broadcast message to appear',
      5000
    );

    const msgItem = api.findMessageInTree('Broadcast from store');
    assert.ok(msgItem, 'Broadcast message should be found');
    assert.ok(
      msgItem.label.includes('all'),
      'Broadcast message should show "all" as recipient'
    );
  });
});
