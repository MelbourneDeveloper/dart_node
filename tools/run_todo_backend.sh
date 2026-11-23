#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building Too Many Cooks server..."
cd ../too_many_cooks
./build.sh
cd ../too_many_cooks_vscode_extension

echo "Installing npm dependencies..."
npm install

echo "Compiling TypeScript..."
npm run compile

echo "Packaging extension..."
npx @vscode/vsce package --no-dependencies

VSIX=$(ls -t *.vsix | head -1)
echo "Installing $VSIX in VSCode..."
code --install-extension "$VSIX" --force

echo "Done. Restart VSCode to activate."
