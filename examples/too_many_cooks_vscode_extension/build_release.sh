#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building Too Many Cooks VSCode Extension..."

# Install dependencies
echo "Installing dependencies..."
npm install

# Compile TypeScript
echo "Compiling TypeScript..."
npm run compile

# Check if vsce is installed
if ! command -v vsce &> /dev/null; then
  echo "Installing vsce..."
  npm install -g @vscode/vsce
fi

# Package the extension
echo "Packaging extension..."
vsce package

echo ""
echo "Build complete! The .vsix file is ready for publishing."
echo ""
echo "To publish to the marketplace:"
echo "  vsce publish"
echo ""
echo "To install locally for testing:"
echo "  code --install-extension too-many-cooks-*.vsix"
