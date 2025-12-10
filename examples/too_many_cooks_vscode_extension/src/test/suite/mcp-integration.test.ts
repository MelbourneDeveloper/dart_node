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
import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import {
  waitForExtensionActivation,
  waitForConnection,
  waitForCondition,
  getTestAPI,
} from '../test-helpers';
import type { TreeItemSnapshot } from '../../test-api';

const SERVER_PATH = path.resolve(
  __dirname,
  '../../../../too_many_cooks/build/bin/server_node.js'
);

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

    if (!fs.existsSync(SERVER_PATH)) {
      throw new Error(
        `MCP SERVER NOT FOUND AT ${SERVER_PATH}\n` +
          'Build it first: cd examples/too_many_cooks && ./build.sh'
      );
    }

    await waitForExtensionActivation();

    const config = vscode.workspace.getConfiguration('tooManyCooks');
    await config.update(
      'serverPath',
      SERVER_PATH,
      vscode.ConfigurationTarget.Global
    );

    // Clean DB for fresh state - uses shared db in home directory
    const homeDir = process.env.HOME ?? '/tmp';
    const dbDir = path.join(homeDir, '.too_many_cooks');
    for (const f of ['data.db', 'data.db-wal', 'data.db-shm']) {
      try {
        fs.unlinkSync(path.join(dbDir, f));
      } catch {
        /* ignore */
      }
    }
  });

  suiteTeardown(async () => {
    await getTestAPI().disconnect();
  });

  test('Connect to MCP server', async function () {
    this.timeout(30000);
    const api = getTestAPI();

    await api.disconnect();
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
    const plansTree = api.getPlansTreeSnapshot();

    dumpTree('AGENTS', agentsTree);
    dumpTree('LOCKS', locksTree);
    dumpTree('MESSAGES', messagesTree);
    dumpTree('PLANS', plansTree);

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
    assert.strictEqual(
      plansTree.some(item => item.label === 'No plans'),
      true,
      'Plans tree should show "No plans"'
    );
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

  test('Update plan for agent-1 → plan content APPEARS in tree', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    await api.callTool('plan', {
      action: 'update',
      agent_name: agent1Name,
      agent_key: agent1Key,
      goal: 'Implement feature X',
      current_task: 'Writing tests',
    });

    await waitForCondition(
      () => api.findPlanInTree(agent1Name) !== undefined,
      `${agent1Name} plan to appear in tree`,
      5000
    );

    const tree = api.getPlansTreeSnapshot();
    dumpTree('PLANS after update', tree);

    // PROOF: Plan appears with correct content
    const planItem = api.findPlanInTree(agent1Name);
    assert.ok(planItem, `${agent1Name} plan MUST appear in tree`);
    assert.strictEqual(planItem.label, agent1Name, 'Plan label should be agent name');
    // Description should contain current task
    assert.ok(
      planItem.description?.includes('Writing tests'),
      `Description should contain current task, got: ${planItem.description}`
    );

    // Children should show goal and task
    assert.ok(planItem.children, 'Plan should have children');
    const goalChild = planItem.children?.find(c => c.label.includes('Implement feature X'));
    const taskChild = planItem.children?.find(c => c.label.includes('Writing tests'));
    assert.ok(goalChild, 'Goal "Implement feature X" MUST appear in children');
    assert.ok(taskChild, 'Task "Writing tests" MUST appear in children');
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

  test('Agent tree shows locks/messages for each agent', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    const tree = api.getAgentsTreeSnapshot();
    dumpTree('AGENTS with children', tree);

    // Find agent-1 and check its children
    const agent1 = api.findAgentInTree('agent-1');
    assert.ok(agent1, 'agent-1 MUST be in tree');
    assert.ok(agent1.children, 'agent-1 MUST have children showing locks/messages');

    // Agent-1 has 1 lock (/src/main.ts) + plan + messages
    const hasLockChild = agent1.children?.some(c => c.label === '/src/main.ts');
    const hasPlanChild = agent1.children?.some(c => c.label.includes('Implement feature X'));
    const hasMessageChild = agent1.children?.some(c => c.label === 'Messages');

    assert.ok(hasLockChild, 'agent-1 children MUST include /src/main.ts lock');
    assert.ok(hasPlanChild, 'agent-1 children MUST include plan goal');
    assert.ok(hasMessageChild, 'agent-1 children MUST include Messages summary');
  });

  test('Refresh syncs all state from server', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    await api.refreshStatus();

    // Verify all counts match
    assert.strictEqual(api.getAgentCount(), 2, '2 agents');
    assert.strictEqual(api.getLockCount(), 2, '2 locks');
    assert.strictEqual(api.getPlans().length, 1, '1 plan');
    assert.strictEqual(api.getMessages().length, 3, '3 messages');

    // Verify tree views match
    assert.strictEqual(api.getAgentsTreeSnapshot().length, 2, '2 agents in tree');
    assert.strictEqual(api.getLockTreeItemCount(), 2, '2 locks in tree');
    assert.strictEqual(api.getPlanTreeItemCount(), 1, '1 plan in tree');
    assert.strictEqual(api.getMessageTreeItemCount(), 3, '3 messages in tree');
  });

  test('Disconnect clears all tree views', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    await api.disconnect();

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
    assert.strictEqual(api.getPlanTreeItemCount(), 0, 'Plans tree should be empty');
  });

  test('Reconnect restores all state and tree views', async function () {
    this.timeout(30000);
    const api = getTestAPI();

    await api.connect();
    await waitForConnection();
    await api.refreshStatus();

    // Data restored - INCLUDING MESSAGES!
    assert.strictEqual(api.getAgentCount(), 2, '2 agents restored');
    assert.strictEqual(api.getLockCount(), 2, '2 locks restored');
    assert.strictEqual(api.getPlans().length, 1, '1 plan restored');
    assert.strictEqual(api.getMessages().length, 3, '3 messages restored');

    // Trees restored with correct labels
    const agentsTree = api.getAgentsTreeSnapshot();
    const locksTree = api.getLocksTreeSnapshot();
    const plansTree = api.getPlansTreeSnapshot();
    const messagesTree = api.getMessagesTreeSnapshot();

    dumpTree('AGENTS after reconnect', agentsTree);
    dumpTree('LOCKS after reconnect', locksTree);
    dumpTree('PLANS after reconnect', plansTree);
    dumpTree('MESSAGES after reconnect', messagesTree);

    assert.ok(api.findAgentInTree('agent-1'), 'agent-1 restored in tree');
    assert.ok(api.findAgentInTree('agent-2'), 'agent-2 restored in tree');
    assert.ok(api.findLockInTree('/src/main.ts'), '/src/main.ts lock restored in tree');
    assert.ok(api.findLockInTree('/src/types.ts'), '/src/types.ts lock restored in tree');
    assert.ok(api.findPlanInTree('agent-1'), 'agent-1 plan restored in tree');

    // CRITICAL: Messages MUST be restored after reconnect!
    assert.ok(api.findMessageInTree('Starting work'), 'First message restored in tree');
    assert.ok(api.findMessageInTree('Acknowledged'), 'Second message restored in tree');
    assert.ok(api.findMessageInTree('Done with main'), 'Third message restored in tree');
    assert.strictEqual(api.getMessageTreeItemCount(), 3, '3 messages in tree after reconnect');
  });
});
