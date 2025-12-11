#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building Too Many Cooks MCP server..."
dart compile js -o build/bin/server.js bin/server.dart

cd ../..
dart run tools/build/add_preamble.dart \
  examples/too_many_cooks/build/bin/server.js \
  examples/too_many_cooks/build/bin/server_node.js \
  --shebang

echo "Build complete: examples/too_many_cooks/build/bin/server_node.js"
