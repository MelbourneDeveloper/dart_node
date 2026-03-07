#!/bin/bash
# Run all e2e tests: MCP clean/build/test → start MCP → VSIX clean/build/test
set -euo pipefail
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS/.." && pwd)"
VSIX_DIR="$ROOT/too_many_cooks_vscode_extension"
source "$SCRIPTS/env.sh"

# 1. Clean, build, and test MCP server
"$SCRIPTS/mcp-server.sh"

# 2. Delete database so MCP starts clean
rm -rf "$VSIX_DIR/.too_many_cooks"

# 3. Kill MCP server on exit
MCP_PID=""
cleanup_mcp() {
  [ -n "$MCP_PID" ] && kill "$MCP_PID" 2>/dev/null || true
}
trap cleanup_mcp EXIT

# 4. Start MCP server with clean database
TMC_WORKSPACE="$VSIX_DIR" \
  node "$ROOT/too_many_cooks/$SERVER_BINARY" &
MCP_PID=$!
sleep 2

# 5. Clean, build, and test VSIX extension
"$SCRIPTS/vscode-extension.sh"
