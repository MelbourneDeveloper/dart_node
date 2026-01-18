/// Dashboard webview panel showing agent coordination status.
///
/// Dart port of dashboardPanel.ts - displays a rich HTML dashboard with
/// agents, locks, messages, and plans.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';
import 'package:too_many_cooks_vscode_extension/state/state.dart';
import 'package:too_many_cooks_vscode_extension/state/store.dart';

/// Dashboard webview panel.
final class DashboardPanel {
  DashboardPanel._(this._panel, this._storeManager) {
    _panel.onDidDispose(dispose.toJS);
    _panel.webview.html = _getHtmlContent();

    _unsubscribe = _storeManager.subscribe(_updateWebview);
  }

  static DashboardPanel? _currentPanel;

  final WebviewPanel _panel;
  final StoreManager _storeManager;
  void Function()? _unsubscribe;

  /// Creates or shows the dashboard panel.
  static void createOrShow(Window window, StoreManager storeManager) {
    final column = window.activeTextEditor?.viewColumn;

    if (_currentPanel case final current?) {
      current._panel.reveal(column);
      return;
    }

    final panel = window.createWebviewPanel(
      'tooManyCooksDashboard',
      'Too Many Cooks Dashboard',
      column ?? ViewColumn.one,
      WebviewOptions(enableScripts: true, retainContextWhenHidden: true),
    );

    _currentPanel = DashboardPanel._(panel, storeManager);
  }

  void _updateWebview() {
    final state = _storeManager.state;
    final data = {
      'agents': selectAgents(state).map((a) => {
        'agentName': a.agentName,
        'registeredAt': a.registeredAt,
        'lastActive': a.lastActive,
      }).toList(),
      'locks': selectLocks(state).map((l) => {
        'filePath': l.filePath,
        'agentName': l.agentName,
        'acquiredAt': l.acquiredAt,
        'expiresAt': l.expiresAt,
        'reason': l.reason,
      }).toList(),
      'messages': selectMessages(state).map((m) => {
        'id': m.id,
        'fromAgent': m.fromAgent,
        'toAgent': m.toAgent,
        'content': m.content,
        'createdAt': m.createdAt,
        'readAt': m.readAt,
      }).toList(),
      'plans': selectPlans(state).map((p) => {
        'agentName': p.agentName,
        'goal': p.goal,
        'currentTask': p.currentTask,
        'updatedAt': p.updatedAt,
      }).toList(),
    };
    _panel.webview.postMessage({'type': 'update', 'data': data}.jsify());
  }

  // ignore: use_raw_strings - escapes are intentional for JS template literals
  String _getHtmlContent() => '''
<!DOCTYPE html>
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
    <h1>Too Many Cooks Dashboard</h1>
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
      <h2><span class="icon">Agents</span></h2>
      <ul class="list" id="agentsList"></ul>
    </div>

    <div class="card">
      <h2><span class="icon">File Locks</span></h2>
      <ul class="list" id="locksList"></ul>
    </div>

    <div class="card">
      <h2><span class="icon">Recent Messages</span></h2>
      <ul class="list" id="messagesList"></ul>
    </div>

    <div class="card">
      <h2><span class="icon">Agent Plans</span></h2>
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
        : state.agents.map(a => `
          <li class="list-item">
            <div class="list-item-header">\${escapeHtml(a.agentName)}</div>
            <div class="list-item-detail">
              Last active: \${formatTime(a.lastActive)}
            </div>
          </li>
        `).join('');

      // Locks
      const locksList = document.getElementById('locksList');
      const now = Date.now();
      locksList.innerHTML = state.locks.length === 0
        ? '<li class="empty">No active locks</li>'
        : state.locks.map(l => {
          const expired = l.expiresAt < now;
          return `
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
          `;
        }).join('');

      // Messages
      const messagesList = document.getElementById('messagesList');
      const sortedMsgs = [...state.messages].sort((a, b) => b.createdAt - a.createdAt).slice(0, 10);
      messagesList.innerHTML = sortedMsgs.length === 0
        ? '<li class="empty">No messages</li>'
        : sortedMsgs.map(m => `
          <li class="list-item">
            <div class="list-item-header">
              \${escapeHtml(m.fromAgent)} -> \${m.toAgent === '*' ? 'All' : escapeHtml(m.toAgent)}
            </div>
            <div class="list-item-detail">
              \${escapeHtml(m.content.substring(0, 100))}\${m.content.length > 100 ? '...' : ''}
            </div>
          </li>
        `).join('');

      // Plans
      const plansList = document.getElementById('plansList');
      plansList.innerHTML = state.plans.length === 0
        ? '<li class="empty">No plans</li>'
        : state.plans.map(p => `
          <li class="list-item">
            <div class="list-item-header">\${escapeHtml(p.agentName)}</div>
            <div class="list-item-detail">
              <strong>Goal:</strong> \${escapeHtml(p.goal)}<br>
              <strong>Task:</strong> \${escapeHtml(p.currentTask)}
            </div>
          </li>
        `).join('');
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
</html>''';

  /// Disposes of this panel.
  void dispose() {
    _currentPanel = null;
    _unsubscribe?.call();
    _panel.dispose();
  }
}
