// Status Bar Tests
// Verifies the status bar item updates correctly.

import {
  waitForExtensionActivation,
  safeDisconnect,
  getTestAPI,
  restoreDialogMocks,
  assertOk,
  assertEqual,
} from './testHelpers';

restoreDialogMocks();

suite('Status Bar', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('Status bar exists after activation', () => {
    const api = getTestAPI();
    assertOk(api, 'Extension should be active with status bar');
  });

  test('Connection status changes are reflected', async () => {
    await safeDisconnect();
    const api = getTestAPI();
    assertEqual(api.getConnectionStatus(), 'disconnected');
  });
});
