---
layout: layouts/docs.njk
title: Too Many Cooks
description: Multi-agent coordination MCP server for AI agents editing codebases simultaneously.
eleventyNavigation:
  key: Too Many Cooks
  parent: Packages
  order: 10
---

Too Many Cooks is a multi-agent coordination MCP server that enables multiple AI agents to safely edit a codebase simultaneously. Built with [dart_node_mcp](/docs/mcp/).

## Features

- **File Locking**: Advisory locks prevent agents from editing the same files
- **Agent Identity**: Secure registration with API keys
- **Messaging**: Inter-agent communication with broadcast support
- **Plan Visibility**: Share goals and current tasks across agents
- **Real-time Status**: System overview of all agents, locks, and plans

## Installation

```bash
npm install -g too-many-cooks
```

## Usage with Claude Code

Add to your Claude Code MCP configuration:

```bash
claude mcp add --transport stdio too-many-cooks -- npx too-many-cooks
```

Or configure manually in your MCP settings:

```json
{
  "mcpServers": {
    "too-many-cooks": {
      "command": "npx",
      "args": ["too-many-cooks"]
    }
  }
}
```

## MCP Tools

### `register`
Register a new agent. Returns a secret key - store it!
```
Input:  { name: string }
Output: { agent_name, agent_key }
```

### `lock`
Manage file locks.
```
Actions: acquire, release, force_release, renew, query, list
Input: { action, agent_name?, agent_key?, file_path?, reason? }
```

### `message`
Send/receive messages between agents.
```
Actions: send, get, mark_read
Input: { action, agent_name, agent_key, to_agent?, content?, message_id? }
```
Use `*` as `to_agent` for broadcast.

### `plan`
Share what you're working on.
```
Actions: update, get, list
Input: { action, agent_name?, agent_key?, goal?, current_task? }
```

### `status`
Get system overview of all agents, locks, and plans.
```
Input: { }
Output: { agents, locks, plans, messages }
```

### `subscribe`
Subscribe to real-time notifications.
```
Actions: subscribe, unsubscribe, list
Events: agent_registered, lock_acquired, lock_released, message_sent, plan_updated
```

## Architecture

The server uses SQLite for persistent storage at `~/.too_many_cooks/data.db`. All clients connect to the same database ensuring coordination works across multiple agent sessions.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Claude Code   │     │ VSCode Extension│     │  Other Agents   │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   Too Many Cooks MCP   │
                    │        Server          │
                    └───────────┬────────────┘
                                │
                                ▼
                    ┌────────────────────────┐
                    │   ~/.too_many_cooks/   │
                    │        data.db         │
                    └────────────────────────┘
```

## Workflow Example

1. Agent registers: `register({ name: "agent-1" })` -> stores returned key
2. Agent acquires lock: `lock({ action: "acquire", file_path: "/src/app.ts", agent_name: "agent-1", agent_key: "xxx" })`
3. Agent updates plan: `plan({ action: "update", goal: "Fix auth bug", current_task: "Reading auth code" })`
4. Other agents can see the lock and plan via `status()`
5. Agent releases lock when done: `lock({ action: "release", ... })`

## VSCode Extension

A companion VSCode extension provides real-time visualization of agent coordination:

- **Agents Panel**: View all registered agents and their activity status
- **File Locks Panel**: See which files are locked and by whom
- **Messages Panel**: Monitor inter-agent communication
- **Plans Panel**: Track agent goals and current tasks
- **Real-time Updates**: Auto-refreshes to show latest status

### Installation

Install from the [VSCode Marketplace](https://marketplace.visualstudio.com/items?itemName=melbournedeveloper.too-many-cooks) or search for "Too Many Cooks" in the Extensions panel.

### Commands

- `Too Many Cooks: Connect to MCP Server` - Connect to the server
- `Too Many Cooks: Disconnect` - Disconnect from the server
- `Too Many Cooks: Refresh Status` - Manually refresh all panels
- `Too Many Cooks: Show Dashboard` - Open the dashboard view

### Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `tooManyCooks.serverPath` | `""` | Path to MCP server (empty = auto-detect via npx) |
| `tooManyCooks.autoConnect` | `true` | Auto-connect on startup |

## Source Code

- [MCP Server](https://github.com/melbournedeveloper/dart_node/tree/main/examples/too_many_cooks) - The Dart MCP server
- [VSCode Extension](https://github.com/melbournedeveloper/dart_node/tree/main/examples/too_many_cooks_vscode_extension) - The visualization extension
- [npm package](https://www.npmjs.com/package/too-many-cooks) - Published npm package
