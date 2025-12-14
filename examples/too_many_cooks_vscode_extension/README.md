# Too Many Cooks - VSCode Extension

Visualize multi-agent coordination in real-time. See file locks, messages, and plans across AI agents working on your codebase.

## Prerequisites

**Node.js 18+** is required. The `too-many-cooks` package is fetched automatically via `npx`.

## Features

- **Agents Panel**: View all registered agents and their activity status
- **File Locks Panel**: See which files are locked and by whom
- **Messages Panel**: Monitor inter-agent communication
- **Plans Panel**: Track agent goals and current tasks
- **Real-time Updates**: Auto-refreshes to show latest status

## Quick Start

1. Add the MCP server to your AI coding assistant (see below)
2. Install this VSCode extension
3. The extension auto-connects on startup
4. Open the "Too Many Cooks" view in the Activity Bar (chef icon)

All tools use `npx too-many-cooks`, sharing the same SQLite database at `~/.too_many_cooks/data.db`.

## MCP Server Setup

### Claude Code

```bash
claude mcp add --transport stdio too-many-cooks --scope user -- npx too-many-cooks
```

### Cursor

Add to `~/.cursor/mcp.json` (global) or `.cursor/mcp.json` (project):

```json
{
  "mcpServers": {
    "too-many-cooks": {
      "command": "npx",
      "args": ["-y", "too-many-cooks"]
    }
  }
}
```

### OpenAI Codex CLI

Add to `~/.codex/config.toml`:

```toml
[mcp_servers.too-many-cooks]
command = "npx"
args = ["-y", "too-many-cooks"]
```

### GitHub Copilot

Add to `.vscode/mcp.json` in your project:

```json
{
  "servers": {
    "too-many-cooks": {
      "command": "npx",
      "args": ["-y", "too-many-cooks"]
    }
  }
}
```

### Commands

- `Too Many Cooks: Connect to MCP Server` - Connect to the server
- `Too Many Cooks: Disconnect` - Disconnect from the server
- `Too Many Cooks: Refresh Status` - Manually refresh all panels
- `Too Many Cooks: Show Dashboard` - Open the dashboard view

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `tooManyCooks.autoConnect` | `true` | Auto-connect on startup |

## Architecture

The extension connects to the Too Many Cooks MCP server which coordinates multiple AI agents editing the same codebase:

```
┌─────────────────────────────────────────────────────────────┐
│                     VSCode Extension                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │  Agents  │ │  Locks   │ │ Messages │ │  Plans   │       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
│       └────────────┴────────────┴────────────┘              │
│                           │                                  │
└───────────────────────────┼──────────────────────────────────┘
                            │ MCP Protocol
                            ▼
              ┌────────────────────────┐
              │   too-many-cooks MCP   │
              │        Server          │
              └───────────┬────────────┘
                          │
                          ▼
              ┌────────────────────────┐
              │   ~/.too_many_cooks/   │
              │        data.db         │
              └────────────────────────┘
```

## Related

- [too-many-cooks](https://www.npmjs.com/package/too-many-cooks) - The MCP server (npm package)
- [dart_node](https://dartnode.dev) - The underlying Dart-on-Node.js framework

## License

MIT
