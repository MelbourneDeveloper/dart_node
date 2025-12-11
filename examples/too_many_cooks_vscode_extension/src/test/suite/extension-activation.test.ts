/**
 * Extension Activation Tests
 * Verifies the extension activates correctly and exposes the test API.
 */

import * as assert from 'assert';
import * as vscode from 'vscode';
import { waitForExtensionActivation, getTestAPI } from '../test-helpers';

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

    // MUST contain server path log
    const hasServerPathLog = logs.some((msg) => msg.includes('Server path:'));
    assert.ok(hasServerPathLog, 'Must log server path');
  });
});
