# Too Many Cooks

Multi-agent coordination MCP server - enables multiple AI agents to safely edit a codebase simultaneously.

## Features

- **File Locking**: Advisory locks prevent agents from editing the same files
- **Agent Identity**: Secure registration with API keys
- **Messaging**: Inter-agent communication with broadcast support
- **Plan Visibility**: Share goals and current tasks across agents
- **Real-time Status**: System overview of all agents, locks, and plans
- **Written in Dart**: Made with [dart_node](https://dartnode.dev)

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

## Example Rules

```markdown
## Multi-Agent Coordination (Too Many Cooks)
- Keep your key! It's critical. Do not lose it!
- Check messages regularly, lock files before editing, unlock after
- Don't edit locked files; signal intent via plans and messages
- Coordinator: keep delegating via messages. Worker: keep asking for tasks via messages
- Clean up expired locks routinely
- Do not use Git unless asked by user
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

## License

MIT
