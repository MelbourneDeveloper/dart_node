#!/bin/bash
# Run ALL tests across all Too Many Cooks packages.
set -e
SCRIPTS="$(dirname "$0")"
ROOT="$(cd "$SCRIPTS/.." && pwd)"

echo "=== Data package tests ==="
cd "$ROOT/too_many_cooks_data"
dart test
echo ""

echo "=== MCP server build ==="
cd "$ROOT/too_many_cooks"
dart compile js -O0 -o build/bin/server.js bin/server.dart
cd "$ROOT/../.."
dart run tools/build/add_preamble.dart \
  examples/too_many_cooks/too_many_cooks/build/bin/server.js \
  examples/too_many_cooks/too_many_cooks/build/bin/server_node.js
echo ""

echo "=== MCP server tests ==="
cd "$ROOT/too_many_cooks"
dart test
echo ""

echo "=== VSIX extension tests (dart test) ==="
cd "$ROOT/too_many_cooks_vscode_extension"
dart test
echo ""

echo "=== VSIX extension suite tests (npm test) ==="
cd "$ROOT/too_many_cooks_vscode_extension"
npm test
echo ""

echo "All tests passed!"
