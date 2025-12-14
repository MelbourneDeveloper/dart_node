#!/bin/bash
# Unified test runner - parallel execution with fail-fast and coverage
# Usage: ./tools/test.sh [--tier N] [--ci] [package...]
#
# Options:
#   --tier N    Only run tier N (1, 2, or 3)
#   --ci        CI mode: fail-fast, minimal output
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

# Parse arguments
CI_MODE=false
TIER=""
PACKAGES=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --ci) CI_MODE=true; shift ;;
    --tier) TIER="$2"; shift 2 ;;
    *) PACKAGES+=("$1"); shift ;;
  esac
done

# Determine what to test
if [[ ${#PACKAGES[@]} -gt 0 ]]; then
  TEST_PATHS=("${PACKAGES[@]}")
elif [[ -n "$TIER" ]]; then
  case $TIER in
    1) read -ra TEST_PATHS <<< "$TIER1" ;;
    2) read -ra TEST_PATHS <<< "$TIER2" ;;
    3) read -ra TEST_PATHS <<< "$TIER3" ;;
    *) echo "Invalid tier: $TIER"; exit 1 ;;
  esac
else
  # All tiers
  read -ra T1 <<< "$TIER1"
  read -ra T2 <<< "$TIER2"
  read -ra T3 <<< "$TIER3"
  TEST_PATHS=("${T1[@]}" "${T2[@]}" "${T3[@]}")
fi

mkdir -p "$LOGS_DIR"

# Helper functions
is_type() {
  local name=$(basename "$1")
  local list="$2"
  [[ " $list " =~ " $name " ]]
}

calc_coverage() {
  local lcov="$1"
  [[ -f "$lcov" ]] || { echo "0"; return; }
  awk -F: '/^LF:/ { total += $2 } /^LH:/ { covered += $2 } END { if (total > 0) printf "%.1f", (covered / total) * 100; else print "0" }' "$lcov"
}

# Test a single package (runs in subshell)
test_package() {
  local dir="$1"
  local name=$(basename "$dir")
  local log="$LOGS_DIR/$name.log"
  local full_path="$ROOT_DIR/$dir"

  [[ -d "$full_path" ]] || { echo "SKIP $name (not found)"; return 0; }

  cd "$full_path"

  # Build first if needed
  if is_type "$dir" "$BUILD_FIRST" && [[ -f "build.sh" ]]; then
    ./build.sh >> "$log" 2>&1 || { echo "FAIL $name (build)"; return 1; }
  fi

  # Install npm deps if needed
  [[ -f "package.json" ]] && npm install >> "$log" 2>&1

  local coverage=""

  if is_type "$dir" "$NPM_PACKAGES"; then
    npm test >> "$log" 2>&1 || { echo "FAIL $name"; return 1; }
  elif is_type "$dir" "$NODE_INTEROP_PACKAGES"; then
    # Node interop packages: use coverage CLI like NODE_PACKAGES
    dart run "$COVERAGE_CLI" >> "$log" 2>&1 || { echo "FAIL $name"; return 1; }
    coverage=$(calc_coverage "coverage/lcov.info")
  elif is_type "$dir" "$NODE_PACKAGES"; then
    dart run "$COVERAGE_CLI" >> "$log" 2>&1 || { echo "FAIL $name"; return 1; }
    coverage=$(calc_coverage "coverage/lcov.info")
  elif is_type "$dir" "$BROWSER_PACKAGES"; then
    # Browser packages: run Chrome tests, check coverage if lcov.info exists
    dart test -p chrome >> "$log" 2>&1 || { echo "FAIL $name"; return 1; }
    [[ -f "coverage/lcov.info" ]] && coverage=$(calc_coverage "coverage/lcov.info")
  else
    # Standard VM package with coverage
    dart test --coverage=coverage >> "$log" 2>&1 || { echo "FAIL $name"; return 1; }
    dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib >> "$log" 2>&1
    coverage=$(calc_coverage "coverage/lcov.info")
  fi

  # Check coverage threshold if applicable
  if [[ -n "$coverage" ]]; then
    if [[ "$coverage" == "0" ]] || (( $(echo "$coverage < $MIN_COVERAGE" | bc -l) )); then
      echo "FAIL $name (coverage ${coverage}% < ${MIN_COVERAGE}%)"
      return 1
    fi
    echo "PASS $name (${coverage}%)"
  else
    echo "PASS $name"
  fi
  return 0
}

# Run tests in parallel, fail-fast on first failure
run_parallel() {
  local pids=()
  local results_dir=$(mktemp -d)

  for dir in "${TEST_PATHS[@]}"; do
    local name=$(basename "$dir")
    (
      if test_package "$dir"; then
        touch "$results_dir/$name.pass"
      else
        touch "$results_dir/$name.fail"
      fi
    ) &
    pids+=($!)
  done

  # Wait and check for failures
  local failed=0
  for i in "${!pids[@]}"; do
    local pid=${pids[$i]}
    local dir=${TEST_PATHS[$i]}
    local name=$(basename "$dir")

    if ! wait "$pid"; then
      failed=1
      if $CI_MODE; then
        # Kill remaining processes on first failure
        for p in "${pids[@]}"; do
          kill "$p" 2>/dev/null || true
        done
        # Show error log
        echo ""
        echo "=== Error log for $name ==="
        cat "$LOGS_DIR/$name.log" 2>/dev/null || true
        break
      fi
    fi
  done

  rm -rf "$results_dir"
  return $failed
}

# Main
echo "Testing ${#TEST_PATHS[@]} packages (MIN_COVERAGE=${MIN_COVERAGE}%)"
echo "Logs: $LOGS_DIR/"
echo ""

if run_parallel; then
  echo ""
  echo "All tests passed"
  exit 0
else
  echo ""
  echo "Tests failed"
  exit 1
fi
