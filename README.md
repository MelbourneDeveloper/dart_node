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

## Dev Container (Recommended)

This project includes a [Dev Container](.devcontainer/devcontainer.json) that provides a fully configured development environment with Dart, Node.js, and Chromium pre-installed. Open the project in VSCode and select **Reopen in Container** when prompted.

**Why use it?**

- **Consistent environment** — Dart 3.10, Node 20, and Chromium are pinned and pre-configured. No version mismatches across machines.
- **Avoids Windows + Node.js performance issues** — Node.js file-heavy operations (`npm install`, `dart2js` output, `node_modules` creation) run up to [4x slower on Windows than Linux](https://github.com/microsoft/Windows-Dev-Performance/issues/17) due to NTFS overhead and Windows Defender real-time scanning. Yo will probably get better performance running on [WSL2](https://docs.docker.com/desktop/features/wsl/). The Dev Container sidesteps this entirely by running inside a Linux container.
- **Zero setup** — Coverage thresholds, linting, and test tooling are pre-configured via environment variables and VSCode settings.

## Quick Start

```bash
# Switch to local deps
dart tools/switch_deps.dart local

# Run everything
sh examples/run_taskflow.sh
```

Open http://localhost:8080/web/

**Mobile:** Use VSCode launch config `Mobile: Build & Run (Expo)`

## License

BSD 3-Clause License. Copyright (c) 2025, Christian Findlay.
