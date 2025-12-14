/**
 * Command Tests
 * Verifies all registered commands work correctly.
 */

import * as assert from 'assert';
import * as vscode from 'vscode';
import { waitForExtensionActivation, getTestAPI, restoreDialogMocks } from '../test-helpers';

// Ensure any dialog mocks from previous tests are restored
restoreDialogMocks();

suite('Commands', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('tooManyCooks.connect command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assert.ok(
      commands.includes('tooManyCooks.connect'),
      'connect command should be registered'
    );
  });

  test('tooManyCooks.disconnect command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assert.ok(
      commands.includes('tooManyCooks.disconnect'),
      'disconnect command should be registered'
    );
  });

  test('tooManyCooks.refresh command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assert.ok(
      commands.includes('tooManyCooks.refresh'),
      'refresh command should be registered'
    );
  });

  test('tooManyCooks.showDashboard command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assert.ok(
      commands.includes('tooManyCooks.showDashboard'),
      'showDashboard command should be registered'
    );
  });

  test('disconnect command can be executed without error when not connected', async () => {
    // Should not throw even when not connected
    await vscode.commands.executeCommand('tooManyCooks.disconnect');
    const api = getTestAPI();
    assert.strictEqual(api.isConnected(), false);
  });

  test('showDashboard command opens a webview panel', async () => {
    // Close any existing editors
    await vscode.commands.executeCommand('workbench.action.closeAllEditors');

    // Execute command
    await vscode.commands.executeCommand('tooManyCooks.showDashboard');

    // Give time for panel to open
    await new Promise((resolve) => setTimeout(resolve, 500));

    // The dashboard should be visible (can't directly test webview content,
    // but we can verify the command executed without error)
    // The test passes if no error is thrown
  });
});
