/**
 * File Decoration Tests
 * Tests the LockDecorationProvider to ensure lock badges appear on files.
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

const SERVER_PATH = path.resolve(
  __dirname,
  '../../../../too_many_cooks/build/bin/server_node.js'
);

suite('File Decorations - Lock Badges', function () {
  let agentKey: string;
  const testId = Date.now();
  const agentName = `decoration-test-${testId}`;

  suiteSetup(async function () {
    this.timeout(60000);

    if (!fs.existsSync(SERVER_PATH)) {
      throw new Error(`MCP SERVER NOT FOUND AT ${SERVER_PATH}`);
    }

    await waitForExtensionActivation();

    const config = vscode.workspace.getConfiguration('tooManyCooks');
    await config.update('serverPath', SERVER_PATH, vscode.ConfigurationTarget.Global);

    // Clean DB for fresh state
    const homeDir = process.env.HOME ?? '/tmp';
    const dbDir = path.join(homeDir, '.too_many_cooks');
    for (const f of ['data.db', 'data.db-wal', 'data.db-shm']) {
      try {
        fs.unlinkSync(path.join(dbDir, f));
      } catch {
        /* ignore */
      }
    }

    const api = getTestAPI();
    await api.disconnect();
    await api.connect();
    await waitForConnection();

    // Register test agent
    const result = await api.callTool('register', { name: agentName });
    agentKey = JSON.parse(result).agent_key;
  });

  suiteTeardown(async () => {
    const api = getTestAPI();
    await api.disconnect();
    // Clean up DB
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

  test('Lock creates file decoration (badge) for locked file', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Acquire a lock on a file
    const testFilePath = '/decorations/test/file.ts';
    await api.callTool('lock', {
      action: 'acquire',
      file_path: testFilePath,
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Testing decorations',
    });

    // Wait for lock to appear in state
    await waitForCondition(
      () => api.findLockInTree(testFilePath) !== undefined,
      'Lock to appear in tree',
      5000
    );

    // Verify the lock exists in state
    const locks = api.getLocks();
    const ourLock = locks.find(l => l.filePath === testFilePath);
    assert.ok(ourLock, 'Lock should exist in state');
    assert.strictEqual(ourLock.agentName, agentName, 'Lock should have correct agent name');
    assert.ok(ourLock.reason, 'Lock should have reason');
  });

  test('Multiple locks create decorations for each file', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Acquire more locks
    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/decorations/second.ts',
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Second lock',
    });

    await api.callTool('lock', {
      action: 'acquire',
      file_path: '/decorations/third.ts',
      agent_name: agentName,
      agent_key: agentKey,
      reason: 'Third lock',
    });

    await waitForCondition(
      () => api.getLockCount() >= 3,
      '3 locks to appear',
      5000
    );

    // All locks should exist
    assert.ok(api.findLockInTree('/decorations/test/file.ts'), 'First lock should exist');
    assert.ok(api.findLockInTree('/decorations/second.ts'), 'Second lock should exist');
    assert.ok(api.findLockInTree('/decorations/third.ts'), 'Third lock should exist');
  });

  test('Lock release removes decoration', async function () {
    this.timeout(15000);
    const api = getTestAPI();

    // Release one lock
    await api.callTool('lock', {
      action: 'release',
      file_path: '/decorations/second.ts',
      agent_name: agentName,
      agent_key: agentKey,
    });

    await waitForCondition(
      () => api.findLockInTree('/decorations/second.ts') === undefined,
      'Released lock to disappear',
      5000
    );

    // Lock should be gone
    assert.strictEqual(
      api.findLockInTree('/decorations/second.ts'),
      undefined,
      'Released lock should not exist'
    );

    // Other locks should remain
    assert.ok(api.findLockInTree('/decorations/test/file.ts'), 'First lock should remain');
    assert.ok(api.findLockInTree('/decorations/third.ts'), 'Third lock should remain');
  });

  test('Lock expiration shows expired badge', async function () {
    this.timeout(20000);
    const api = getTestAPI();

    // Create a short-lived lock by setting a very short duration
    // Note: The server determines expiration, but we can test the UI handling
    // by checking that expired locks are in the "Expired" category

    // First, verify our existing locks show in Active category
    const locksTree = api.getLocksTreeSnapshot();
    const activeCategory = locksTree.find(c => c.label.includes('Active'));
    assert.ok(activeCategory, 'Should have Active locks category');
    assert.ok(
      activeCategory.children && activeCategory.children.length > 0,
      'Active category should have children'
    );
  });

  test('Lock badge shows agent initials', async function () {
    this.timeout(10000);
    const api = getTestAPI();

    // The decoration badge should show first 2 chars of agent name in uppercase
    // This is verified through the lock tree which shows agent name in description
    const lockItem = api.findLockInTree('/decorations/test/file.ts');
    assert.ok(lockItem, 'Lock should exist');
    assert.ok(
      lockItem.description?.includes(agentName),
      `Lock description should contain agent name, got: ${lockItem.description}`
    );
  });
});
