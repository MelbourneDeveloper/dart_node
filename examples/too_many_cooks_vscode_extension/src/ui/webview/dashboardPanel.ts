/**
 * Dashboard webview panel showing agent coordination status.
 */

import * as vscode from 'vscode';
import { effect } from '@preact/signals-core';
import { agents, locks, messages, plans } from '../../state/signals';

export class DashboardPanel {
  public static currentPanel: DashboardPanel | undefined;
  private readonly panel: vscode.WebviewPanel;
  private disposeEffect: (() => void) | null = null;
  private disposables: vscode.Disposable[] = [];

  private constructor(
    panel: vscode.WebviewPanel,
    private extensionUri: vscode.Uri
  ) {
    this.panel = panel;

    this.panel.onDidDispose(() => this.dispose(), null, this.disposables);

    this.panel.webview.html = this.getHtmlContent();

    // React to state changes
    this.disposeEffect = effect(() => {
      this.updateWebview();
    });
  }

  public static createOrShow(extensionUri: vscode.Uri): void {
    const column = vscode.window.activeTextEditor
      ? vscode.window.activeTextEditor.viewColumn
      : undefined;

    if (DashboardPanel.currentPanel) {
      DashboardPanel.currentPanel.panel.reveal(column);
      return;
    }

    const panel = vscode.window.createWebviewPanel(
      'tooManyCooksDashboard',
      'Too Many Cooks Dashboard',
      column || vscode.ViewColumn.One,
      {
        enableScripts: true,
        retainContextWhenHidden: true,
      }
    );

    DashboardPanel.currentPanel = new DashboardPanel(panel, extensionUri);
  }

  private updateWebview(): void {
    const data = {
      agents: agents.value,
      locks: locks.value,
      messages: messages.value,
      plans: plans.value,
    };
    this.panel.webview.postMessage({ type: 'update', data });
  }

  private getHtmlContent(): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Too Many Cooks Dashboard</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: var(--vscode-font-family);
      background: var(--vscode-editor-background);
      color: var(--vscode-editor-foreground);
      padding: 16px;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
      padding-bottom: 10px;
      border-bottom: 1px solid var(--vscode-panel-border);
    }
    h1 {
      font-size: 1.5em;
      font-weight: 600;
    }
    .stats {
      display: flex;
      gap: 20px;
    }
    .stat {
      text-align: center;
      padding: 10px 20px;
      background: var(--vscode-input-background);
      border-radius: 6px;
    }
    .stat-value {
      font-size: 2em;
      font-weight: bold;
      color: var(--vscode-textLink-foreground);
    }
    .stat-label {
      font-size: 0.85em;
      color: var(--vscode-descriptionForeground);
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 16px;
      margin-top: 20px;
    }
    .card {
      background: var(--vscode-input-background);
      border-radius: 8px;
      padding: 16px;
    }
    .card h2 {
      font-size: 1.1em;
      margin-bottom: 12px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .icon { font-size: 1.2em; }
    .list {
      list-style: none;
      max-height: 300px;
      overflow-y: auto;
    }
    .list-item {
      padding: 8px;
      margin-bottom: 6px;
      background: var(--vscode-editor-background);
      border-radius: 4px;
      font-size: 0.9em;
    }
    .list-item-header {
      font-weight: 600;
      margin-bottom: 4px;
    }
    .list-item-detail {
      color: var(--vscode-descriptionForeground);
      font-size: 0.85em;
    }
    .badge {
      display: inline-block;
      padding: 2px 6px;
      border-radius: 10px;
      font-size: 0.75em;
      margin-left: 8px;
    }
    .badge-active {
      background: var(--vscode-testing-iconPassed);
      color: white;
    }
    .badge-expired {
      background: var(--vscode-testing-iconFailed);
      color: white;
    }
    .empty {
      color: var(--vscode-descriptionForeground);
      font-style: italic;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>🍳 Too Many Cooks Dashboard</h1>
    <div class="stats">
      <div class="stat">
        <div class="stat-value" id="agentCount">0</div>
        <div class="stat-label">Agents</div>
      </div>
      <div class="stat">
        <div class="stat-value" id="lockCount">0</div>
        <div class="stat-label">Locks</div>
      </div>
      <div class="stat">
        <div class="stat-value" id="messageCount">0</div>
        <div class="stat-label">Messages</div>
      </div>
      <div class="stat">
        <div class="stat-value" id="planCount">0</div>
        <div class="stat-label">Plans</div>
      </div>
    </div>
  </div>

  <div class="grid">
    <div class="card">
      <h2><span class="icon">👤</span> Agents</h2>
      <ul class="list" id="agentsList"></ul>
    </div>

    <div class="card">
      <h2><span class="icon">🔒</span> File Locks</h2>
      <ul class="list" id="locksList"></ul>
    </div>

    <div class="card">
      <h2><span class="icon">💬</span> Recent Messages</h2>
      <ul class="list" id="messagesList"></ul>
    </div>

    <div class="card">
      <h2><span class="icon">🎯</span> Agent Plans</h2>
      <ul class="list" id="plansList"></ul>
    </div>
  </div>

  <script>
    const vscode = acquireVsCodeApi();
    let state = { agents: [], locks: [], messages: [], plans: [] };

    window.addEventListener('message', event => {
      const msg = event.data;
      if (msg.type === 'update') {
        state = msg.data;
        render();
      }
    });

    function render() {
      // Stats
      document.getElementById('agentCount').textContent = state.agents.length;
      document.getElementById('lockCount').textContent = state.locks.length;
      document.getElementById('messageCount').textContent = state.messages.length;
      document.getElementById('planCount').textContent = state.plans.length;

      // Agents
      const agentsList = document.getElementById('agentsList');
      agentsList.innerHTML = state.agents.length === 0
        ? '<li class="empty">No agents registered</li>'
        : state.agents.map(a => \`
          <li class="list-item">
            <div class="list-item-header">\${escapeHtml(a.agentName)}</div>
            <div class="list-item-detail">
              Last active: \${formatTime(a.lastActive)}
            </div>
          </li>
        \`).join('');

      // Locks
      const locksList = document.getElementById('locksList');
      const now = Date.now();
      locksList.innerHTML = state.locks.length === 0
        ? '<li class="empty">No active locks</li>'
        : state.locks.map(l => {
          const expired = l.expiresAt < now;
          return \`
            <li class="list-item">
              <div class="list-item-header">
                \${escapeHtml(l.filePath)}
                <span class="badge \${expired ? 'badge-expired' : 'badge-active'}">
                  \${expired ? 'EXPIRED' : 'ACTIVE'}
                </span>
              </div>
              <div class="list-item-detail">
                Held by: \${escapeHtml(l.agentName)}
                \${l.reason ? ' - ' + escapeHtml(l.reason) : ''}
              </div>
            </li>
          \`;
        }).join('');

      // Messages
      const messagesList = document.getElementById('messagesList');
      const sortedMsgs = [...state.messages].sort((a, b) => b.createdAt - a.createdAt).slice(0, 10);
      messagesList.innerHTML = sortedMsgs.length === 0
        ? '<li class="empty">No messages</li>'
        : sortedMsgs.map(m => \`
          <li class="list-item">
            <div class="list-item-header">
              \${escapeHtml(m.fromAgent)} → \${m.toAgent === '*' ? 'All' : escapeHtml(m.toAgent)}
            </div>
            <div class="list-item-detail">
              \${escapeHtml(m.content.substring(0, 100))}\${m.content.length > 100 ? '...' : ''}
            </div>
          </li>
        \`).join('');

      // Plans
      const plansList = document.getElementById('plansList');
      plansList.innerHTML = state.plans.length === 0
        ? '<li class="empty">No plans</li>'
        : state.plans.map(p => \`
          <li class="list-item">
            <div class="list-item-header">\${escapeHtml(p.agentName)}</div>
            <div class="list-item-detail">
              <strong>Goal:</strong> \${escapeHtml(p.goal)}<br>
              <strong>Task:</strong> \${escapeHtml(p.currentTask)}
            </div>
          </li>
        \`).join('');
    }

    function escapeHtml(str) {
      const div = document.createElement('div');
      div.textContent = str;
      return div.innerHTML;
    }

    function formatTime(ts) {
      if (!ts) return 'Never';
      return new Date(ts).toLocaleString();
    }

    // Initial render
    render();
  </script>
</body>
</html>`;
  }

  public dispose(): void {
    DashboardPanel.currentPanel = undefined;
    this.disposeEffect?.();
    this.panel.dispose();
    while (this.disposables.length) {
      const d = this.disposables.pop();
      if (d) {
        d.dispose();
      }
    }
  }
}
