// Dashboard webview panel showing agent coordination status.

import * as vscode from 'vscode';
import type { StoreManager } from 'services/storeManager';
import { selectAgents, selectLocks, selectMessages, selectPlans } from 'state/selectors';
import type { AgentIdentity, AgentPlan, AppState, FileLock, Message } from 'state/types';
import { getDashboardHtml } from 'ui/webview/dashboardHtml';

export class DashboardPanel {
  private static currentPanel: DashboardPanel | null = null;

  private readonly panel: vscode.WebviewPanel;
  private readonly unsubscribe: () => void;

  private constructor(
    panel: vscode.WebviewPanel,
    storeManager: Readonly<StoreManager>,
  ) {
    this.panel = panel;
    this.panel.onDidDispose((): void => { this.dispose(); });
    this.panel.webview.html = getDashboardHtml();

    this.unsubscribe = storeManager.subscribe((): void => {
      this.updateWebview(storeManager);
    });
  }

  public static createOrShow(storeManager: Readonly<StoreManager>): void {
    const column: vscode.ViewColumn | undefined = vscode.window.activeTextEditor?.viewColumn;

    if (DashboardPanel.currentPanel !== null) {
      DashboardPanel.currentPanel.panel.reveal(column);
      return;
    }

    const resolvedColumn: vscode.ViewColumn = column ?? vscode.ViewColumn.One;
    const panel: vscode.WebviewPanel = vscode.window.createWebviewPanel(
      'tooManyCooksDashboard',
      'Too Many Cooks Dashboard',
      resolvedColumn,
      { enableScripts: true, retainContextWhenHidden: true },
    );

    DashboardPanel.currentPanel = new DashboardPanel(panel, storeManager);
  }

  private updateWebview(storeManager: Readonly<StoreManager>): void {
    const { state }: { readonly state: AppState } = storeManager;
    const data: Record<string, unknown> = buildWebviewData(state);
    this.panel.webview.postMessage({ data, type: 'update' }).then(
      (): void => {
        // Sent successfully
      },
      (): void => {
        // Post message failed
      },
    );
  }

  public dispose(): void {
    DashboardPanel.currentPanel = null;
    this.unsubscribe();
    this.panel.dispose();
  }
}

function buildWebviewData(state: Readonly<AppState>): Record<string, unknown> {
  return {
    agents: selectAgents(state).map(
      (agent: Readonly<AgentIdentity>): Record<string, unknown> => {
        return {
          agentName: agent.agentName,
          lastActive: agent.lastActive,
          registeredAt: agent.registeredAt,
        };
      },
    ),
    locks: selectLocks(state).map(
      (lock: Readonly<FileLock>): Record<string, unknown> => {
        return {
          acquiredAt: lock.acquiredAt,
          agentName: lock.agentName,
          expiresAt: lock.expiresAt,
          filePath: lock.filePath,
          reason: lock.reason,
        };
      },
    ),
    messages: selectMessages(state).map(
      (msg: Readonly<Message>): Record<string, unknown> => {
        return {
          content: msg.content,
          createdAt: msg.createdAt,
          fromAgent: msg.fromAgent,
          id: msg.id,
          readAt: msg.readAt,
          toAgent: msg.toAgent,
        };
      },
    ),
    plans: selectPlans(state).map(
      (plan: Readonly<AgentPlan>): Record<string, unknown> => {
        return {
          agentName: plan.agentName,
          currentTask: plan.currentTask,
          goal: plan.goal,
          updatedAt: plan.updatedAt,
        };
      },
    ),
  };
}