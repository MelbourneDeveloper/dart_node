/**
 * Too Many Cooks VSCode Extension
 *
 * Visualizes the Too Many Cooks multi-agent coordination system.
 */

import * as vscode from 'vscode';
import { Store } from './state/store';
import { AgentsTreeProvider, AgentTreeItem } from './ui/tree/agentsTreeProvider';
import { LocksTreeProvider, LockTreeItem } from './ui/tree/locksTreeProvider';
import { MessagesTreeProvider } from './ui/tree/messagesTreeProvider';
import { LockDecorationProvider } from './ui/decorations/lockDecorations';
import { StatusBarManager } from './ui/statusBar/statusBarItem';
import { DashboardPanel } from './ui/webview/dashboardPanel';
import { createTestAPI, addLogMessage, type TestAPI } from './test-api';

export type { TestAPI };

let store: Store | undefined;
let statusBar: StatusBarManager | undefined;
let agentsProvider: AgentsTreeProvider | undefined;
let locksProvider: LocksTreeProvider | undefined;
let messagesProvider: MessagesTreeProvider | undefined;
let lockDecorations: LockDecorationProvider | undefined;
let outputChannel: vscode.OutputChannel | undefined;

function log(message: string): void {
  const timestamp = new Date().toISOString();
  const fullMessage = `[${timestamp}] ${message}`;
  outputChannel?.appendLine(fullMessage);
  // Also store for test verification
  addLogMessage(fullMessage);
}

export async function activate(
  context: vscode.ExtensionContext
): Promise<TestAPI> {
  // Create output channel for logging - show it immediately so user can see logs
  outputChannel = vscode.window.createOutputChannel('Too Many Cooks');
  outputChannel.show(true); // Show but don't take focus
  // Expose globally for Store to use
  (globalThis as Record<string, unknown>)._tooManyCooksOutput = outputChannel;
  log('Extension activating...');

  const config = vscode.workspace.getConfiguration('tooManyCooks');
  let serverPath = config.get<string>('serverPath', '');

  // Auto-detect server path if not configured
  if (!serverPath) {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (workspaceFolder) {
      // Try common locations relative to workspace
      const candidates = [
        'examples/too_many_cooks/build/bin/server_node.js',
        'too_many_cooks/build/bin/server_node.js',
        'build/bin/server_node.js',
      ];
      const fs = require('fs');
      const path = require('path');
      for (const candidate of candidates) {
        const fullPath = path.join(workspaceFolder.uri.fsPath, candidate);
        if (fs.existsSync(fullPath)) {
          serverPath = fullPath;
          log(`Auto-detected server at: ${serverPath}`);
          break;
        }
      }
    }
  }

  if (!serverPath) {
    log('WARNING: No server path configured and auto-detect failed');
    vscode.window.showWarningMessage(
      'Too Many Cooks: Set tooManyCooks.serverPath in settings'
    );
  }

  log(`Server path: ${serverPath}`);

  // Initialize store
  store = new Store(serverPath);

  // Create tree providers
  agentsProvider = new AgentsTreeProvider();
  locksProvider = new LocksTreeProvider();
  messagesProvider = new MessagesTreeProvider();

  // Register tree views
  const agentsView = vscode.window.createTreeView('tooManyCooksAgents', {
    treeDataProvider: agentsProvider,
    showCollapseAll: true,
  });

  const locksView = vscode.window.createTreeView('tooManyCooksLocks', {
    treeDataProvider: locksProvider,
  });

  const messagesView = vscode.window.createTreeView('tooManyCooksMessages', {
    treeDataProvider: messagesProvider,
  });

  // Create file decoration provider
  lockDecorations = new LockDecorationProvider();
  const decorationDisposable = vscode.window.registerFileDecorationProvider(
    lockDecorations
  );

  // Create status bar
  statusBar = new StatusBarManager();

  // Register commands
  const connectCmd = vscode.commands.registerCommand(
    'tooManyCooks.connect',
    async () => {
      log('Connect command triggered');
      try {
        await store?.connect();
        log('Connected successfully');
        vscode.window.showInformationMessage(
          'Connected to Too Many Cooks server'
        );
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        log(`Connection failed: ${msg}`);
        vscode.window.showErrorMessage(`Failed to connect: ${msg}`);
      }
    }
  );

  const disconnectCmd = vscode.commands.registerCommand(
    'tooManyCooks.disconnect',
    async () => {
      await store?.disconnect();
      vscode.window.showInformationMessage(
        'Disconnected from Too Many Cooks server'
      );
    }
  );

  const refreshCmd = vscode.commands.registerCommand(
    'tooManyCooks.refresh',
    async () => {
      try {
        await store?.refreshStatus();
      } catch (err) {
        vscode.window.showErrorMessage(
          `Failed to refresh: ${err instanceof Error ? err.message : String(err)}`
        );
      }
    }
  );

  const dashboardCmd = vscode.commands.registerCommand(
    'tooManyCooks.showDashboard',
    () => {
      DashboardPanel.createOrShow(context.extensionUri);
    }
  );

  // Delete lock command - force release a lock
  const deleteLockCmd = vscode.commands.registerCommand(
    'tooManyCooks.deleteLock',
    async (item: LockTreeItem | AgentTreeItem) => {
      const filePath = item instanceof LockTreeItem
        ? item.lock?.filePath
        : item.filePath;
      if (!filePath) {
        vscode.window.showErrorMessage('No lock selected');
        return;
      }
      const confirm = await vscode.window.showWarningMessage(
        `Force release lock on ${filePath}?`,
        { modal: true },
        'Release'
      );
      if (confirm !== 'Release') return;
      try {
        await store?.forceReleaseLock(filePath);
        log(`Force released lock: ${filePath}`);
        vscode.window.showInformationMessage(`Lock released: ${filePath}`);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        log(`Failed to release lock: ${msg}`);
        vscode.window.showErrorMessage(`Failed to release lock: ${msg}`);
      }
    }
  );

  // Delete agent command - remove an agent from the system
  const deleteAgentCmd = vscode.commands.registerCommand(
    'tooManyCooks.deleteAgent',
    async (item: AgentTreeItem) => {
      const agentName = item.agentName;
      if (!agentName) {
        vscode.window.showErrorMessage('No agent selected');
        return;
      }
      const confirm = await vscode.window.showWarningMessage(
        `Remove agent "${agentName}"? This will release all their locks.`,
        { modal: true },
        'Remove'
      );
      if (confirm !== 'Remove') return;
      try {
        await store?.deleteAgent(agentName);
        log(`Removed agent: ${agentName}`);
        vscode.window.showInformationMessage(`Agent removed: ${agentName}`);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        log(`Failed to remove agent: ${msg}`);
        vscode.window.showErrorMessage(`Failed to remove agent: ${msg}`);
      }
    }
  );

  // Send message command
  const sendMessageCmd = vscode.commands.registerCommand(
    'tooManyCooks.sendMessage',
    async (item?: AgentTreeItem) => {
      // Get target agent (if clicked from agent context menu)
      let toAgent = item?.agentName;

      // If no target, show quick pick to select one
      if (!toAgent) {
        const response = await store?.callTool('status', {});
        if (!response) {
          vscode.window.showErrorMessage('Not connected to server');
          return;
        }
        const status = JSON.parse(response);
        const agentNames = status.agents.map(
          (a: { agent_name: string }) => a.agent_name
        );
        agentNames.unshift('* (broadcast to all)');
        toAgent = await vscode.window.showQuickPick(agentNames, {
          placeHolder: 'Select recipient agent',
        });
        if (!toAgent) return;
        if (toAgent === '* (broadcast to all)') toAgent = '*';
      }

      // Get sender name
      const fromAgent = await vscode.window.showInputBox({
        prompt: 'Your agent name (sender)',
        placeHolder: 'e.g., vscode-user',
        value: 'vscode-user',
      });
      if (!fromAgent) return;

      // Get message content
      const content = await vscode.window.showInputBox({
        prompt: `Message to ${toAgent}`,
        placeHolder: 'Enter your message...',
      });
      if (!content) return;

      try {
        await store?.sendMessage(fromAgent, toAgent, content);
        vscode.window.showInformationMessage(
          `Message sent to ${toAgent}: "${content.substring(0, 50)}${content.length > 50 ? '...' : ''}"`
        );
        log(`Message sent from ${fromAgent} to ${toAgent}: ${content}`);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        log(`Failed to send message: ${msg}`);
        vscode.window.showErrorMessage(`Failed to send message: ${msg}`);
      }
    }
  );

  // Auto-connect on startup if configured (default: true)
  const autoConnect = config.get<boolean>('autoConnect', true);
  log(`Auto-connect: ${autoConnect}`);
  if (autoConnect) {
    log('Attempting auto-connect...');
    store.connect().then(() => {
      log('Auto-connect successful');
    }).catch((err) => {
      log(`Auto-connect failed: ${err instanceof Error ? err.message : String(err)}`);
      console.error('Auto-connect failed:', err);
    });
  }

  // Watch for config changes
  const configListener = vscode.workspace.onDidChangeConfiguration((e) => {
    if (e.affectsConfiguration('tooManyCooks.serverPath')) {
      const newPath = vscode.workspace
        .getConfiguration('tooManyCooks')
        .get<string>('serverPath', 'dart run too_many_cooks');
      store?.setServerPath(newPath);
    }
  });

  log('Extension activated');

  // Register disposables
  context.subscriptions.push(
    outputChannel,
    agentsView,
    locksView,
    messagesView,
    decorationDisposable,
    connectCmd,
    disconnectCmd,
    refreshCmd,
    dashboardCmd,
    deleteLockCmd,
    deleteAgentCmd,
    sendMessageCmd,
    configListener,
    {
      dispose: () => {
        store?.disconnect();
        statusBar?.dispose();
        agentsProvider?.dispose();
        locksProvider?.dispose();
        messagesProvider?.dispose();
        lockDecorations?.dispose();
      },
    }
  );

  // Return test API for integration tests
  return createTestAPI(store, {
    agents: agentsProvider,
    locks: locksProvider,
    messages: messagesProvider,
  });
}

export function deactivate(): void {
  // Cleanup handled by disposables
}
