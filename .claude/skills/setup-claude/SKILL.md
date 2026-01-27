---
name: setup-claude
description: Install Claude Code CLI and the Too Many Cooks VSCode extension for multi-agent development
disable-model-invocation: true
allowed-tools: Bash
---

# Install Claude Code & Extension

Sets up Claude Code CLI and the Too Many Cooks VSCode extension for multi-agent coordination.

## Step 1: Install Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
```

Verify:
```bash
claude --version
```

## Step 2: Build the Too Many Cooks VSCode Extension

The extension provides visual agent coordination (locks, messages, plans) via the MCP server.

### 2a. Build the MCP Server first

```bash
cd examples/too_many_cooks && dart pub get && npm install
dart compile js -o examples/too_many_cooks/build/bin/server.js examples/too_many_cooks/bin/server.dart
dart run tools/build/add_preamble.dart \
  examples/too_many_cooks/build/bin/server.js \
  examples/too_many_cooks/build/bin/server_node.js \
  --shebang
```

### 2b. Build and package the extension

```bash
cd examples/too_many_cooks_vscode_extension
npm install
npm run compile
npx @vscode/vsce package
```

This creates a `.vsix` file in `examples/too_many_cooks_vscode_extension/`.

### 2c. Install the extension

```bash
code --install-extension examples/too_many_cooks_vscode_extension/*.vsix
```

Or use the full build script that does steps 2a-2b:
```bash
bash examples/too_many_cooks_vscode_extension/build.sh
```

## Step 3: Configure Claude Code for this project

The project's `.claude/settings.local.json` already has the required permissions:
- `Bash(dart pub get:*)` — dependency installation
- `mcp__too-many-cooks__register` — MCP agent registration
- `Bash(docker ps:*)` — Docker status checks

Custom skills are in `.claude/skills/` — run `/help` to see them.

## Multi-Agent Usage

After setup, agents coordinate via the Too Many Cooks MCP server:
- **Lock files** before editing, unlock after
- **Check messages** regularly between agents
- **Update plans** so other agents can see your intent
- Keep your agent key — it's critical for authentication
