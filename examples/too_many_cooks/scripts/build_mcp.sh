#!/bin/bash
# Build MCP server
set -e
cd "$(dirname "$0")/.."

echo "Building MCP server..."
cd too_many_cooks
dart compile js -o build/bin/server.js bin/server.dart

cd ../../..
dart run tools/build/add_preamble.dart \
  examples/too_many_cooks/too_many_cooks/build/bin/server.js \
  examples/too_many_cooks/too_many_cooks/build/bin/server_node.js \
  --shebang

echo "MCP server built."
