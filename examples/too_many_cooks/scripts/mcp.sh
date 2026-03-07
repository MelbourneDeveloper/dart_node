#!/bin/bash
# MCP server operations: clean, build, install, install-cline, uninstall
set -e
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS/.." && pwd)"
source "$SCRIPTS/env.sh"

usage() {
  echo "Usage: $0 {clean|build|install|install-cline|uninstall}"
  exit 1
}

cmd_clean() {
  rm -rf "$ROOT/too_many_cooks/build"
  echo "MCP build cleaned."
}

cmd_build() {
  echo "Building MCP server..."
  cd "$ROOT/too_many_cooks"
  dart compile js -o build/bin/server.js bin/server.dart

  cd "$ROOT/../.."
  dart run tools/build/add_preamble.dart \
    examples/too_many_cooks/too_many_cooks/build/bin/server.js \
    "examples/too_many_cooks/too_many_cooks/$SERVER_BINARY" \
    --shebang

  echo "Done: examples/too_many_cooks/too_many_cooks/$SERVER_BINARY"
  echo "MCP server built."
}

cmd_install() {
  SERVER_PATH="$(cd "$ROOT/too_many_cooks" && pwd)/$SERVER_BINARY"

  if [ ! -f "$SERVER_PATH" ]; then
    echo "Error: MCP server not built. Run '$0 build' first."
    exit 1
  fi

  WORKSPACE_ROOT="$(cd "$ROOT/../.." && pwd)"

  # Remove existing if present (ignore errors)
  claude mcp remove too-many-cooks --scope user 2>/dev/null || true

  claude mcp add --transport stdio too-many-cooks --scope user \
    -e TMC_WORKSPACE="$WORKSPACE_ROOT" \
    -- node "$SERVER_PATH"

  echo "MCP installed in Claude Code."
  echo "TMC_WORKSPACE=$WORKSPACE_ROOT"
  echo "Database: $WORKSPACE_ROOT/.too_many_cooks/data.db"
  echo "Verify: claude mcp list"
}

cmd_install_cline() {
  SERVER_PATH="$(cd "$ROOT/too_many_cooks" && pwd)/$SERVER_BINARY"

  if [ ! -f "$SERVER_PATH" ]; then
    echo "Error: MCP server not built. Run '$0 build' first."
    exit 1
  fi

  WORKSPACE_ROOT="$(cd "$ROOT/../.." && pwd)"
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
}

cmd_uninstall() {
  claude mcp remove too-many-cooks 2>/dev/null || true
  echo "MCP uninstalled from Claude Code."
}

case "${1:-}" in
  clean)          cmd_clean ;;
  build)          cmd_build ;;
  install)        cmd_install ;;
  install-cline)  cmd_install_cline ;;
  uninstall)      cmd_uninstall ;;
  *)              usage ;;
esac
