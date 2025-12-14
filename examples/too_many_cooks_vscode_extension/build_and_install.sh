#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Uninstalling existing installations ==="
claude mcp remove too-many-cooks 2>/dev/null || true
code --uninstall-extension christianfindlay.too-many-cooks 2>/dev/null || true

echo "=== Deleting global database (fresh state) ==="
rm -rf ~/.too_many_cooks/data.db ~/.too_many_cooks/data.db-wal ~/.too_many_cooks/data.db-shm

echo "=== Building MCP Server (local dart2js build) ==="
pushd ../too_many_cooks > /dev/null
rm -rf build/bin/server_node.js
dart run tools/build/build.dart
popd > /dev/null

# Get absolute path to local server
SERVER_PATH="$(cd ../too_many_cooks && pwd)/build/bin/server_node.js"
echo "Local server: $SERVER_PATH"

echo "=== Building VSCode extension ==="
./build.sh

echo "=== Installing MCP Server in Claude Code (LOCAL build) ==="
claude mcp add --transport stdio too-many-cooks --scope user -- node "$SERVER_PATH"

echo "=== Installing VSCode Extension ==="
VSIX=$(ls -t *.vsix | head -1)
code --install-extension "$VSIX" --force

echo ""
echo "Done! Restart VSCode to activate."
echo "Claude Code uses LOCAL server: $SERVER_PATH"
echo "VSCode extension uses: npx too-many-cooks (will need npm publish for admin tools)"
echo ""
echo "IMPORTANT: To use admin tools in VSCode, publish 0.3.0 first:"
echo "  cd ../too_many_cooks && npm publish"
echo ""
echo "Verify MCP with: claude mcp list"
