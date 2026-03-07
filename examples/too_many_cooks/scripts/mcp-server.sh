#!/bin/bash
# MCP server: clean, build, and test
set -euo pipefail
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS/.." && pwd)"
source "$SCRIPTS/env.sh"

# 1. Clean MCP build
rm -rf "$ROOT/too_many_cooks/build"

# 2. Compile Dart to JS
cd "$ROOT/too_many_cooks"
dart compile js -o build/bin/server.js bin/server.dart

# 3. Add Node.js preamble to compiled JS
cd "$ROOT/../.."
dart run tools/build/add_preamble.dart \
  examples/too_many_cooks/too_many_cooks/build/bin/server.js \
  "examples/too_many_cooks/too_many_cooks/$SERVER_BINARY" \
  --shebang

# 4. Run data package tests
cd "$ROOT/too_many_cooks_data"
dart test

# 5. Run MCP server tests
cd "$ROOT/too_many_cooks"
dart test
