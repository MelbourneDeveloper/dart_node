#!/bin/bash
# Post-create: install deps and pre-build so run_taskflow.sh just works
set -euo pipefail

echo "==========================================="
echo "  dart_node dev container setup"
echo "==========================================="
echo ""
echo "Dart: $(dart --version 2>&1)"
echo "Node: $(node --version)"
echo "npm:  $(npm --version)"

# ── 1. Build tool ────────────────────────────────────────────────────
echo ""
echo "[1/4] Setting up build tool..."
(cd tools/build && dart pub get)

# ── 2. Dart pub get ──────────────────────────────────────────────────
echo ""
echo "[2/4] Installing Dart dependencies..."
for dir in packages/* examples/*; do
  [ -d "$dir" ] && [ -f "$dir/pubspec.yaml" ] && {
    echo "  $(basename "$dir")..."
    (cd "$dir" && dart pub get) || echo "  WARNING: pub get failed for $dir"
  }
done

# ── 3. npm install ───────────────────────────────────────────────────
echo ""
echo "[3/4] Installing npm dependencies..."
for dir in packages/* examples/*; do
  [ -d "$dir" ] && [ -f "$dir/package.json" ] && {
    if [ -f "$dir/package-lock.json" ]; then
      echo "  npm ci: $(basename "$dir")..."
      (cd "$dir" && npm ci) || echo "  WARNING: npm ci failed for $dir"
    else
      echo "  npm install: $(basename "$dir")..."
      (cd "$dir" && npm install) || echo "  WARNING: npm install failed for $dir"
    fi
  }
done

# ── 4. Pre-build backend ────────────────────────────────────────────
echo ""
echo "[4/4] Pre-building backend..."
dart run tools/build/build.dart backend

echo ""
echo "==========================================="
echo "  Setup complete!"
echo ""
echo "  Run the demo:  sh examples/run_taskflow.sh"
echo "  Or manually:   node examples/backend/build/server.js"
echo "  API at:        http://localhost:3000"
echo "==========================================="
