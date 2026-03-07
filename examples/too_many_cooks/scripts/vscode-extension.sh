#!/bin/bash
# VSCode extension: clean, build, and test (MCP must already be running)
set -euo pipefail
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPTS/.." && pwd)"
VSIX_DIR="$ROOT/too_many_cooks_vscode_extension"

# 1. Clean VSIX build artifacts
rm -rf "$VSIX_DIR"/*.vsix "$VSIX_DIR/out"

cd "$VSIX_DIR"

# 2. Install npm dependencies
npm install

# 3. Compile extension source (src/ → out/)
npm run compile

# 4. Compile test source (test/ → out/test/)
npm run compile:test

# 5. Run VSIX e2e tests (launches VS Code with extension)
npm run test
