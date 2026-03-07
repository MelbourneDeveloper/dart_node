// Too Many Cooks VSCode Extension - TypeScript
// Visualizes the Too Many Cooks multi-agent coordination system.

import * as vscode from 'vscode';
import { StoreManager } from './services/storeManager';
import { StatusBarManager } from './ui/statusBar';
import { AgentsTreeProvider } from './ui/tree/agentsTreeProvider';
import { LocksTreeProvider } from './ui/tree/locksTreeProvider';
import { MessagesTreeProvider } from './ui/tree/messagesTreeProvider';
import { DashboardPanel } from './ui/webview/dashboardPanel';
import { AgentTreeItem } from './ui/tree/treeItems';
import { LockTreeItem } from './ui/tree/treeItems';
import { createTestAPI, TestAPI } from './testApi';

const logMessages: string[] = [];
let outputChannel: vscode.OutputChannel | undefined;

function log(message: string): void {
  const timestamp = new Date().toISOString();
  const fullMessage = `[${timestamp}] ${message}`;
  outputChannel?.appendLine(fullMessage);
  logMessages.push(fullMessage);
}

export function activate(context: vscode.ExtensionContext): TestAPI {
  outputChannel = vscode.window.createOutputChannel('Too Many Cooks');
  outputChannel.show(true);
  log('Extension activating...');

  // Get configuration
  const config = vscode.workspace.getConfiguration('tooManyCooks');
  const autoConnect = config.get<boolean>('autoConnect') ?? true;

  // Get workspace folder
  const folders = vscode.workspace.workspaceFolders;
  const workspaceFolder = folders && folders.length > 0
    ? folders[0].uri.fsPath
    : '.';
  log(`Using workspace folder: ${workspaceFolder}`);

  // Create store manager
  const storeManager = new StoreManager(workspaceFolder, log);

  // Create tree providers
  const agentsProvider = new AgentsTreeProvider(storeManager);
  const locksProvider = new LocksTreeProvider(storeManager);
  const messagesProvider = new MessagesTreeProvider(storeManager);

  // Register tree views
  vscode.window.createTreeView('tooManyCooksAgents', {
    treeDataProvider: agentsProvider,
    showCollapseAll: true,
  });
  vscode.window.createTreeView('tooManyCooksLocks', {
    treeDataProvider: locksProvider,
  });
  vscode.window.createTreeView('tooManyCooksMessages', {
    treeDataProvider: messagesProvider,
  });

  // Create status bar
  const statusBar = new StatusBarManager(storeManager);

  // Register commands
  registerCommands(context, storeManager);

  // Auto-connect if configured
  log(`Auto-connect: ${autoConnect}`);
  if (autoConnect) {
    log('Attempting auto-connect...');
    storeManager.connect().then(() => {
      log('Auto-connect: SUCCESS');
    }).catch(e => {
      log(`Auto-connect FAILED: ${e}`);
    });
  }

  log('Extension activated');

  // Register disposables
  context.subscriptions.push({
    dispose: () => {
      storeManager.disconnect();
      statusBar.dispose();
      agentsProvider.dispose();
      locksProvider.dispose();
      messagesProvider.dispose();
    },
  });

  return createTestAPI(storeManager, agentsProvider, locksProvider, messagesProvider, logMessages);
}

export function deactivate(): void {
  log('Extension deactivating');
}

function registerCommands(context: vscode.ExtensionContext, storeManager: StoreManager): void {
  // Connect
  context.subscriptions.push(
    vscode.commands.registerCommand('tooManyCooks.connect', async () => {
      log('Connect command triggered');
      try {
        await storeManager.connect();
        log('Connected successfully');
        vscode.window.showInformationMessage('Connected to Too Many Cooks server');
      } catch (e) {
        log(`Connection failed: ${e}`);
        vscode.window.showErrorMessage(`Failed to connect: ${e}`);
      }
    }),
  );

  // Disconnect
  context.subscriptions.push(
    vscode.commands.registerCommand('tooManyCooks.disconnect', async () => {
      await storeManager.disconnect();
      vscode.window.showInformationMessage('Disconnected from Too Many Cooks server');
    }),
  );

  // Refresh
  context.subscriptions.push(
    vscode.commands.registerCommand('tooManyCooks.refresh', async () => {
      try {
        await storeManager.refreshStatus();
      } catch (e) {
        vscode.window.showErrorMessage(`Failed to refresh: ${e}`);
      }
    }),
  );

  // Dashboard
  context.subscriptions.push(
    vscode.commands.registerCommand('tooManyCooks.showDashboard', () => {
      DashboardPanel.createOrShow(storeManager);
    }),
  );

  // Delete lock
  context.subscriptions.push(
    vscode.commands.registerCommand('tooManyCooks.deleteLock', async (item?: vscode.TreeItem) => {
      const filePath = getFilePathFromItem(item);
      if (!filePath) {
        vscode.window.showErrorMessage('No lock selected');
        return;
      }
      const confirm = await vscode.window.showWarningMessage(
        `Force release lock on ${filePath}?`,
        { modal: true },
        'Release',
      );
      if (confirm !== 'Release') { return; }
      try {
        storeManager.forceReleaseLock(filePath);
        log(`Force released lock: ${filePath}`);
        vscode.window.showInformationMessage(`Lock released: ${filePath}`);
      } catch (e) {
        log(`Failed to release lock: ${e}`);
        vscode.window.showErrorMessage(`Failed to release lock: ${e}`);
      }
    }),
  );

  // Delete agent
  context.subscriptions.push(
    vscode.commands.registerCommand('tooManyCooks.deleteAgent', async (item?: vscode.TreeItem) => {
      const agentName = getAgentNameFromItem(item);
      if (!agentName) {
        vscode.window.showErrorMessage('No agent selected');
        return;
      }
      const confirm = await vscode.window.showWarningMessage(
        `Remove agent "${agentName}"? This will release all their locks.`,
        { modal: true },
        'Remove',
      );
      if (confirm !== 'Remove') { return; }
      try {
        storeManager.deleteAgent(agentName);
        log(`Removed agent: ${agentName}`);
        vscode.window.showInformationMessage(`Agent removed: ${agentName}`);
      } catch (e) {
        log(`Failed to remove agent: ${e}`);
        vscode.window.showErrorMessage(`Failed to remove agent: ${e}`);
      }
    }),
  );

  // Send message
  context.subscriptions.push(
    vscode.commands.registerCommand('tooManyCooks.sendMessage', async (item?: vscode.TreeItem) => {
      let toAgent = getAgentNameFromItem(item);

      // If no target, show quick pick to select one
      if (!toAgent) {
        if (!storeManager.isConnected) {
          vscode.window.showErrorMessage('Not connected to server');
          return;
        }
        const agents = storeManager.state.agents;
        const agentNames = [
          '* (broadcast to all)',
          ...agents.map(a => a.agentName),
        ];
        const picked = await vscode.window.showQuickPick(agentNames, {
          placeHolder: 'Select recipient agent',
        });
        if (!picked) { return; }
        toAgent = picked === '* (broadcast to all)' ? '*' : picked;
      }

      // Pick sender from registered agents
      const senderAgents = storeManager.state.agents;
      if (senderAgents.length === 0) {
        vscode.window.showErrorMessage('No registered agents to send as');
        return;
      }
      const fromAgent = await vscode.window.showQuickPick(
        senderAgents.map(a => a.agentName),
        { placeHolder: 'Send as which agent?' },
      );
      if (!fromAgent) { return; }

      // Get message content
      const content = await vscode.window.showInputBox({
        prompt: `Message to ${toAgent}`,
        placeHolder: 'Enter your message...',
      });
      if (!content) { return; }

      try {
        storeManager.sendMessage(fromAgent, toAgent, content);
        const preview = content.length > 50 ? `${content.substring(0, 50)}...` : content;
        vscode.window.showInformationMessage(`Message sent to ${toAgent}: "${preview}"`);
        log(`Message sent from ${fromAgent} to ${toAgent}: ${content}`);
      } catch (e) {
        log(`Failed to send message: ${e}`);
        vscode.window.showErrorMessage(`Failed to send message: ${e}`);
      }
    }),
  );
}

function getFilePathFromItem(item?: vscode.TreeItem): string | undefined {
  if (!item) { return undefined; }
  // AgentTreeItem with filePath
  if (item instanceof AgentTreeItem && item.filePath) {
    return item.filePath;
  }
  // LockTreeItem with lock.filePath
  if (item instanceof LockTreeItem && item.lock) {
    return item.lock.filePath;
  }
  return undefined;
}

function getAgentNameFromItem(item?: vscode.TreeItem): string | undefined {
  if (!item) { return undefined; }
  if (item instanceof AgentTreeItem && item.agentName) {
    return item.agentName;
  }
  return undefined;
}
