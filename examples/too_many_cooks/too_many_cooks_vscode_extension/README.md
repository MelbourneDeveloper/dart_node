# Too Many Cooks VSCode Extension

VSCode extension for visualizing multi-agent coordination. See [spec](../docs/spec.md).

Talks to the TMC server via `/admin/*` REST endpoints. Receives all state changes via SSE push — no polling. Does **not** access the database directly. Provides tree views for agents, locks, messages, and plans. Admin operations (delete agent, delete lock, reset key, send message) available via command palette.

## Build

```bash
cd examples/too_many_cooks/scripts
bash build_vsix.sh
```

## Install

```bash
bash scripts/install_vsix.sh
```

## Test

```bash
npm test
```

## License

MIT
