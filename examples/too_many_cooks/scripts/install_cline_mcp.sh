#!/bin/bash
# Install MCP server config for Cline VSCode extension.
# Cline has no per-workspace MCP config, so this writes to the global settings file.
set -e
cd "$(dirname "$0")/.."

source "$(dirname "$0")/env.sh"
SERVER_PATH="$(cd too_many_cooks && pwd)/$SERVER_BINARY"

if [ ! -f "$SERVER_PATH" ]; then
  echo "Error: MCP server not built. Run build_mcp.sh first."
  exit 1
fi

WORKSPACE_ROOT="$(cd ../.. && pwd)"

CLINE_SETTINGS="$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"

if [ ! -d "$(dirname "$CLINE_SETTINGS")" ]; then
  echo "Error: Cline settings directory not found. Is Cline installed?"
  exit 1
fi

cat > "$CLINE_SETTINGS" <<EOF
{
  "mcpServers": {
    "too-many-cooks": {
      "disabled": false,
      "timeout": 60,
      "type": "stdio",
      "command": "node",
      "args": [
        "$SERVER_PATH"
      ],
      "env": {
        "TMC_WORKSPACE": "$WORKSPACE_ROOT"
      }
    }
  }
}
EOF

echo "Cline MCP config written to:"
echo "  $CLINE_SETTINGS"
echo "TMC_WORKSPACE=$WORKSPACE_ROOT"
echo "Database: $WORKSPACE_ROOT/.too_many_cooks/data.db"
