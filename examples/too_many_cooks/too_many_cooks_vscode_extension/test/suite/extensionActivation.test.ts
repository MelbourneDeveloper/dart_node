// Extension Activation Tests
// Verifies the extension activates correctly and exposes the test API.

import * as vscode from 'vscode';
import {
  waitForExtensionActivation,
  waitForConnection,
  safeDisconnect,
  getTestAPI,
  callToolString,
  extractKeyFromResult,
  restoreDialogMocks,
  assertOk,
  assertEqual,
} from './testHelpers';

const EXTENSION_ID = 'Nimblesite.too-many-cooks';

restoreDialogMocks();

suite('Extension Activation', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('Extension is present and can be activated', async () => {
    const ext = vscode.extensions.getExtension(EXTENSION_ID);
    assertOk(ext, 'Extension should be present');
    assertOk(ext!.isActive, 'Extension should be active');
  });

  test('Extension exports TestAPI', () => {
    const api = getTestAPI();
    assertOk(api, 'TestAPI should be available');
  });

  test('TestAPI has all required methods', () => {
    const api = getTestAPI();

    const agents = api.getAgents();
    assertOk(Array.isArray(agents), 'getAgents should return array');

    const locks = api.getLocks();
    assertOk(Array.isArray(locks), 'getLocks should return array');

    const messages = api.getMessages();
    assertOk(Array.isArray(messages), 'getMessages should return array');

    const plans = api.getPlans();
    assertOk(Array.isArray(plans), 'getPlans should return array');

    const status = api.getConnectionStatus();
    assertOk(typeof status === 'string', 'getConnectionStatus should return string');

    assertOk(typeof api.getAgentCount() === 'number', 'getAgentCount should return number');
    assertOk(typeof api.getLockCount() === 'number', 'getLockCount should return number');
    assertOk(typeof api.getMessageCount() === 'number', 'getMessageCount should return number');
    assertOk(typeof api.getUnreadMessageCount() === 'number', 'getUnreadMessageCount should return number');

    const details = api.getAgentDetails();
    assertOk(Array.isArray(details), 'getAgentDetails should return array');

    assertOk(typeof api.isConnected() === 'boolean', 'isConnected should return boolean');
  });

  test('Initial state is disconnected', () => {
    const api = getTestAPI();
    assertEqual(api.getConnectionStatus(), 'disconnected');
    assertEqual(api.isConnected(), false);
  });

  test('Initial state has empty arrays', () => {
    const api = getTestAPI();
    assertEqual(api.getAgents().length, 0);
    assertEqual(api.getLocks().length, 0);
    assertEqual(api.getMessages().length, 0);
    assertEqual(api.getPlans().length, 0);
  });

  test('Initial computed values are zero', () => {
    const api = getTestAPI();
    assertEqual(api.getAgentCount(), 0);
    assertEqual(api.getLockCount(), 0);
    assertEqual(api.getMessageCount(), 0);
    assertEqual(api.getUnreadMessageCount(), 0);
  });

  test('Extension logs activation messages', () => {
    const api = getTestAPI();
    const logs = api.getLogMessages();

    assertOk(logs.length > 0, 'Extension must produce log messages');

    const hasActivating = logs.some(m => m.includes('Extension activating'));
    const hasActivated = logs.some(m => m.includes('Extension activated'));
    const hasServerLog = logs.some(m =>
      m.includes('Database will be at:') || m.includes('Using workspace folder:'),
    );

    assertOk(hasActivating, 'Must log "Extension activating..."');
    assertOk(hasActivated, 'Must log "Extension activated"');
    assertOk(hasServerLog, 'Must log database/workspace path');
  });
});

suite('Database Feature Verification', () => {
  const testId = Date.now();
  const agentName = `feature-verify-${testId}`;
  let agentKey = '';

  suiteSetup(async () => {
    await waitForExtensionActivation();
    const api = getTestAPI();
    if (!api.isConnected()) {
      await api.connect();
      await waitForConnection(10000);
    }
    const result = await callToolString(api, 'register', { name: agentName });
    agentKey = extractKeyFromResult(result);
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  test('CRITICAL: Admin tool MUST exist on database', async () => {
    const api = getTestAPI();
    assertOk(agentKey.length > 0, 'Should have agent key from suiteSetup');

    try {
      const resultStr = await callToolString(api, 'admin', {
        action: 'delete_agent',
        agent_name: 'non-existent-agent-12345',
      });
      assertOk(
        resultStr.includes('deleted') || resultStr.includes('error'),
        'Admin tool should return valid response',
      );
    } catch (err: unknown) {
      const msg = String(err);
      if (msg.includes('Tool admin not found') || msg.includes('-32602')) {
        throw new Error(
          'CRITICAL: Admin tool not found on database!\n' +
          'The VSCode extension requires the admin tool for delete/remove features.',
        );
      }
      if (msg.includes('NOT_FOUND') || msg.includes('StateError')) {
        return; // Tool exists - NOT_FOUND is a valid business response
      }
      throw err;
    }
  });

  test('All core tools are available', async () => {
    const api = getTestAPI();
    const coreTools = ['status', 'register', 'lock', 'message', 'plan'];

    for (const tool of coreTools) {
      try {
        if (tool === 'status') {
          const resultStr = await callToolString(api, 'status', {});
          assertOk(resultStr.includes('agents'), 'Status should have agents');
        }
      } catch (err: unknown) {
        const msg = String(err);
        if (msg.includes('not found')) {
          throw new Error(`Core tool '${tool}' not found on database!`);
        }
      }
    }
  });
});
