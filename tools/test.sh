#!/bin/bash
# Unified test runner - parallel execution with fail-fast and coverage
# Usage: ./tools/test.sh [--tier N] [package...]
#
# Options:
#   --tier N    Only run tier N (1, 2, or 3)
#   package...  Specific packages/examples to test
#
# Without arguments: runs all packages and examples

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$ROOT_DIR/logs"
COVERAGE_CLI="$ROOT_DIR/packages/dart_node_coverage/bin/coverage.dart"

# Minimum coverage threshold (can be overridden by MIN_COVERAGE env var)
MIN_COVERAGE="${MIN_COVERAGE:-80}"

# Package type definitions
NODE_PACKAGES="dart_node_core dart_node_express dart_node_ws dart_node_better_sqlite3"
NODE_INTEROP_PACKAGES="dart_node_mcp dart_node_react_native too_many_cooks"
BROWSER_PACKAGES="dart_node_react frontend"
NPM_PACKAGES="too_many_cooks_vscode_extension"
BUILD_FIRST="too_many_cooks"

# Tier definitions (space-separated paths)
TIER1="packages/dart_logging packages/dart_node_core"
TIER2="packages/reflux packages/dart_node_express packages/dart_node_ws packages/dart_node_better_sqlite3 packages/dart_node_mcp packages/dart_node_react_native packages/dart_node_react"
TIER3="examples/frontend examples/markdown_editor examples/reflux_demo/web_counter examples/too_many_cooks"

# Exclusion list (package names to skip)
EXCLUDED="too_many_cooks too_many_cooks_vscode_extension"

# Helper functions
is_type() {
  local name=$(basename "$1")
  local list="$2"
  [[ " $list " =~ " $name " ]]
}

is_excluded() {
  local name=$(basename "$1")
  [[ " $EXCLUDED " =~ " $name " ]]
}

calc_coverage() {
  local lcov="$1"
  [[ -f "$lcov" ]] || { echo "0"; return; }
  awk -F: '/^LF:/ { total += $2 } /^LH:/ { covered += $2 } END { if (total > 0) printf "%.1f", (covered / total) * 100; else print "0" }' "$lcov"
}

# Parse arguments
TIER=""
PACKAGES=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --tier) TIER="$2"; shift 2 ;;
    *) PACKAGES+=("$1"); shift ;;
  esac
done

# Determine what to test (as tiers)
TIERS_TO_RUN=()

if [[ ${#PACKAGES[@]} -gt 0 ]]; then
  # Specific packages - run as single tier
  TIERS_TO_RUN+=("${PACKAGES[*]}")
elif [[ -n "$TIER" ]]; then
  # Single tier
  case $TIER in
    1) TIERS_TO_RUN+=("$TIER1") ;;
    2) TIERS_TO_RUN+=("$TIER2") ;;
    3) TIERS_TO_RUN+=("$TIER3") ;;
    *) echo "Invalid tier: $TIER"; exit 1 ;;
  esac
else
  # All tiers - run sequentially
  TIERS_TO_RUN+=("$TIER1")
  TIERS_TO_RUN+=("$TIER2")
  TIERS_TO_RUN+=("$TIER3")
fi

# Clean and recreate logs directory
rm -rf "$LOGS_DIR"
mkdir -p "$LOGS_DIR"

# Test a single package (runs in subshell)
test_package() {
  local dir="$1"
  local name=$(basename "$dir")
  local log="$LOGS_DIR/$name.log"
  local full_path="$ROOT_DIR/$dir"

  [[ -d "$full_path" ]] || { echo "SKIP $name (not found)"; return 0; }

  cd "$full_path"

  # Clear log file
  > "$log"

  echo "🏁 Starting $name"
  echo "=== Testing $name ===" >> "$log"

  # Build first if needed
  if is_type "$dir" "$BUILD_FIRST" && [[ -f "build.sh" ]]; then
    ./build.sh >> "$log" 2>&1 || { echo "⛔️ Failed $name (build)" ; return 1; }
  fi

  # Install npm deps if needed
  [[ -f "package.json" ]] && npm install --silent >> "$log" 2>&1

  local coverage=""

  if is_type "$dir" "$NPM_PACKAGES"; then
    npm test >> "$log" 2>&1 || { echo "⛔️ Failed $name"; return 1; }
  elif is_type "$dir" "$NODE_INTEROP_PACKAGES"; then
    # Node interop packages: use coverage CLI like NODE_PACKAGES
    dart run "$COVERAGE_CLI" >> "$log" 2>&1 || { echo "⛔️ Failed $name"; return 1; }
    coverage=$(calc_coverage "coverage/lcov.info")
  elif is_type "$dir" "$NODE_PACKAGES"; then
    dart run "$COVERAGE_CLI" >> "$log" 2>&1 || { echo "⛔️ Failed $name"; return 1; }
    coverage=$(calc_coverage "coverage/lcov.info")
  elif is_type "$dir" "$BROWSER_PACKAGES"; then
    # Browser packages: run Chrome tests, check coverage if lcov.info exists
    dart test -p chrome --reporter expanded --fail-fast >> "$log" 2>&1 || { echo "⛔️ Failed $name"; return 1; }
    [[ -f "coverage/lcov.info" ]] && coverage=$(calc_coverage "coverage/lcov.info")
  else
    # Standard VM package with coverage
    dart test --coverage=coverage --reporter expanded --fail-fast >> "$log" 2>&1 || { echo "⛔️ Failed $name"; return 1; }
    dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib >> "$log" 2>&1
    coverage=$(calc_coverage "coverage/lcov.info")
  fi

  # Check coverage threshold if applicable
  if [[ -n "$coverage" ]]; then
    if [[ "$coverage" == "0" ]] || (( $(echo "$coverage < $MIN_COVERAGE" | bc -l) )); then
      echo "⛔️ Failed $name (coverage ${coverage}% < ${MIN_COVERAGE}%)"
      return 1
    fi
    echo "✅ Succeeded $name (${coverage}%)"
  else
    echo "✅ Succeeded $name"
  fi
  return 0
}

# Extract failure summary from a log file
extract_failure() {
  local log="$1"
  local name="$2"

  # Look for "Failed to load" or "Failed to run" errors
  if grep -q "Failed to load\|Failed to run\|Some tests failed" "$log"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "FAILURE: $name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Extract failed test file names
    grep "Failed to load\|Failed to run" "$log" | head -5 | while IFS= read -r line; do
      if [[ "$line" =~ Failed\ to\ load\ \"([^\"]+)\" ]]; then
        echo "  Test: ${BASH_REMATCH[1]}"
      fi
    done

    # Extract first error message
    echo ""
    echo "  Error:"
    grep -A 1 "Failed to load\|Failed to run" "$log" | head -3 | sed 's/^/    /'
    echo ""
    echo "  Full log: $log"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
}

# Run a tier of tests in parallel (wait for all, don't kill on failure)
run_tier() {
  local tier_paths=("$@")
  local pids=()
  local failed_packages=()

  # Filter out excluded packages
  local filtered=()
  for path in "${tier_paths[@]}"; do
    if ! is_excluded "$path"; then
      filtered+=("$path")
    fi
  done

  [[ ${#filtered[@]} -eq 0 ]] && return 0

  # Start all tests in parallel
  for dir in "${filtered[@]}"; do
    test_package "$dir" &
    pids+=($!)
  done

  # Wait for ALL jobs to complete, track failures
  for i in "${!pids[@]}"; do
    if ! wait "${pids[$i]}"; then
      failed_packages+=("${filtered[$i]}")
    fi
  done

  # Report failures with details
  if [[ ${#failed_packages[@]} -gt 0 ]]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  ${#failed_packages[@]} PACKAGE(S) FAILED"
    echo "╚════════════════════════════════════════════════════════════════╝"

    for dir in "${failed_packages[@]}"; do
      local name=$(basename "$dir")
      local log="$LOGS_DIR/$name.log"
      extract_failure "$log" "$name"
    done

    return 1
  fi

  return 0
}

# Main
echo "Running ${#TIERS_TO_RUN[@]} tier(s) (MIN_COVERAGE=${MIN_COVERAGE}%)"
echo "Excluded: $EXCLUDED"
echo "Logs: $LOGS_DIR/"
echo ""

# Determine actual tier number for display
if [[ -n "$TIER" ]]; then
  TIER_LABEL="TIER $TIER"
elif [[ ${#PACKAGES[@]} -gt 0 ]]; then
  TIER_LABEL="CUSTOM"
else
  TIER_LABEL="ALL TIERS"
fi

tier_num=1
for tier_spec in "${TIERS_TO_RUN[@]}"; do
  read -ra tier_paths <<< "$tier_spec"

  # Display label
  if [[ "$TIER_LABEL" == "ALL TIERS" ]]; then
    echo "=== TIER $tier_num: ${#tier_paths[@]} packages ==="
  else
    echo "=== $TIER_LABEL: ${#tier_paths[@]} packages ==="
  fi

  if ! run_tier "${tier_paths[@]}"; then
    echo ""
    if [[ "$TIER_LABEL" == "ALL TIERS" ]]; then
      echo "TIER $tier_num FAILED - stopping"
    else
      echo "$TIER_LABEL FAILED"
    fi
    exit 1
  fi

  echo ""
  ((tier_num++))
done

echo "All tests passed"
exit 0
