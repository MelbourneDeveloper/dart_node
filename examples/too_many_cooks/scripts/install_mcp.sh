#!/bin/bash
# Install MCP server in Claude Code
set -e
cd "$(dirname "$0")/.."

SERVER_PATH="$(cd too_many_cooks && pwd)/build/bin/server_node.js"

if [ ! -f "$SERVER_PATH" ]; then
  echo "Error: MCP server not built. Run build_mcp.sh first."
  exit 1
fi

# Detect workspace root (git root or parent of examples/)
WORKSPACE_ROOT="$(cd ../.. && pwd)"

# Remove existing if present (ignore errors)
claude mcp remove too-many-cooks --scope user 2>/dev/null || true

# Install with TMC_WORKSPACE so the MCP server uses the same DB as the VSIX
claude mcp add --transport stdio too-many-cooks --scope user \
  -e TMC_WORKSPACE="$WORKSPACE_ROOT" \
  -- node "$SERVER_PATH"

echo "MCP installed in Claude Code."
echo "TMC_WORKSPACE=$WORKSPACE_ROOT"
echo "Database: $WORKSPACE_ROOT/.too_many_cooks/data.db"
echo "Verify: claude mcp list"
