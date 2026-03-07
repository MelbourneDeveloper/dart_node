#!/bin/bash
# Run all e2e tests: MCP clean/build/test → start MCP → VSIX clean/build/test
set -euo pipefail
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS/.." && pwd)"
source "$SCRIPTS/env.sh"

# 1. Clean, build, and test MCP server
"$SCRIPTS/mcp-server.sh"

# 2. Kill MCP server on exit
MCP_PID=""
cleanup_mcp() {
  [ -n "$MCP_PID" ] && kill "$MCP_PID" 2>/dev/null || true
}
trap cleanup_mcp EXIT

# 3. Start MCP server (workspace = extension folder so DB path matches cleanDatabase())
TMC_WORKSPACE="$ROOT/too_many_cooks_vscode_extension" \
  node "$ROOT/too_many_cooks/$SERVER_BINARY" &
MCP_PID=$!
sleep 2

# 4. Clean, build, and test VSIX extension
"$SCRIPTS/vscode-extension.sh"
