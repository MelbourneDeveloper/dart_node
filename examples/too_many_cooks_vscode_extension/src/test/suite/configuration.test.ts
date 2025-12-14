/**
 * Configuration Tests
 * Verifies configuration settings work correctly.
 */

import * as assert from 'assert';
import * as vscode from 'vscode';
import { waitForExtensionActivation, restoreDialogMocks } from '../test-helpers';

// Ensure any dialog mocks from previous tests are restored
restoreDialogMocks();

suite('Configuration', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('autoConnect configuration exists', () => {
    const config = vscode.workspace.getConfiguration('tooManyCooks');
    const autoConnect = config.get<boolean>('autoConnect');
    assert.ok(autoConnect !== undefined, 'autoConnect config should exist');
  });

  test('autoConnect defaults to true', () => {
    const config = vscode.workspace.getConfiguration('tooManyCooks');
    const autoConnect = config.get<boolean>('autoConnect');
    // Default is true according to package.json
    assert.strictEqual(autoConnect, true);
  });
});
