# Examples

Dart apps running on Node.js and browser JS.

```
examples/
├── backend/                      → Express API server (Node.js)
├── frontend/                     → React web app (Browser)
├── shared/                       → Common types (User, Task)
├── mobile/                       → React Native app (Expo)
├── markdown_editor/              → Rich text editor demo
├── reflux_demo/                  → State management demo
├── jsx_demo/                     → JSX syntax demo
├── too_many_cooks/               → Multi-agent coordination MCP server
└── too_many_cooks_vscode_extension/ → VSCode extension for agent visualization
```

## Quick Start

```bash
# Build everything from repo root
sh run_dev.sh
```

## Too Many Cooks

The `too_many_cooks` example is a production MCP server published to npm:

```bash
npm install -g too-many-cooks
```

The `too_many_cooks_vscode_extension` provides real-time visualization of agent coordination.
