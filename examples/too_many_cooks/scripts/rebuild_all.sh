#!/bin/bash
# Clean, build, and install everything
set -e
SCRIPTS="$(dirname "$0")"

"$SCRIPTS/uninstall_mcp.sh"
"$SCRIPTS/uninstall_vsix.sh"
"$SCRIPTS/clean_mcp.sh"
"$SCRIPTS/clean_vsix.sh"
"$SCRIPTS/build_mcp.sh"
"$SCRIPTS/build_vsix.sh"
"$SCRIPTS/install_mcp.sh"
"$SCRIPTS/install_vsix.sh"

echo ""
echo "All done. Restart VSCode to activate."
