#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Uninstalling existing installations ==="
claude mcp remove too-many-cooks 2>/dev/null || true
code --uninstall-extension christianfindlay.too-many-cooks 2>/dev/null || true

echo "=== Building MCP Server ==="
pushd ../too_many_cooks > /dev/null
rm -rf build/bin/server_node.js
popd > /dev/null

echo "=== Building VSCode extension ==="
./build.sh

echo "=== Installing MCP Server in Claude Code ==="
claude mcp add --transport stdio too-many-cooks --scope user -- npx too-many-cooks

echo "=== Installing VSCode Extension ==="
VSIX=$(ls -t *.vsix | head -1)
code --install-extension "$VSIX" --force

echo ""
echo "Done! Restart VSCode to activate."
echo "Both Claude Code and VSCode now use: npx too-many-cooks"
echo "Verify MCP with: claude mcp list"
