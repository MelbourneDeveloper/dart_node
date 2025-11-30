#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Getting dependencies..."
dart pub get

echo "Compiling Dart to JavaScript..."
mkdir -p build
dart compile js web/app.dart -o build/app.js -O2

echo "Build complete! Open web/index.html in your browser."
