#!/bin/bash
# Run dart pub get on all packages and examples in dependency order
# Usage: ./tools/pub_get.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Running dart pub get in dependency order..."
echo ""

# Tier 1: Core packages with no internal dependencies
TIER1_PACKAGES=(
  "packages/dart_logging"
  "packages/dart_node_coverage"
  "packages/dart_node_core"
  "packages/reflux"
)

# Tier 2: Packages that depend on Tier 1
TIER2_PACKAGES=(
  "packages/dart_jsx"
  "packages/dart_node_express"
  "packages/dart_node_ws"
  "packages/dart_node_better_sqlite3"
  "packages/dart_node_mcp"
  "packages/dart_node_react"
  "packages/dart_node_react_native"
)

# Tier 3: Examples that depend on packages
TIER3_EXAMPLES=(
  "examples/frontend"
  "examples/markdown_editor"
  "examples/reflux_demo/web_counter"
  "examples/too_many_cooks"
  "examples/backend"
  "examples/mobile"
  "examples/jsx_demo"
)

pub_get() {
  local dir="$1"
  local full_path="$ROOT_DIR/$dir"

  if [[ ! -d "$full_path" ]]; then
    echo "  SKIP $dir (not found)"
    return 0
  fi

  if [[ ! -f "$full_path/pubspec.yaml" ]]; then
    echo "  SKIP $dir (no pubspec.yaml)"
    return 0
  fi

  echo "  $dir..."
  if ! (cd "$full_path" && dart pub get 2>&1 | grep -E "^(Got|Resolving|Changed)" | head -1); then
    echo "    FAILED"
    return 1
  fi
}

npm_install() {
  local dir="$1"
  local full_path="$ROOT_DIR/$dir"

  if [[ -f "$full_path/package.json" ]] && [[ ! -d "$full_path/node_modules" ]]; then
    echo "    npm install..."
    (cd "$full_path" && npm install --silent 2>&1) || true
  fi

  # Check for rn subdirectory (React Native)
  if [[ -f "$full_path/rn/package.json" ]] && [[ ! -d "$full_path/rn/node_modules" ]]; then
    echo "    npm install (rn)..."
    (cd "$full_path/rn" && npm install --silent 2>&1) || true
  fi
}

echo "=== Tier 1: Core packages ==="
for pkg in "${TIER1_PACKAGES[@]}"; do
  pub_get "$pkg"
  npm_install "$pkg"
done

echo ""
echo "=== Tier 2: Dependent packages ==="
for pkg in "${TIER2_PACKAGES[@]}"; do
  pub_get "$pkg"
  npm_install "$pkg"
done

echo ""
echo "=== Tier 3: Examples ==="
for example in "${TIER3_EXAMPLES[@]}"; do
  pub_get "$example"
  npm_install "$example"
done

echo ""
echo "Done!"
