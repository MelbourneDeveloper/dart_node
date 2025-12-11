/**
 * Configuration Tests
 * Verifies configuration settings work correctly.
 */

import * as assert from 'assert';
import * as vscode from 'vscode';
import { waitForExtensionActivation } from '../test-helpers';

suite('Configuration', () => {
  suiteSetup(async () => {
    await waitForExtensionActivation();
  });

  test('serverPath configuration exists', () => {
    const config = vscode.workspace.getConfiguration('tooManyCooks');
    const serverPath = config.get<string>('serverPath');
    assert.ok(serverPath !== undefined, 'serverPath config should exist');
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

  test('serverPath can be updated', async () => {
    const config = vscode.workspace.getConfiguration('tooManyCooks');
    const testPath = '/test/path/to/server.js';

    await config.update('serverPath', testPath, vscode.ConfigurationTarget.Global);

    const updatedConfig = vscode.workspace.getConfiguration('tooManyCooks');
    const serverPath = updatedConfig.get<string>('serverPath');
    assert.strictEqual(serverPath, testPath);

    // Reset
    await config.update('serverPath', '', vscode.ConfigurationTarget.Global);
  });
});
