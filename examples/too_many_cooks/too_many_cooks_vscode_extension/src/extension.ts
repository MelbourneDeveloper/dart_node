// Too Many Cooks VSCode Extension - TypeScript.
// Visualizes the Too Many Cooks multi-agent coordination system.

// eslint-disable-next-line @typescript-eslint/no-require-imports
require('module-alias/register');

import * as vscode from 'vscode';
import type { AgentIdentity } from 'state/types';
import { AgentsTreeProvider } from 'ui/tree/agentsTreeProvider';
import { DashboardPanel } from 'ui/webview/dashboardPanel';
import { LocksTreeProvider } from 'ui/tree/locksTreeProvider';
import { MessagesTreeProvider } from 'ui/tree/messagesTreeProvider';
import { StatusBarManager } from 'ui/statusBar';
import { StoreManager } from 'services/storeManager';
import type { TestAPI } from 'testApi';
import { createTestAPI } from 'testApi';

// eslint-disable-next-line @typescript-eslint/no-inferrable-types
const MESSAGE_PREVIEW_LENGTH: number = 50;

const logMessages: string[] = [];
let outputChannel: vscode.OutputChannel | null = null;

function log(message: string): void {
  const timestamp: string = new Date().toISOString();
  const fullMessage: string = `[${timestamp}] ${message}`;
  outputChannel?.appendLine(fullMessage);
  logMessages.push(fullMessage);
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
export function activate(context: vscode.ExtensionContext): TestAPI {
  outputChannel = vscode.window.createOutputChannel('Too Many Cooks');
  outputChannel.show(true);
  log('Extension activating...');

  const config: vscode.WorkspaceConfiguration = vscode.workspace.getConfiguration('tooManyCooks');
  const autoConnect: boolean = config.get<boolean>('autoConnect') ?? true;
  const workspaceFolder: string = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? '.';
  log(`Using workspace folder: ${workspaceFolder}`);

  const storeManager: StoreManager = new StoreManager(workspaceFolder, log);
  const agentsProvider: AgentsTreeProvider = new AgentsTreeProvider(storeManager);
  const locksProvider: LocksTreeProvider = new LocksTreeProvider(storeManager);
  const messagesProvider: MessagesTreeProvider = new MessagesTreeProvider(storeManager);

  registerTreeViews(agentsProvider, locksProvider, messagesProvider);
  const statusBar: StatusBarManager = new StatusBarManager(storeManager);
  registerAllCommands(context, storeManager);

  if (autoConnect) {
    storeManager.connect().then(
      (): void => { log('Auto-connect: SUCCESS'); },
      (err: unknown): void => { log(`Auto-connect FAILED: ${String(err)}`); },
    );
  }

  context.subscriptions.push({
    dispose: (): void => {
      storeManager.disconnect();
      statusBar.dispose();
      agentsProvider.dispose();
      locksProvider.dispose();
      messagesProvider.dispose();
    },
  });

  return createTestAPI({
    agentsProvider,
    locksProvider,
    logMessages,
    messagesProvider,
    storeManager,
  });
}

export function deactivate(): void {
  log('Extension deactivating');
}

function registerTreeViews(
  agentsProvider: Readonly<AgentsTreeProvider>,
  locksProvider: Readonly<LocksTreeProvider>,
  messagesProvider: Readonly<MessagesTreeProvider>,
): void {
  vscode.window.createTreeView('tooManyCooksAgents', {
    showCollapseAll: true,
    treeDataProvider: agentsProvider,
  });
  vscode.window.createTreeView('tooManyCooksLocks', {
    treeDataProvider: locksProvider,
  });
  vscode.window.createTreeView('tooManyCooksMessages', {
    treeDataProvider: messagesProvider,
  });
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function registerAllCommands(context: vscode.ExtensionContext, sm: Readonly<StoreManager>): void {
  context.subscriptions.push(registerConnectCommand(sm));
  context.subscriptions.push(registerDisconnectCommand(sm));
  context.subscriptions.push(registerRefreshCommand(sm));
  context.subscriptions.push(registerDashboardCommand(sm));
  context.subscriptions.push(registerDeleteLockCommand(sm));
  context.subscriptions.push(registerDeleteAgentCommand(sm));
  context.subscriptions.push(registerSendMessageCommand(sm));
}

function registerConnectCommand(storeManager: Readonly<StoreManager>): vscode.Disposable {
  return vscode.commands.registerCommand('tooManyCooks.connect', async (): Promise<void> => {
    try {
      await storeManager.connect();
      log('Connected successfully');
      await vscode.window.showInformationMessage('Connected to Too Many Cooks server');
    } catch (err: unknown) {
      log(`Connection failed: ${String(err)}`);
      await vscode.window.showErrorMessage(`Failed to connect: ${String(err)}`);
    }
  });
}

function registerDisconnectCommand(storeManager: Readonly<StoreManager>): vscode.Disposable {
  return vscode.commands.registerCommand('tooManyCooks.disconnect', (): void => {
    storeManager.disconnect();
    vscode.window.showInformationMessage('Disconnected from Too Many Cooks server').then(
      (): void => {
        // Resolved
      },
      (): void => {
        // Rejected
      },
    );
  });
}

function registerRefreshCommand(storeManager: Readonly<StoreManager>): vscode.Disposable {
  return vscode.commands.registerCommand('tooManyCooks.refresh', async (): Promise<void> => {
    try {
      await storeManager.refreshStatus();
    } catch (err: unknown) {
      await vscode.window.showErrorMessage(`Failed to refresh: ${String(err)}`);
    }
  });
}

function registerDashboardCommand(storeManager: Readonly<StoreManager>): vscode.Disposable {
  return vscode.commands.registerCommand('tooManyCooks.showDashboard', (): void => {
    DashboardPanel.createOrShow(storeManager);
  });
}

function registerDeleteLockCommand(storeManager: Readonly<StoreManager>): vscode.Disposable {
  return vscode.commands.registerCommand(
    'tooManyCooks.deleteLock',
    // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
    async (item?: vscode.TreeItem): Promise<void> => {
      const filePath: string | null = getFilePathFromItem(item);
      if (filePath === null) {
        await vscode.window.showErrorMessage('No lock selected');
        return;
      }
      const confirm: string | undefined = await vscode.window.showWarningMessage(
        `Force release lock on ${filePath}?`,
        { modal: true },
        'Release',
      );
      if (confirm !== 'Release') { return; }
      try {
        await storeManager.forceReleaseLock(filePath);
        log(`Force released lock: ${filePath}`);
        await vscode.window.showInformationMessage(`Lock released: ${filePath}`);
      } catch (err: unknown) {
        log(`Failed to release lock: ${String(err)}`);
        await vscode.window.showErrorMessage(`Failed to release lock: ${String(err)}`);
      }
    },
  );
}

function registerDeleteAgentCommand(storeManager: Readonly<StoreManager>): vscode.Disposable {
  return vscode.commands.registerCommand(
    'tooManyCooks.deleteAgent',
    // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
    async (item?: vscode.TreeItem): Promise<void> => {
      const agentName: string | null = getAgentNameFromItem(item);
      if (agentName === null) {
        await vscode.window.showErrorMessage('No agent selected');
        return;
      }
      const confirm: string | undefined = await vscode.window.showWarningMessage(
        `Remove agent "${agentName}"? This will release all their locks.`,
        { modal: true },
        'Remove',
      );
      if (confirm !== 'Remove') { return; }
      try {
        await storeManager.deleteAgent(agentName);
        log(`Removed agent: ${agentName}`);
        await vscode.window.showInformationMessage(`Agent removed: ${agentName}`);
      } catch (err: unknown) {
        log(`Failed to remove agent: ${String(err)}`);
        await vscode.window.showErrorMessage(`Failed to remove agent: ${String(err)}`);
      }
    },
  );
}

function registerSendMessageCommand(storeManager: Readonly<StoreManager>): vscode.Disposable {
  return vscode.commands.registerCommand(
    'tooManyCooks.sendMessage',
    // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
    async (item?: vscode.TreeItem): Promise<void> => {
      await handleSendMessage(storeManager, item);
    },
  );
}

async function handleSendMessage(
  storeManager: Readonly<StoreManager>,
  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  item?: vscode.TreeItem,
): Promise<void> {
  const toAgent: string | null = await selectRecipient(storeManager, item);
  if (toAgent === null) { return; }

  const fromAgent: string | undefined = await vscode.window.showQuickPick(
    storeManager.state.agents.map(
      (agent: Readonly<AgentIdentity>): string => { return agent.agentName; },
    ),
    { placeHolder: 'Send as which agent?' },
  );
  if (typeof fromAgent === 'undefined') { return; }

  const content: string | undefined = await vscode.window.showInputBox({
    placeHolder: 'Enter your message...',
    prompt: `Message to ${toAgent}`,
  });
  if (typeof content === 'undefined') { return; }

  try {
    await storeManager.sendMessage(fromAgent, toAgent, content);
    let preview: string = content;
    if (content.length > MESSAGE_PREVIEW_LENGTH) {
      preview = `${content.substring(0, MESSAGE_PREVIEW_LENGTH)}...`;
    }
    await vscode.window.showInformationMessage(`Message sent to ${toAgent}: "${preview}"`);
    log(`Message sent from ${fromAgent} to ${toAgent}: ${content}`);
  } catch (err: unknown) {
    log(`Failed to send message: ${String(err)}`);
    await vscode.window.showErrorMessage(`Failed to send message: ${String(err)}`);
  }
}

async function selectRecipient(
  storeManager: Readonly<StoreManager>,
  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  item?: vscode.TreeItem,
): Promise<string | null> {
  const fromItem: string | null = getAgentNameFromItem(item);
  if (fromItem !== null) { return fromItem; }

  if (!storeManager.isConnected) {
    await vscode.window.showErrorMessage('Not connected to server');
    return null;
  }
  const agentNames: string[] = [
    '* (broadcast to all)',
    ...storeManager.state.agents.map(
      (agent: Readonly<AgentIdentity>): string => { return agent.agentName; },
    ),
  ];
  const picked: string | undefined = await vscode.window.showQuickPick(agentNames, {
    placeHolder: 'Select recipient agent',
  });
  if (typeof picked === 'undefined') { return null; }
  if (picked === '* (broadcast to all)') { return '*'; }
  return picked;
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function getFilePathFromItem(item?: vscode.TreeItem): string | null {
  if (typeof item === 'undefined') { return null; }
  // Duck-type checks to avoid instanceof failures across module boundaries.
  if ('filePath' in item && typeof item.filePath === 'string') {
    return item.filePath;
  }
  if ('lock' in item && typeof item.lock === 'object' && item.lock !== null) {
    const lock: unknown = item.lock;
    if (typeof lock === 'object' && lock !== null && 'filePath' in lock && typeof lock.filePath === 'string') {
      return lock.filePath;
    }
  }
  return null;
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function getAgentNameFromItem(item?: vscode.TreeItem): string | null {
  if (typeof item === 'undefined') { return null; }
  if ('agentName' in item && typeof item.agentName === 'string') {
    return item.agentName;
  }
  return null;
}
