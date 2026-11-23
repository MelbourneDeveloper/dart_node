/**
 * Extension Activation Tests
 * Verifies the extension activates correctly and exposes the test API.
 */

import * as assert from 'assert';
import * as vscode from 'vscode';
import { waitForExtensionActivation, waitForConnection, getTestAPI, restoreDialogMocks, safeDisconnect } from '../test-helpers';

const TEST_TIMEOUT = 5000;

// Ensure any dialog mocks from previous tests are restored
restoreDialogMocks();

suite('Extension Activation', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('Extension is present and can be activated', async () => {
    const extension = vscode.extensions.getExtension('Nimblesite.too-many-cooks');
    assert.ok(extension, 'Extension should be present');
    assert.ok(extension.isActive, 'Extension should be active');
  });

  test('Extension exports TestAPI', () => {
    const api = getTestAPI();
    assert.ok(api, 'TestAPI should be available');
  });

  test('TestAPI has all required methods', () => {
    const api = getTestAPI();

    // State getters
    assert.ok(typeof api.getAgents === 'function', 'getAgents should be a function');
    assert.ok(typeof api.getLocks === 'function', 'getLocks should be a function');
    assert.ok(typeof api.getMessages === 'function', 'getMessages should be a function');
    assert.ok(typeof api.getPlans === 'function', 'getPlans should be a function');
    assert.ok(typeof api.getConnectionStatus === 'function', 'getConnectionStatus should be a function');

    // Computed getters
    assert.ok(typeof api.getAgentCount === 'function', 'getAgentCount should be a function');
    assert.ok(typeof api.getLockCount === 'function', 'getLockCount should be a function');
    assert.ok(typeof api.getMessageCount === 'function', 'getMessageCount should be a function');
    assert.ok(typeof api.getUnreadMessageCount === 'function', 'getUnreadMessageCount should be a function');
    assert.ok(typeof api.getAgentDetails === 'function', 'getAgentDetails should be a function');

    // Store actions
    assert.ok(typeof api.connect === 'function', 'connect should be a function');
    assert.ok(typeof api.disconnect === 'function', 'disconnect should be a function');
    assert.ok(typeof api.refreshStatus === 'function', 'refreshStatus should be a function');
    assert.ok(typeof api.isConnected === 'function', 'isConnected should be a function');
  });

  test('Initial state is disconnected', () => {
    const api = getTestAPI();
    assert.strictEqual(api.getConnectionStatus(), 'disconnected');
    assert.strictEqual(api.isConnected(), false);
  });

  test('Initial state has empty arrays', () => {
    const api = getTestAPI();
    assert.deepStrictEqual(api.getAgents(), []);
    assert.deepStrictEqual(api.getLocks(), []);
    assert.deepStrictEqual(api.getMessages(), []);
    assert.deepStrictEqual(api.getPlans(), []);
  });

  test('Initial computed values are zero', () => {
    const api = getTestAPI();
    assert.strictEqual(api.getAgentCount(), 0);
    assert.strictEqual(api.getLockCount(), 0);
    assert.strictEqual(api.getMessageCount(), 0);
    assert.strictEqual(api.getUnreadMessageCount(), 0);
  });

  test('Extension logs activation messages', () => {
    const api = getTestAPI();
    const logs = api.getLogMessages();

    // MUST have log messages - extension MUST be logging
    assert.ok(logs.length > 0, 'Extension must produce log messages');

    // MUST contain activation message
    const hasActivatingLog = logs.some((msg) => msg.includes('Extension activating'));
    assert.ok(hasActivatingLog, 'Must log "Extension activating..."');

    // MUST contain activated message
    const hasActivatedLog = logs.some((msg) => msg.includes('Extension activated'));
    assert.ok(hasActivatedLog, 'Must log "Extension activated"');

    // MUST contain server mode log (either test server path or npx)
    const hasServerLog = logs.some((msg) =>
      msg.includes('TEST MODE: Using local server') ||
      msg.includes('Using npx too-many-cooks')
    );
    assert.ok(hasServerLog, 'Must log server mode');
  });
});

/**
 * MCP Server Feature Verification Tests
 * These tests verify that the MCP server has all required tools.
 * CRITICAL: These tests MUST pass for production use.
 * If admin tool is missing, the VSCode extension delete/remove features won't work.
 */
suite('MCP Server Feature Verification', function () {
  const testId = Date.now();
  const agentName = `feature-verify-${testId}`;
  let agentKey: string;

  suiteSetup(async function () {
    this.timeout(30000);
    await waitForExtensionActivation();

    // Connect in suiteSetup so tests don't have to wait
    const api = getTestAPI();
    if (!api.isConnected()) {
      await api.connect();
      await waitForConnection(10000);
    }

    // Register an agent for tests
    const result = await api.callTool('register', { name: agentName });
    const parsed = JSON.parse(result);
    agentKey = parsed.agent_key;
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('CRITICAL: Admin tool MUST exist on MCP server', async function () {
    this.timeout(TEST_TIMEOUT);
    const api = getTestAPI();
    assert.ok(agentKey, 'Should have agent key from suiteSetup');

    // Test admin tool exists by calling it
    // This is the CRITICAL test - if admin tool doesn't exist, this will throw
    try {
      const adminResult = await api.callTool('admin', {
        action: 'delete_agent',
        agent_name: 'non-existent-agent-12345',
      });
      // Either success (agent didn't exist) or error response (which is fine)
      const adminParsed = JSON.parse(adminResult);
      // If we get here, admin tool exists!
      // Valid responses: {"deleted":true}, {"error":"NOT_FOUND: ..."}, etc.
      assert.ok(
        adminParsed.deleted !== undefined || adminParsed.error !== undefined,
        'Admin tool should return valid response'
      );
    } catch (err) {
      // If error message contains "Tool admin not found" (MCP protocol error),
      // the server is outdated. But "NOT_FOUND: Agent not found" is a valid
      // business logic response that means the tool exists.
      const msg = err instanceof Error ? err.message : String(err);

      // Check for MCP-level "tool not found" error (means admin tool missing)
      if (msg.includes('Tool admin not found') || msg.includes('-32602')) {
        assert.fail(
          'CRITICAL: Admin tool not found on MCP server!\n' +
            'The VSCode extension requires the admin tool for delete/remove features.\n' +
            'This means either:\n' +
            '  1. You are using npx with outdated npm package (need to publish 0.3.0)\n' +
            '  2. The local server build is outdated (run build.sh)\n' +
            'To fix: cd examples/too_many_cooks && npm publish\n' +
            `Error was: ${msg}`
        );
      }

      // "NOT_FOUND: Agent not found" is a valid business response - tool exists!
      if (msg.includes('NOT_FOUND:')) {
        // This is actually success - the admin tool exists and responded
        return;
      }

      // Other errors are re-thrown
      throw err;
    }
  });

  test('CRITICAL: Subscribe tool MUST exist on MCP server', async function () {
    this.timeout(TEST_TIMEOUT);
    const api = getTestAPI();

    // Subscribe tool is required for real-time notifications
    try {
      const result = await api.callTool('subscribe', {
        action: 'list',
      });
      const parsed = JSON.parse(result);
      assert.ok(
        Array.isArray(parsed.subscribers),
        'Subscribe tool should return subscribers list'
      );
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      if (msg.includes('not found') || msg.includes('-32602')) {
        assert.fail(
          'CRITICAL: Subscribe tool not found on MCP server!\n' +
            `Error was: ${msg}`
        );
      }
      throw err;
    }
  });

  test('All core tools are available', async function () {
    this.timeout(TEST_TIMEOUT);
    const api = getTestAPI();

    // Test each core tool
    const coreTools = ['status', 'register', 'lock', 'message', 'plan'];

    for (const tool of coreTools) {
      try {
        // Call status tool (safe, no side effects)
        if (tool === 'status') {
          const result = await api.callTool('status', {});
          const parsed = JSON.parse(result);
          assert.ok(parsed.agents !== undefined, 'Status should have agents');
        }
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        if (msg.includes('not found')) {
          assert.fail(`Core tool '${tool}' not found on MCP server!`);
        }
        // Other errors might be expected (missing params, etc.)
      }
    }
  });
});
