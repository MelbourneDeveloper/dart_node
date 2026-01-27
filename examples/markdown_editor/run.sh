#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Markdown Editor ==="
echo ""

# Get Dart dependencies if needed
if [ ! -d ".dart_tool" ]; then
  echo "Getting Dart dependencies..."
  dart pub get
fi

# Build the app
echo "Building app..."
dart compile js web/app.dart -o web/build/app.js -O2

# Serve it
echo ""
echo "Starting server on http://localhost:8080"
echo "Press Ctrl+C to stop"
echo ""
npx serve web -p 8080
