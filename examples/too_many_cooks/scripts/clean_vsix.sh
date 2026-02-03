#!/bin/bash
# Clean VSCode extension build artifacts
set -e
cd "$(dirname "$0")/.."

rm -rf too_many_cooks_vscode_extension/*.vsix
rm -rf too_many_cooks_vscode_extension/out
echo "VSIX build cleaned."
