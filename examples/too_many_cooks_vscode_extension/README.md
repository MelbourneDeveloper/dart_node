# Too Many Cooks - VSCode Extension

Visualize multi-agent coordination in real-time. See file locks, messages, and plans across AI agents working on your codebase.

## Prerequisites

**Node.js** and the **too-many-cooks** MCP server must be installed:

```bash
npm install -g too-many-cooks
```

## Features

- **Agents Panel**: View all registered agents and their activity status
- **File Locks Panel**: See which files are locked and by whom
- **Messages Panel**: Monitor inter-agent communication
- **Plans Panel**: Track agent goals and current tasks
- **Real-time Updates**: Auto-refreshes to show latest status

## Usage

1. Install the extension
2. The extension auto-connects on startup (configurable)
3. Open the "Too Many Cooks" view in the Activity Bar (chef icon)
4. View agents, locks, messages, and plans in real-time

### Commands

- `Too Many Cooks: Connect to MCP Server` - Connect to the server
- `Too Many Cooks: Disconnect` - Disconnect from the server
- `Too Many Cooks: Refresh Status` - Manually refresh all panels
- `Too Many Cooks: Show Dashboard` - Open the dashboard view

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `tooManyCooks.serverPath` | `""` | Path to MCP server (empty = auto-detect via npx) |
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
- [dart_node](https://dartnode.org) - The underlying Dart-on-Node.js framework

## License

MIT
