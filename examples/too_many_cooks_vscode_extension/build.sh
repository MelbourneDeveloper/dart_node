#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Building Too Many Cooks MCP Server ==="
cd ../too_many_cooks
dart compile js -o build/bin/server.js bin/server.dart
cd ../..
dart run tools/build/add_preamble.dart \
  examples/too_many_cooks/build/bin/server.js \
  examples/too_many_cooks/build/bin/server_node.js \
  --shebang

echo "=== Building VSCode Extension ==="
cd examples/too_many_cooks_vscode_extension
npm install
npm run compile
npx @vscode/vsce package

echo ""
echo "Build complete!"
