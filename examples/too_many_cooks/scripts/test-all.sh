#!/bin/bash
set -euo pipefail
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS/.." && pwd)"
VSIX_DIR="$ROOT/too_many_cooks_vscode_extension"
SERVER_BINARY="build/bin/server_node.js"

# 1. Clean MCP
rm -rf "$ROOT/too_many_cooks/build"

# 2. Build MCP
cd "$ROOT/too_many_cooks"
dart compile js -o build/bin/server.js bin/server.dart
cd "$ROOT/../.."
dart run tools/build/add_preamble.dart \
  examples/too_many_cooks/too_many_cooks/build/bin/server.js \
  "examples/too_many_cooks/too_many_cooks/$SERVER_BINARY" \
  --shebang

# 3. Clean VSIX
rm -rf "$VSIX_DIR"/*.vsix "$VSIX_DIR/out"

# 4. Build VSIX
cd "$VSIX_DIR"
npm install
npm run compile
npm run compile:test

# 5. Delete database
rm -rf "$VSIX_DIR/.too_many_cooks"

# 6. Start MCP server
cleanup_mcp() { [ -n "${MCP_PID:-}" ] && kill "$MCP_PID" 2>/dev/null || true; }
trap cleanup_mcp EXIT
TMC_WORKSPACE="$VSIX_DIR" node "$ROOT/too_many_cooks/$SERVER_BINARY" &
MCP_PID=$!

# Poll until server is ready (max 10s)
for i in $(seq 1 50); do
  if curl -sf http://localhost:4040/admin/status >/dev/null 2>&1; then
    echo "MCP server ready (attempt $i)"
    break
  fi
  if [ "$i" -eq 50 ]; then
    echo "MCP server failed to start"
    exit 1
  fi
  sleep 0.2
done

# 7. Run VSIX tests
npm run test
