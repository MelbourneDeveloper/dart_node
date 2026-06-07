#!/bin/bash
# Run dart pub get on all packages and examples in dependency order
# Usage: ./tools/pub_get.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Running dart pub get in dependency order..."
echo ""

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

# Recursively discover EVERY Dart package (path deps resolve regardless of order)
# so no package is silently left without dependencies.
echo "=== All Dart packages (recursive discovery) ==="
while IFS= read -r pub; do
  # Skip Flutter-SDK packages — CI provisions Dart only, so `dart pub get` on
  # them fails. They are excluded from the test matrix too (see tools/test.sh).
  if grep -qE 'sdk:[[:space:]]*flutter' "$pub"; then
    echo "  SKIP ${pub#"$ROOT_DIR"/} (Flutter SDK package)"
    continue
  fi
  rel=${pub#"$ROOT_DIR"/}
  rel=${rel%/pubspec.yaml}
  pub_get "$rel"
  npm_install "$rel"
done < <(find "$ROOT_DIR/packages" "$ROOT_DIR/examples" "$ROOT_DIR/signal_mesh" \
  -name pubspec.yaml -not -path '*/node_modules/*' -not -path '*/.dart_tool/*' \
  -not -path '*/build/*' | sort)

echo ""
echo "Done!"
