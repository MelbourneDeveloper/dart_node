/**
 * Test helpers for integration tests.
 * NO MOCKING - real VSCode instance with real extension.
 */

import * as vscode from 'vscode';
import type { TestAPI } from '../test-api';

let cachedTestAPI: TestAPI | null = null;

/**
 * Gets the test API from the extension's exports.
 */
export function getTestAPI(): TestAPI {
  if (!cachedTestAPI) {
    throw new Error('Test API not initialized - call waitForExtensionActivation first');
  }
  return cachedTestAPI;
}

/**
 * Waits for a condition to be true, polling at regular intervals.
 */
export const waitForCondition = async (
  condition: () => boolean | Promise<boolean>,
  timeoutMessage = 'Condition not met within timeout',
  timeout = 10000
): Promise<void> => {
  const interval = 100;
  const startTime = Date.now();

  while (Date.now() - startTime < timeout) {
    const result = await Promise.resolve(condition());
    if (result) {
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, interval));
  }

  throw new Error(timeoutMessage);
};

/**
 * Waits for the extension to fully activate.
 */
export async function waitForExtensionActivation(): Promise<void> {
  console.log('[TEST HELPER] Starting extension activation wait...');

  const extension = vscode.extensions.getExtension('Nimblesite.too-many-cooks');
  if (!extension) {
    throw new Error('Extension not found - check publisher name in package.json');
  }

  console.log('[TEST HELPER] Extension found, checking activation status...');

  if (!extension.isActive) {
    console.log('[TEST HELPER] Extension not active, activating now...');
    await extension.activate();
    console.log('[TEST HELPER] Extension activate() completed');
  } else {
    console.log('[TEST HELPER] Extension already active');
  }

  await waitForCondition(
    () => {
      const exportsValue: unknown = extension.exports;
      console.log(`[TEST HELPER] Checking exports - type: ${typeof exportsValue}`);

      if (exportsValue !== undefined && exportsValue !== null) {
        if (typeof exportsValue === 'object') {
          cachedTestAPI = exportsValue as TestAPI;
          console.log('[TEST HELPER] Test API verified');
          return true;
        }
      }
      return false;
    },
    'Extension exports not available within timeout',
    30000
  );

  console.log('[TEST HELPER] Extension activation complete');
}

/**
 * Waits for connection to the MCP server.
 */
export async function waitForConnection(timeout = 30000): Promise<void> {
  console.log('[TEST HELPER] Waiting for MCP connection...');

  const api = getTestAPI();

  await waitForCondition(
    () => api.isConnected(),
    'MCP connection timed out',
    timeout
  );

  console.log('[TEST HELPER] MCP connection established');
}

/**
 * Opens the Too Many Cooks panel.
 */
export async function openTooManyCooksPanel(): Promise<void> {
  console.log('[TEST HELPER] Opening Too Many Cooks panel...');
  await vscode.commands.executeCommand('workbench.view.extension.tooManyCooks');

  // Wait for panel to be visible
  await new Promise((resolve) => setTimeout(resolve, 500));
  console.log('[TEST HELPER] Panel opened');
}
