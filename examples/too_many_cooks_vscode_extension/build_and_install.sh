#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Uninstalling existing installations ==="
claude mcp remove too-many-cooks 2>/dev/null || true
code --uninstall-extension christianfindlay.too-many-cooks 2>/dev/null || true

echo "=== Building ==="
./build.sh

echo "=== Installing MCP Server in Claude Code ==="
SERVER_PATH="$(pwd)/../too_many_cooks/build/bin/server_node.js"
claude mcp add --transport stdio too-many-cooks --scope user -- node "$SERVER_PATH"

echo "=== Installing VSCode Extension ==="
VSIX=$(ls -t *.vsix | head -1)
code --install-extension "$VSIX" --force

echo ""
echo "Done! Restart VSCode to activate."
echo "Verify MCP with: claude mcp list"
