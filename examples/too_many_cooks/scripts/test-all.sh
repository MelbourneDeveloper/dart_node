#!/bin/bash
# Run all e2e tests
set -euo pipefail
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

"$SCRIPTS/mcp-server.sh"
"$SCRIPTS/vscode-extension.sh"
