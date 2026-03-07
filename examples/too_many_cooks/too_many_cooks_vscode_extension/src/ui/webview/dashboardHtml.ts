// Dashboard HTML template - split into parts to satisfy max-lines-per-function.

function getLayoutStyles(): string {
  return `<style>
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
    h1 { font-size: 1.5em; font-weight: 600; }
    .stats { display: flex; gap: 20px; }
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
  </style>`;
}

function getCardStyles(): string {
  return `<style>
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
  </style>`;
}

function getItemStyles(): string {
  return `<style>
    .icon { font-size: 1.2em; }
    .list { list-style: none; max-height: 300px; overflow-y: auto; }
    .list-item {
      padding: 8px;
      margin-bottom: 6px;
      background: var(--vscode-editor-background);
      border-radius: 4px;
      font-size: 0.9em;
    }
    .list-item-header { font-weight: 600; margin-bottom: 4px; }
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
    .badge-active { background: var(--vscode-testing-iconPassed); color: white; }
    .badge-expired { background: var(--vscode-testing-iconFailed); color: white; }
    .empty { color: var(--vscode-descriptionForeground); font-style: italic; }
  </style>`;
}

function getHeaderHtml(): string {
  return `<div class="header">
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
  </div>`;
}

function getGridHtml(): string {
  return `<div class="grid">
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
  </div>`;
}

function getInitScript(): string {
  return `
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
      document.getElementById('agentCount').textContent = state.agents.length;
      document.getElementById('lockCount').textContent = state.locks.length;
      document.getElementById('messageCount').textContent = state.messages.length;
      document.getElementById('planCount').textContent = state.plans.length;
      renderAgents();
      renderLocks();
      renderMessages();
      renderPlans();
    }
  `;
}

function getRenderAgentsScript(): string {
  return `
    function renderAgents() {
      const el = document.getElementById('agentsList');
      el.innerHTML = state.agents.length === 0
        ? '<li class="empty">No agents registered</li>'
        : state.agents.map(a =>
          '<li class="list-item">' +
          '<div class="list-item-header">' + escapeHtml(a.agentName) + '</div>' +
          '<div class="list-item-detail">Last active: ' + formatTime(a.lastActive) + '</div>' +
          '</li>').join('');
    }
  `;
}

function getRenderLocksScript(): string {
  return `
    function renderLocks() {
      const el = document.getElementById('locksList');
      const now = Date.now();
      el.innerHTML = state.locks.length === 0
        ? '<li class="empty">No active locks</li>'
        : state.locks.map(l => {
          const expired = l.expiresAt < now;
          return '<li class="list-item">' +
            '<div class="list-item-header">' + escapeHtml(l.filePath) +
            '<span class="badge ' + (expired ? 'badge-expired' : 'badge-active') + '">' +
            (expired ? 'EXPIRED' : 'ACTIVE') + '</span></div>' +
            '<div class="list-item-detail">Held by: ' + escapeHtml(l.agentName) +
            (l.reason ? ' - ' + escapeHtml(l.reason) : '') +
            '</div></li>';
        }).join('');
    }
  `;
}

function getRenderMessagesScript(): string {
  return `
    function renderMessages() {
      const el = document.getElementById('messagesList');
      const sorted = [...state.messages].sort((a, b) => b.createdAt - a.createdAt).slice(0, 10);
      el.innerHTML = sorted.length === 0
        ? '<li class="empty">No messages</li>'
        : sorted.map(m =>
          '<li class="list-item">' +
          '<div class="list-item-header">' + escapeHtml(m.fromAgent) +
          ' -> ' + (m.toAgent === '*' ? 'All' : escapeHtml(m.toAgent)) + '</div>' +
          '<div class="list-item-detail">' +
          escapeHtml(m.content.substring(0, 100)) +
          (m.content.length > 100 ? '...' : '') +
          '</div></li>').join('');
    }
  `;
}

function getRenderPlansScript(): string {
  return `
    function renderPlans() {
      const el = document.getElementById('plansList');
      el.innerHTML = state.plans.length === 0
        ? '<li class="empty">No plans</li>'
        : state.plans.map(p =>
          '<li class="list-item">' +
          '<div class="list-item-header">' + escapeHtml(p.agentName) + '</div>' +
          '<div class="list-item-detail">' +
          '<strong>Goal:</strong> ' + escapeHtml(p.goal) + '<br>' +
          '<strong>Task:</strong> ' + escapeHtml(p.currentTask) +
          '</div></li>').join('');
    }
  `;
}

function getUtilScript(): string {
  return `
    function escapeHtml(str) {
      const div = document.createElement('div');
      div.textContent = str;
      return div.innerHTML;
    }

    function formatTime(ts) {
      if (!ts) return 'Never';
      return new Date(ts).toLocaleString();
    }

    render();
  `;
}

export function getDashboardHtml(): string {
  return [
    '<!DOCTYPE html>',
    '<html lang="en">',
    '<head>',
    '  <meta charset="UTF-8">',
    '  <meta name="viewport" content="width=device-width, initial-scale=1.0">',
    '  <title>Too Many Cooks Dashboard</title>',
    getLayoutStyles(),
    getCardStyles(),
    getItemStyles(),
    '</head>',
    '<body>',
    getHeaderHtml(),
    getGridHtml(),
    '<script>',
    getInitScript(),
    getRenderAgentsScript(),
    getRenderLocksScript(),
    getRenderMessagesScript(),
    getRenderPlansScript(),
    getUtilScript(),
    '</script>',
    '</body>',
    '</html>',
  ].join('\n');
}
