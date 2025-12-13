#!/bin/bash
# Run tests for a tier - detects package type and runs appropriate test method
# Usage: ./tools/test_tier.sh <min_coverage> <package1> <package2> ...

set -e

MIN_COVERAGE=$1
shift

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
COVERAGE_CLI="$ROOT_DIR/packages/dart_node_coverage/bin/coverage.dart"

# Node.js packages use dart_node_coverage
NODE_PACKAGES="dart_node_core dart_node_express dart_node_ws dart_node_better_sqlite3 dart_node_mcp dart_node_react_native"

# Browser packages use dart test -p chrome (no coverage)
BROWSER_PACKAGES="dart_node_react frontend"

# TypeScript/npm packages use npm test
NPM_PACKAGES="too_many_cooks_vscode_extension"

is_node_package() {
  local name=$(basename "$1")
  [[ " $NODE_PACKAGES " =~ " $name " ]]
}

is_browser_package() {
  local name=$(basename "$1")
  [[ " $BROWSER_PACKAGES " =~ " $name " ]]
}

is_npm_package() {
  local name=$(basename "$1")
  [[ " $NPM_PACKAGES " =~ " $name " ]]
}

check_coverage() {
  local name=$1
  local lcov_file=$2
  if [ -f "$lcov_file" ]; then
    COVERAGE=$(awk -F: '/^LF:/ { total += $2 } /^LH:/ { covered += $2 } END { if (total > 0) printf "%.1f", (covered / total) * 100; else print "0" }' "$lcov_file")
    echo "$name coverage: ${COVERAGE}%"
    if [ -z "$COVERAGE" ] || [ "$COVERAGE" = "0" ] || [ "$(echo "$COVERAGE < $MIN_COVERAGE" | bc -l)" -eq 1 ]; then
      echo "Coverage ${COVERAGE}% is below ${MIN_COVERAGE}% threshold"
      return 1
    fi
  fi
  return 0
}

pids=""
for dir in "$@"; do
  name=$(basename "$dir")
  (
    cd "$ROOT_DIR/$dir"

    if is_npm_package "$dir"; then
      # TypeScript/npm package
      npm install
      npm test
      echo "$name: npm tests passed"
    elif is_node_package "$dir"; then
      # Node.js package - use dart_node_coverage
      dart run "$COVERAGE_CLI"
      check_coverage "$name" "coverage/lcov.info"
    elif is_browser_package "$dir"; then
      # Browser package - no coverage
      dart test -p chrome
      echo "$name: browser tests passed"
    else
      # VM package - standard dart test with coverage
      dart test --coverage=coverage
      dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
      check_coverage "$name" "coverage/lcov.info"
    fi
  ) &
  pids="$pids $!"
done

failed=0
for pid in $pids; do
  wait $pid || failed=1
done
exit $failed
