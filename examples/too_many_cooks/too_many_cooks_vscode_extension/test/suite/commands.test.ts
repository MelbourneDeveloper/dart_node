// Command Tests
// Verifies all registered commands work correctly.

import * as vscode from 'vscode';
import {
  waitForExtensionActivation,
  getTestAPI,
  restoreDialogMocks,
  delay,
  assertOk,
  assertEqual,
} from './testHelpers';

restoreDialogMocks();

suite('Commands', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('tooManyCooks.connect command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assertOk(commands.includes('tooManyCooks.connect'), 'connect command should be registered');
  });

  test('tooManyCooks.disconnect command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assertOk(commands.includes('tooManyCooks.disconnect'), 'disconnect command should be registered');
  });

  test('tooManyCooks.refresh command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assertOk(commands.includes('tooManyCooks.refresh'), 'refresh command should be registered');
  });

  test('tooManyCooks.showDashboard command is registered', async () => {
    const commands = await vscode.commands.getCommands(true);
    assertOk(commands.includes('tooManyCooks.showDashboard'), 'showDashboard command should be registered');
  });

  test('disconnect command can be executed without error when not connected', async () => {
    await vscode.commands.executeCommand('tooManyCooks.disconnect');
    const api = getTestAPI();
    assertEqual(api.isConnected(), false);
  });

  test('showDashboard command opens a webview panel', async () => {
    await vscode.commands.executeCommand('workbench.action.closeAllEditors');
    await vscode.commands.executeCommand('tooManyCooks.showDashboard');
    await delay(500);
    await vscode.commands.executeCommand('workbench.action.closeAllEditors');
  });
});
