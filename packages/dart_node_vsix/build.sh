#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Building dart_node_vsix test extension ==="

# Get dependencies
echo "Getting dependencies..."
dart pub get

# Create build directories
mkdir -p build/bin build/test/suite

# Compile extension
echo "Compiling extension..."
dart compile js lib/extension.dart -o build/bin/extension.js -O2

# Compile tests
echo "Compiling tests..."
for f in test/suite/*_test.dart; do
  name=$(basename "$f" .dart)
  echo "  Compiling $name..."
  dart compile js "$f" -o "build/test/suite/$name.js" -O2
done

# Wrap with vscode require
echo "Wrapping extension..."
node scripts/wrap-extension.js

echo "Wrapping tests..."
node scripts/wrap-tests.js

# Copy test index.js (JavaScript bootstrap for Mocha)
echo "Copying test index.js..."
cp test/suite/index.js out/test/suite/

echo "=== Build complete ==="
