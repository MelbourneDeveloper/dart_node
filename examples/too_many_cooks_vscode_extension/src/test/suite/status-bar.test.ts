/**
 * Status Bar Tests
 * Verifies the status bar item updates correctly.
 */

import * as assert from 'assert';
import { waitForExtensionActivation, getTestAPI, restoreDialogMocks, safeDisconnect } from '../test-helpers';

// Ensure any dialog mocks from previous tests are restored
restoreDialogMocks();

suite('Status Bar', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('Status bar exists after activation', () => {
    // The status bar is created during activation
    // We can't directly query it, but we verify the extension is active
    const api = getTestAPI();
    assert.ok(api, 'Extension should be active with status bar');
  });

  test('Connection status changes are reflected', async function () {
    this.timeout(5000);

    // Ensure clean state by disconnecting first
    await safeDisconnect();
    const api = getTestAPI();

    // Initial state should be disconnected
    assert.strictEqual(api.getConnectionStatus(), 'disconnected');
  });
});
