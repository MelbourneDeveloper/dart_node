# dart_node

Write your entire stack in Dart: React web apps, React Native mobile apps with Expo, and Node.js Express backends.

[Documentation](https://melbournedeveloper.github.io/dart_node/)

![React and React Native](images/dart_node.gif)

## Packages

| Package | Description |
|---------|-------------|
| [dart_node_core](packages/dart_node_core) | Core JS interop utilities |
| [dart_node_express](packages/dart_node_express) | Express.js bindings |
| [dart_node_ws](packages/dart_node_ws) | WebSocket bindings |
| [dart_node_react](packages/dart_node_react) | React bindings |
| [dart_node_react_native](packages/dart_node_react_native) | React Native bindings |
| [dart_node_mcp](packages/dart_node_mcp) | MCP server bindings |
| [dart_node_better_sqlite3](packages/dart_node_better_sqlite3) | SQLite3 bindings |
| [dart_jsx](packages/dart_jsx) | JSX transpiler for Dart |
| [reflux](packages/reflux) | Redux-style state management |
| [dart_logging](packages/dart_logging) | Structured logging |
| [dart_node_coverage](packages/dart_node_coverage) | Code coverage for dart2js |

## Tools

| Tool | Description |
|------|-------------|
| [too-many-cooks](examples/too_many_cooks) | Multi-agent coordination MCP server ([npm](https://www.npmjs.com/package/too-many-cooks)) |
| [Too Many Cooks VSCode](examples/too_many_cooks_vscode_extension) | VSCode extension for agent visualization |

## Quick Start

```bash
# Switch to local deps
dart tools/switch_deps.dart local

# Run everything
sh run_dev.sh
```

Open http://localhost:8080/web/

**Mobile:** Use VSCode launch config `Mobile: Build & Run (Expo)`

## License

BSD 3-Clause License. Copyright (c) 2025, Christian Findlay.
