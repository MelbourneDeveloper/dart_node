#!/bin/bash
# MCP server: clean, build, and test
set -euo pipefail
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS/.." && pwd)"
source "$SCRIPTS/env.sh"

rm -rf "$ROOT/too_many_cooks/build"

cd "$ROOT/too_many_cooks"
dart compile js -o build/bin/server.js bin/server.dart

cd "$ROOT/../.."
dart run tools/build/add_preamble.dart \
  examples/too_many_cooks/too_many_cooks/build/bin/server.js \
  "examples/too_many_cooks/too_many_cooks/$SERVER_BINARY" \
  --shebang

cd "$ROOT/too_many_cooks_data"
dart test

cd "$ROOT/too_many_cooks"
dart test
