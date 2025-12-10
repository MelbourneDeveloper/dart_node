#!/bin/bash
set -e
cd "$(dirname "$0")"

SERVER_PATH="$(pwd)/build/bin/server_node.js"

if [ ! -f "$SERVER_PATH" ]; then
  echo "Server not built. Run ./build.sh first"
  exit 1
fi

echo "Installing Too Many Cooks MCP server in Claude Code..."
claude mcp remove too-many-cooks 2>/dev/null || true
claude mcp add --transport stdio too-many-cooks --scope user -- node "$SERVER_PATH"

echo "Installed. Verify with: claude mcp list"
