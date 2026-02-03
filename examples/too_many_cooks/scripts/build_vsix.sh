#!/bin/bash
# Build VSCode extension
set -e
cd "$(dirname "$0")/../too_many_cooks_vscode_extension"

echo "Building VSCode extension..."
npm install
npm run compile
npx @vscode/vsce package
echo "VSCode extension built."
