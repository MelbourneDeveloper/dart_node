#!/bin/bash
# Install MCP server in Claude Code
set -e
cd "$(dirname "$0")/.."

SERVER_PATH="$(cd too_many_cooks && pwd)/build/bin/server_node.js"

if [ ! -f "$SERVER_PATH" ]; then
  echo "Error: MCP server not built. Run build_mcp.sh first."
  exit 1
fi

claude mcp add --transport stdio too-many-cooks --scope user -- node "$SERVER_PATH"
echo "MCP installed in Claude Code."
echo "Verify: claude mcp list"
