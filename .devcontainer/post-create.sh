#!/bin/bash
# Post-create: install ALL dependencies and pre-build the backend demo
# so ./run_dev.sh works immediately with zero setup
set -euo pipefail

echo "==========================================="
echo "  dart_node dev container setup"
echo "==========================================="
echo ""
echo "Dart: $(dart --version 2>&1)"
echo "Node: $(node --version)"
echo "npm:  $(npm --version)"

# ── 1. Build tool dependencies ──────────────────────────────────────
echo ""
echo "[1/6] Setting up build tool..."
(cd tools/build && dart pub get)

# ── 2. Dart pub get for all packages ────────────────────────────────
echo ""
echo "[2/6] Installing Dart dependencies (packages)..."
for dir in packages/*; do
  [ -d "$dir" ] && [ -f "$dir/pubspec.yaml" ] && {
    echo "  $(basename "$dir")..."
    (cd "$dir" && dart pub get) || echo "  WARNING: pub get failed for $dir"
  }
done

# ── 3. Dart pub get for all examples ────────────────────────────────
echo ""
echo "[3/6] Installing Dart dependencies (examples)..."
for dir in examples/*; do
  [ -d "$dir" ] && [ -f "$dir/pubspec.yaml" ] && {
    echo "  $(basename "$dir")..."
    (cd "$dir" && dart pub get) || echo "  WARNING: pub get failed for $dir"
  }
done

# ── 4. npm install for all packages/examples with package.json ──────
echo ""
echo "[4/6] Installing npm dependencies..."
for dir in packages/* examples/*; do
  [ -d "$dir" ] && [ -f "$dir/package.json" ] && {
    echo "  npm install: $(basename "$dir")..."
    (cd "$dir" && npm install) || echo "  WARNING: npm install failed for $dir"
  }
done

# Handle nested React Native dir
[ -d "examples/mobile/rn" ] && [ -f "examples/mobile/rn/package.json" ] && {
  echo "  npm install: mobile/rn..."
  (cd examples/mobile/rn && npm install) || echo "  WARNING: npm install failed for mobile/rn"
}

# Website deps
[ -d "website" ] && [ -f "website/package.json" ] && {
  echo "  npm ci: website..."
  (cd website && npm ci) || echo "  WARNING: npm ci failed for website"
}

# ── 5. Pre-build the backend demo ───────────────────────────────────
echo ""
echo "[5/6] Pre-building backend demo..."
dart run tools/build/build.dart backend

# ── 6. Playwright browsers (for website tests) ──────────────────────
echo ""
echo "[6/6] Installing Playwright browsers..."
(cd website && npx playwright install chromium) 2>/dev/null || echo "  Playwright install skipped (optional)"

# Ensure coverage tool is available
dart pub global activate coverage 2>/dev/null || true

echo ""
echo "==========================================="
echo "  Setup complete!"
echo ""
echo "  Run the demo:  ./run_dev.sh"
echo "  Or manually:   node examples/backend/build/server.js"
echo "  API at:        http://localhost:3000"
echo "==========================================="
