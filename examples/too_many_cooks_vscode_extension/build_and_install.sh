#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Uninstalling existing installations ==="
claude mcp remove too-many-cooks 2>/dev/null || true
code --uninstall-extension christianfindlay.too-many-cooks 2>/dev/null || true

echo "=== Deleting global database (fresh state) ==="
rm -rf ~/.too_many_cooks/data.db ~/.too_many_cooks/data.db-wal ~/.too_many_cooks/data.db-shm

echo "=== Cleaning old build ==="
rm -rf ../too_many_cooks/build

echo "=== Building MCP Server ==="
REPO_ROOT="$(cd ../.. && pwd)"
cd "$REPO_ROOT"
dart run tools/build/build.dart too_many_cooks
cd "$REPO_ROOT/examples/too_many_cooks_vscode_extension"
SERVER_PATH="$(cd ../too_many_cooks && pwd)/build/bin/server.js"

echo "=== Building VSCode extension ==="
npm install
npm run compile
npx @vscode/vsce package

echo "=== Installing MCP Server in Claude Code (LOCAL build) ==="
claude mcp add --transport stdio too-many-cooks --scope user -- node "$SERVER_PATH"

echo "=== Installing VSCode Extension ==="
VSIX=$(ls -t *.vsix | head -1)
code --install-extension "$VSIX" --force

echo ""
echo "Done! Restart VSCode to activate."
echo "Verify: claude mcp list"
echo "MCP logs: ~/Library/Caches/claude-cli-nodejs/*/mcp-logs-too-many-cooks/"
