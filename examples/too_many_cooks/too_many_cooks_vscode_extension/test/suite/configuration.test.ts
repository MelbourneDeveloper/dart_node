// Configuration Tests
// Verifies configuration settings work correctly.

import * as vscode from 'vscode';
import {
  waitForExtensionActivation,
  restoreDialogMocks,
  assertOk,
  assertEqual,
} from './testHelpers';

restoreDialogMocks();

suite('Configuration', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('autoConnect configuration exists', () => {
    const config = vscode.workspace.getConfiguration('tooManyCooks');
    const autoConnect = config.get<boolean>('autoConnect');
    assertOk(autoConnect !== undefined, 'autoConnect config should exist');
  });

  test('autoConnect defaults to true', () => {
    const config = vscode.workspace.getConfiguration('tooManyCooks');
    const autoConnect = config.get<boolean>('autoConnect');
    assertEqual(autoConnect, true);
  });
});
