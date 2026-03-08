// Test helpers for VSCode Extension Host integration tests.

import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { TestAPI, TreeItemSnapshot } from '../../src/testApi';

const EXTENSION_ID = 'Nimblesite.too-many-cooks';
const EVENT_TIMEOUT_MS = 1000;
const EVENT_POLL_MS = 50;

let cachedTestAPI: TestAPI | null = null;

// ============================================================================
// Core helpers
// ============================================================================

export function getTestAPI(): TestAPI {
  if (!cachedTestAPI) {
    throw new Error('Test API not initialized - call waitForExtensionActivation first');
  }
  return cachedTestAPI;
}

export async function waitForCondition(
  condition: () => boolean,
  message = 'Condition not met within timeout',
  timeout = EVENT_TIMEOUT_MS,
  interval = EVENT_POLL_MS,
): Promise<void> {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    if (condition()) { return; }
    await delay(interval);
  }
  throw new Error(`Timeout: ${message}`);
}

export async function waitForExtensionActivation(): Promise<void> {
  console.log('[TEST HELPER] Starting extension activation wait...');

  const ext = vscode.extensions.getExtension(EXTENSION_ID);
  if (!ext) {
    throw new Error(`Extension not found: ${EXTENSION_ID}`);
  }

  if (!ext.isActive) {
    await ext.activate();
  }

  const exports = ext.exports as TestAPI | undefined;
  if (exports) {
    cachedTestAPI = exports;
    console.log('[TEST HELPER] Test API verified immediately');
  } else {
    await waitForCondition(() => {
      const exp = ext.exports as TestAPI | undefined;
      if (exp) {
        cachedTestAPI = exp;
        return true;
      }
      return false;
    }, 'Extension exports not available within timeout', EVENT_TIMEOUT_MS);
  }

  console.log('[TEST HELPER] Extension activation complete');
}

export async function waitForConnection(timeout = EVENT_TIMEOUT_MS): Promise<void> {
  console.log('[TEST HELPER] Waiting for connection...');
  const api = getTestAPI();
  await waitForCondition(
    () => api.isConnected(),
    'Connection timed out',
    timeout,
  );
  console.log('[TEST HELPER] Connection established');
}

export async function safeDisconnect(): Promise<void> {
  if (!cachedTestAPI) { return; }
  if (cachedTestAPI.isConnected()) {
    try { await cachedTestAPI.disconnect(); } catch { /* ignore */ }
  }
  console.log('[TEST HELPER] Safe disconnect complete');
}

// ============================================================================
// Wait-for-tree helpers
// ============================================================================

export async function waitForLockInTree(
  api: TestAPI,
  filePath: string,
  timeout = EVENT_TIMEOUT_MS,
  interval = EVENT_POLL_MS,
): Promise<void> {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    try { await api.refreshStatus(); } catch { /* ignore */ }
    if (api.findLockInTree(filePath)) { return; }
    await delay(interval);
  }
  throw new Error(`Timeout: Lock to appear: ${filePath}`);
}

export async function waitForLockGone(
  api: TestAPI,
  filePath: string,
  timeout = EVENT_TIMEOUT_MS,
  interval = EVENT_POLL_MS,
): Promise<void> {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    try { await api.refreshStatus(); } catch { /* ignore */ }
    if (!api.findLockInTree(filePath)) { return; }
    await delay(interval);
  }
  throw new Error(`Timeout: Lock to disappear: ${filePath}`);
}

export async function waitForAgentInTree(
  api: TestAPI,
  agentName: string,
  timeout = EVENT_TIMEOUT_MS,
  interval = EVENT_POLL_MS,
): Promise<void> {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    try { await api.refreshStatus(); } catch { /* ignore */ }
    if (api.findAgentInTree(agentName)) { return; }
    await delay(interval);
  }
  throw new Error(`Timeout: Agent to appear: ${agentName}`);
}

export async function waitForAgentGone(
  api: TestAPI,
  agentName: string,
  timeout = EVENT_TIMEOUT_MS,
  interval = EVENT_POLL_MS,
): Promise<void> {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    try { await api.refreshStatus(); } catch { /* ignore */ }
    if (!api.findAgentInTree(agentName)) { return; }
    await delay(interval);
  }
  throw new Error(`Timeout: Agent to disappear: ${agentName}`);
}

export async function waitForMessageInTree(
  api: TestAPI,
  content: string,
  timeout = EVENT_TIMEOUT_MS,
  interval = EVENT_POLL_MS,
): Promise<void> {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    try { await api.refreshStatus(); } catch { /* ignore */ }
    if (api.findMessageInTree(content)) { return; }
    await delay(interval);
  }
  throw new Error(`Timeout: Message to appear: ${content}`);
}

// ============================================================================
// Server state reset & database cleanup
// ============================================================================

const TEST_BASE_URL = 'http://localhost:4040';

export async function resetServerState(): Promise<void> {
  console.log('[TEST HELPER] Resetting server state via /admin/reset');
  const response = await fetch(`${TEST_BASE_URL}/admin/reset`, { method: 'POST' });
  if (!response.ok) {
    throw new Error(`Failed to reset server: ${response.status} ${response.statusText}`);
  }
  console.log('[TEST HELPER] Server state reset');
}

export function cleanDatabase(): void {
  const folders = vscode.workspace.workspaceFolders;
  const first = folders && folders.length > 0 ? folders[0] : undefined;
  const wsFolder = first ? first.uri.fsPath : '.';
  const dbDir = path.join(wsFolder, '.too_many_cooks');

  console.log(`[TEST HELPER] Cleaning database at: ${dbDir}`);

  for (const f of ['data.db', 'data.db-wal', 'data.db-shm']) {
    try {
      fs.unlinkSync(path.join(dbDir, f));
    } catch { /* ignore if doesn't exist */ }
  }

  console.log('[TEST HELPER] Database cleaned');
}

// ============================================================================
// Dialog mocking via DialogService (not monkey-patching vscode.window)
// ============================================================================

import { setDialogService, resetDialogService } from 'services/dialogService';

let mocksInstalled = false;

const warningMessageResponses: (string | undefined)[] = [];
const quickPickResponses: (string | undefined)[] = [];
const inputBoxResponses: (string | undefined)[] = [];

export function mockWarningMessage(response: string | undefined): void {
  warningMessageResponses.push(response);
}

export function mockQuickPick(response: string | undefined): void {
  quickPickResponses.push(response);
}

export function mockInputBox(response: string | undefined): void {
  inputBoxResponses.push(response);
}

export function installDialogMocks(): void {
  if (mocksInstalled) { return; }

  setDialogService({
    showErrorMessage: async (_message: string): Promise<string | undefined> => {
      console.log(`[MOCK] showErrorMessage: ${_message}`);
      return undefined;
    },
    showInformationMessage: async (_message: string): Promise<string | undefined> => {
      console.log(`[MOCK] showInformationMessage: ${_message}`);
      return undefined;
    },
    showInputBox: async (): Promise<string | undefined> => {
      const val = inputBoxResponses.shift();
      console.log(`[MOCK] showInputBox returning: ${val}`);
      return val;
    },
    showQuickPick: async (): Promise<string | undefined> => {
      const val = quickPickResponses.shift();
      console.log(`[MOCK] showQuickPick returning: ${val}`);
      return val;
    },
    showWarningMessage: async (): Promise<string | undefined> => {
      const val = warningMessageResponses.shift();
      console.log(`[MOCK] showWarningMessage returning: ${val}`);
      return val;
    },
  });

  mocksInstalled = true;
  console.log('[TEST HELPER] Dialog mocks installed');
}

export function restoreDialogMocks(): void {
  if (!mocksInstalled) { return; }

  resetDialogService();

  warningMessageResponses.length = 0;
  quickPickResponses.length = 0;
  inputBoxResponses.length = 0;
  mocksInstalled = false;
  console.log('[TEST HELPER] Dialog mocks restored');
}

// ============================================================================
// Tool call helper
// ============================================================================

export async function callToolString(
  api: TestAPI,
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  return api.callTool(name, args);
}

export function extractKeyFromResult(result: string): string {
  const match = /"agent_key"\s*:\s*"([^"]+)"/.exec(result);
  if (!match) {
    throw new Error(`Could not extract agent_key from result: ${result}`);
  }
  return match[1] ?? '';
}

// ============================================================================
// TreeItemSnapshot helpers
// ============================================================================

export function getLabel(item: TreeItemSnapshot): string {
  return item.label ?? '';
}

export function getDescription(item: TreeItemSnapshot): string {
  return item.description ?? '';
}

export function getChildren(item: TreeItemSnapshot): readonly TreeItemSnapshot[] | undefined {
  return item.children;
}

export function hasChildWithLabel(item: TreeItemSnapshot, text: string): boolean {
  return item.children?.some(c => c.label.includes(text)) ?? false;
}

export function findChildByLabel(item: TreeItemSnapshot, text: string): TreeItemSnapshot | undefined {
  return item.children?.find(c => c.label.includes(text));
}

export function countChildrenMatching(
  item: TreeItemSnapshot,
  predicate: (child: TreeItemSnapshot) => boolean,
): number {
  return item.children?.filter(predicate).length ?? 0;
}

// ============================================================================
// Misc helpers
// ============================================================================

export async function openTooManyCooksPanel(): Promise<void> {
  await vscode.commands.executeCommand('workbench.view.extension.tooManyCooks');
}

export function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export function dumpTree(name: string, items: readonly TreeItemSnapshot[]): void {
  console.log(`\n=== ${name} TREE ===`);
  function dump(list: readonly TreeItemSnapshot[], indent: number): void {
    for (const item of list) {
      const prefix = '  '.repeat(indent);
      const desc = item.description ? ` [${item.description}]` : '';
      console.log(`${prefix}- ${item.label}${desc}`);
      if (item.children) { dump(item.children, indent + 1); }
    }
  }
  dump(items, 0);
  console.log('=== END ===\n');
}

// Assertion helpers
export function assertOk(value: unknown, message: string): void {
  if (!value) { throw new Error(`Assertion failed: ${message}`); }
}

export function assertEqual<T>(actual: T, expected: T, message?: string): void {
  if (actual !== expected) {
    throw new Error(
      `Assertion failed: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}` +
      (message ? ` - ${message}` : ''),
    );
  }
}
