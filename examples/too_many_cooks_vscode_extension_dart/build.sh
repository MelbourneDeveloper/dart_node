#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Building Too Many Cooks MCP Server ==="
cd ../too_many_cooks
dart compile js -o build/bin/server.js bin/server.dart
cd ../..
dart run tools/build/add_preamble.dart \
  examples/too_many_cooks/build/bin/server.js \
  examples/too_many_cooks/build/bin/server_node.js \
  --shebang

echo "=== Building VSCode Extension (Dart) ==="
cd examples/too_many_cooks_vscode_extension_dart
dart compile js -O2 -o out/extension.dart.js lib/extension.dart
node scripts/wrap-extension.js

echo "=== Building Integration Tests (Dart) ==="
# Compile each test file to JS
for testfile in test/suite/*.test.dart; do
  if [ -f "$testfile" ]; then
    outfile="out/test/suite/$(basename "${testfile%.dart}.js")"
    mkdir -p "$(dirname "$outfile")"
    echo "Compiling $testfile -> $outfile"
    dart compile js -O0 -o "$outfile" "$testfile"
  fi
done

# Copy test runner index.js
mkdir -p out/test/suite
cp test/suite/index.js out/test/suite/

echo "=== Packaging VSIX ==="
npx @vscode/vsce package

echo ""
echo "Build complete!"
