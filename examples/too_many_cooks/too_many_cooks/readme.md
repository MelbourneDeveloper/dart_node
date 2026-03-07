# Too Many Cooks

Multi-agent coordination MCP server. See [spec](../docs/spec.md) for full documentation.

## Build

```bash
bash scripts/mcp.sh build
```

## Install

**Claude Code:**
```bash
bash scripts/mcp.sh install
```

**Cline:**
```bash
bash scripts/mcp.sh install-cline
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
