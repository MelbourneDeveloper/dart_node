/**
 * Too Many Cooks VSCode Extension
 *
 * Visualizes the Too Many Cooks multi-agent coordination system.
 */

import * as vscode from 'vscode';
import { Store } from './state/store';
import { AgentsTreeProvider } from './ui/tree/agentsTreeProvider';
import { LocksTreeProvider } from './ui/tree/locksTreeProvider';
import { MessagesTreeProvider } from './ui/tree/messagesTreeProvider';
import { PlansTreeProvider } from './ui/tree/plansTreeProvider';
import { LockDecorationProvider } from './ui/decorations/lockDecorations';
import { StatusBarManager } from './ui/statusBar/statusBarItem';
import { DashboardPanel } from './ui/webview/dashboardPanel';

let store: Store | undefined;
let statusBar: StatusBarManager | undefined;
let agentsProvider: AgentsTreeProvider | undefined;
let locksProvider: LocksTreeProvider | undefined;
let messagesProvider: MessagesTreeProvider | undefined;
let plansProvider: PlansTreeProvider | undefined;
let lockDecorations: LockDecorationProvider | undefined;

export async function activate(
  context: vscode.ExtensionContext
): Promise<void> {
  const config = vscode.workspace.getConfiguration('tooManyCooks');
  const serverPath = config.get<string>(
    'serverPath',
    'dart run too_many_cooks'
  );

  // Initialize store
  store = new Store(serverPath);

  // Create tree providers
  agentsProvider = new AgentsTreeProvider();
  locksProvider = new LocksTreeProvider();
  messagesProvider = new MessagesTreeProvider();
  plansProvider = new PlansTreeProvider();

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

  const plansView = vscode.window.createTreeView('tooManyCooksPlans', {
    treeDataProvider: plansProvider,
    showCollapseAll: true,
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
      try {
        await store?.connect();
        vscode.window.showInformationMessage(
          'Connected to Too Many Cooks server'
        );
      } catch (err) {
        vscode.window.showErrorMessage(
          `Failed to connect: ${err instanceof Error ? err.message : String(err)}`
        );
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

  // Auto-connect on startup if configured
  const autoConnect = config.get<boolean>('autoConnect', false);
  if (autoConnect) {
    store.connect().catch((err) => {
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

  // Register disposables
  context.subscriptions.push(
    agentsView,
    locksView,
    messagesView,
    plansView,
    decorationDisposable,
    connectCmd,
    disconnectCmd,
    refreshCmd,
    dashboardCmd,
    configListener,
    {
      dispose: () => {
        store?.disconnect();
        statusBar?.dispose();
        agentsProvider?.dispose();
        locksProvider?.dispose();
        messagesProvider?.dispose();
        plansProvider?.dispose();
        lockDecorations?.dispose();
      },
    }
  );
}

export function deactivate(): void {
  // Cleanup handled by disposables
}
