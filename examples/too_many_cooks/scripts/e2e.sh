#!/bin/bash
# End-to-end test: clean → build MCP → MCP tests → VSIX tests (spawns server)
set -e
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS/.." && pwd)"

echo "=== 1. Clean ==="
"$SCRIPTS/mcp.sh" clean
"$SCRIPTS/vsix.sh" clean
echo ""

echo "=== 2. Build MCP server ==="
"$SCRIPTS/mcp.sh" build
echo ""

echo "=== 3. Data package tests ==="
cd "$ROOT/too_many_cooks_data"
dart test
echo ""

echo "=== 4. MCP server tests ==="
cd "$ROOT/too_many_cooks"
dart test
echo ""

echo "=== 5. VSIX extension tests ==="
cd "$ROOT/too_many_cooks_vscode_extension"
npm run compile
npm run compile:tests
npx vscode-test
echo ""

echo "=== All e2e tests passed! ==="
