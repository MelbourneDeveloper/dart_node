# Too Many Cooks

Multi-agent coordination MCP server. See [spec](../docs/spec.md) for full documentation.

## Build

```bash
cd examples/too_many_cooks/scripts
bash build_mcp.sh
```

Output: `build/bin/server_node.js`

## Install

**Claude Code:**
```bash
bash scripts/install_mcp.sh
```

**Cline:**
```bash
bash scripts/install_cline_mcp.sh
```

## Run

```bash
node build/bin/server_node.js
```

Set `TMC_WORKSPACE` env var to workspace folder (falls back to `process.cwd()`).

## Test

```bash
dart test
```

## Example CLAUDE.md Rules

```markdown
## Multi-Agent Coordination (Too Many Cooks)
- Keep your key! If disconnected, reconnect by calling register with ONLY your key
- Check messages regularly, lock files before editing, unlock after
- Don't edit locked files; signal intent via plans and messages
- Do not use Git unless asked by user
```

## License

MIT
