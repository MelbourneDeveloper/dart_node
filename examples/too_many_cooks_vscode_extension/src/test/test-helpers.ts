/**
 * Test helpers for integration tests.
 * Includes dialog mocking for command testing.
 */

import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { spawn } from 'child_process';
import { createRequire } from 'module';
import type { TestAPI } from '../test-api';

// Store original methods for restoration
const originalShowWarningMessage = vscode.window.showWarningMessage;
const originalShowQuickPick = vscode.window.showQuickPick;
const originalShowInputBox = vscode.window.showInputBox;

// Mock response queues
let warningMessageResponses: (string | undefined)[] = [];
let quickPickResponses: (string | undefined)[] = [];
let inputBoxResponses: (string | undefined)[] = [];

/**
 * Queue a response for the next showWarningMessage call.
 */
export function mockWarningMessage(response: string | undefined): void {
  warningMessageResponses.push(response);
}

/**
 * Queue a response for the next showQuickPick call.
 */
export function mockQuickPick(response: string | undefined): void {
  quickPickResponses.push(response);
}

/**
 * Queue a response for the next showInputBox call.
 */
export function mockInputBox(response: string | undefined): void {
  inputBoxResponses.push(response);
}

/**
 * Install dialog mocks on vscode.window.
 */
export function installDialogMocks(): void {
  (vscode.window as { showWarningMessage: typeof vscode.window.showWarningMessage }).showWarningMessage = (async () => {
    return warningMessageResponses.shift();
  }) as typeof vscode.window.showWarningMessage;

  (vscode.window as { showQuickPick: typeof vscode.window.showQuickPick }).showQuickPick = (async () => {
    return quickPickResponses.shift();
  }) as typeof vscode.window.showQuickPick;

  (vscode.window as { showInputBox: typeof vscode.window.showInputBox }).showInputBox = (async () => {
    return inputBoxResponses.shift();
  }) as typeof vscode.window.showInputBox;
}

/**
 * Restore original dialog methods.
 */
export function restoreDialogMocks(): void {
  (vscode.window as { showWarningMessage: typeof vscode.window.showWarningMessage }).showWarningMessage = originalShowWarningMessage;
  (vscode.window as { showQuickPick: typeof vscode.window.showQuickPick }).showQuickPick = originalShowQuickPick;
  (vscode.window as { showInputBox: typeof vscode.window.showInputBox }).showInputBox = originalShowInputBox;
  warningMessageResponses = [];
  quickPickResponses = [];
  inputBoxResponses = [];
}

let cachedTestAPI: TestAPI | null = null;
// __dirname at runtime is out/test, so go up 3 levels to extension root, then up to examples/, then into too_many_cooks
const serverProjectDir = path.resolve(__dirname, '../../../too_many_cooks');
const npmCommand = process.platform === 'win32' ? 'npm.cmd' : 'npm';
const requireFromServer = createRequire(path.join(serverProjectDir, 'package.json'));
let serverDepsPromise: Promise<void> | null = null;

// Path to local server build for testing
export const SERVER_PATH = path.resolve(
  serverProjectDir,
  'build/bin/server.js'
);

/**
 * Configure the extension to use local server path for testing.
 * MUST be called before extension activates.
 */
export function setTestServerPath(): void {
  (globalThis as Record<string, unknown>)._tooManyCooksTestServerPath = SERVER_PATH;
  console.log(`[TEST HELPER] Set test server path: ${SERVER_PATH}`);
}

const canRequireBetterSqlite3 = (): boolean => {
  try {
    requireFromServer('better-sqlite3');
    return true;
  } catch (err) {
    if (
      err instanceof Error &&
      (err.message.includes('NODE_MODULE_VERSION') ||
        err.message.includes("Cannot find module 'better-sqlite3'") ||
        err.message.includes('MODULE_NOT_FOUND'))
    ) {
      return false;
    }
    throw err;
  }
};

const runNpm = async (args: string[]): Promise<void> => {
  console.log(`[TEST HELPER] Running ${npmCommand} ${args.join(' ')} in ${serverProjectDir}`);
  await new Promise<void>((resolve, reject) => {
    const child = spawn(npmCommand, args, {
      cwd: serverProjectDir,
      stdio: 'inherit',
    });
    child.on('error', reject);
    child.on('exit', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`npm ${args.join(' ')} failed with code ${code ?? 'unknown'}`));
      }
    });
  });
};

const installOrRebuildBetterSqlite3 = async (): Promise<void> => {
  if (canRequireBetterSqlite3()) {
    return;
  }

  const moduleDir = path.join(serverProjectDir, 'node_modules', 'better-sqlite3');
  const args = fs.existsSync(moduleDir)
    ? ['rebuild', 'better-sqlite3']
    : ['install', '--no-audit', '--no-fund'];

  await runNpm(args);

  if (!canRequireBetterSqlite3()) {
    throw new Error('better-sqlite3 remains unavailable after rebuild');
  }
};

export const ensureServerDependencies = async (): Promise<void> => {
  if (!serverDepsPromise) {
    serverDepsPromise = installOrRebuildBetterSqlite3().catch((err) => {
      serverDepsPromise = null;
      throw err;
    });
  }
  await serverDepsPromise;
};

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
 * Sets up test server path before activation.
 */
export async function waitForExtensionActivation(): Promise<void> {
  console.log('[TEST HELPER] Starting extension activation wait...');

  // Ensure server dependencies are installed
  await ensureServerDependencies();

  // Set test server path BEFORE extension activates
  if (!fs.existsSync(SERVER_PATH)) {
    throw new Error(
      `MCP SERVER NOT FOUND AT ${SERVER_PATH}\n` +
      'Build it first: cd examples/too_many_cooks && ./build.sh'
    );
  }
  setTestServerPath();

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
 * Safely disconnects, waiting for any pending connection to settle first.
 * This avoids the "Client stopped" race condition.
 */
export async function safeDisconnect(): Promise<void> {
  const api = getTestAPI();

  // Wait a moment for any pending auto-connect to either succeed or fail
  await new Promise((resolve) => setTimeout(resolve, 500));

  // Only disconnect if actually connected - avoids "Client stopped" error
  // when disconnecting a client that failed to connect
  if (api.isConnected()) {
    try {
      await api.disconnect();
    } catch {
      // Ignore errors during disconnect - connection may have failed
    }
  }

  console.log('[TEST HELPER] Safe disconnect complete');
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

/**
 * Cleans the Too Many Cooks database files for fresh test state.
 * Should be called in suiteSetup before connecting.
 */
export function cleanDatabase(): void {
  const homeDir = process.env.HOME ?? '/tmp';
  const dbDir = path.join(homeDir, '.too_many_cooks');
  for (const f of ['data.db', 'data.db-wal', 'data.db-shm']) {
    try {
      fs.unlinkSync(path.join(dbDir, f));
    } catch {
      /* ignore if doesn't exist */
    }
  }
  console.log('[TEST HELPER] Database cleaned');
}
