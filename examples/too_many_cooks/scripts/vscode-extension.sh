#!/bin/bash
# VSCode extension: clean, build, and test
set -euo pipefail
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS/.." && pwd)"
VSIX_DIR="$ROOT/too_many_cooks_vscode_extension"
source "$SCRIPTS/env.sh"

rm -rf "$VSIX_DIR"/*.vsix "$VSIX_DIR/out"

cd "$VSIX_DIR"
npm install
npm run compile
npm run compile:test

MCP_PID=""
cleanup_mcp() {
  [ -n "$MCP_PID" ] && kill "$MCP_PID" 2>/dev/null || true
}
trap cleanup_mcp EXIT

TMC_WORKSPACE="$ROOT/../.." node "$ROOT/too_many_cooks/$SERVER_BINARY" &
MCP_PID=$!
sleep 2

npm run test
