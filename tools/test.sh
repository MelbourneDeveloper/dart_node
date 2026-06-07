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

# Per-package coverage thresholds live in coverage-thresholds.json
# ([COVERAGE-THRESHOLDS-JSON]). Floors ratchet UP only — see ratchet_thresholds().
THRESHOLDS_FILE="${THRESHOLDS_FILE:-$ROOT_DIR/coverage-thresholds.json}"

# Resolve the coverage threshold for a package: its per-package entry if present,
# else default_threshold from the file, else the MIN_COVERAGE fallback.
pkg_threshold() {
  local name="$1"
  local t=""
  if command -v jq >/dev/null 2>&1 && [[ -f "$THRESHOLDS_FILE" ]]; then
    t=$(jq -r --arg n "$name" \
      '.packages[$n] // .default_threshold // empty' "$THRESHOLDS_FILE")
  fi
  [[ -z "$t" || "$t" == "null" ]] && t="$MIN_COVERAGE"
  echo "$t"
}

# Detect Chromium executable for browser tests (can be overridden by CHROME_EXECUTABLE env var)
if [[ -z "${CHROME_EXECUTABLE:-}" ]]; then
  case "$(uname -s)" in
    Darwin)
      for candidate in \
        "/opt/homebrew/Caskroom/chromium/latest/chrome-mac/Chromium.app/Contents/MacOS/Chromium" \
        "/Applications/Chromium.app/Contents/MacOS/Chromium"; do
        [[ -x "$candidate" ]] && { CHROME_EXECUTABLE="$candidate"; break; }
      done
      ;;
    Linux)
      # Try system chromium first
      for candidate in chromium chromium-browser; do
        if command -v "$candidate" >/dev/null 2>&1; then
          candidate_path="$(command -v "$candidate")"
          # Test if it actually runs (not just a snap wrapper)
          if "$candidate_path" --version >/dev/null 2>&1; then
            CHROME_EXECUTABLE="$candidate_path"
            break
          fi
        fi
      done
      # Fallback to dev container cache if system chromium doesn't work
      if [[ -z "${CHROME_EXECUTABLE:-}" ]]; then
        for dir in /home/vscode/.cache/chromium-*/chrome-linux; do
          [[ -x "$dir/chrome" ]] && { CHROME_EXECUTABLE="$dir/chrome"; break; }
        done
      fi
      ;;
  esac
fi

if [[ -n "${CHROME_EXECUTABLE:-}" ]]; then
  export CHROME_EXECUTABLE
  echo "Chromium: $CHROME_EXECUTABLE"
else
  echo "WARNING: No Chromium found — browser tests will fail"
fi

# Package type definitions
NODE_PACKAGES="dart_node_core dart_node_express dart_node_ws dart_node_better_sqlite3 dart_node_sql_js"
NODE_INTEROP_PACKAGES="dart_node_mcp dart_node_react_native"
BROWSER_PACKAGES="dart_node_react frontend jsx_demo mobile"
NPM_PACKAGES=""
BUILD_FIRST=""

# Tier definitions (space-separated paths). EVERY package that has a test/ dir
# must appear here OR in EXCLUDED_WITH_REASON below — enforced by
# check_all_packages_covered() so a package's coverage check is never silently
# dropped.
TIER1="packages/dart_logging packages/dart_node_core packages/dart_node_coverage"
TIER2="packages/reflux packages/dart_jsx packages/dart_node_express packages/dart_node_ws packages/dart_node_better_sqlite3 packages/dart_node_sql_js packages/dart_node_mcp packages/dart_node_react_native packages/dart_node_react signal_mesh"
TIER3="examples/frontend examples/markdown_editor examples/reflux_demo/web_counter examples/jsx_demo examples/mobile"

# Packages that have tests but are deliberately NOT run here, each with a reason.
# Format "name:reason"; surfaced loudly by check_all_packages_covered().
EXCLUDED_WITH_REASON=(
  "backend:e2e tests require a running Node server (not a unit suite)"
  "flutter_counter:requires the Flutter SDK; CI provisions Dart only"
  "dart_node_vsix:VS Code @vscode/test-electron harness (needs Xvfb + VS Code)"
  "too_many_cooks:removed from the repo"
  "too_many_cooks_vscode_extension:removed from the repo"
)

# Names skipped by run_tier, derived from EXCLUDED_WITH_REASON.
EXCLUDED=""
for _e in "${EXCLUDED_WITH_REASON[@]}"; do EXCLUDED="$EXCLUDED ${_e%%:*}"; done

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

# Fail the run if any package with a test/ dir is neither in a tier nor in
# EXCLUDED_WITH_REASON. This guarantees every testable package is coverage-checked
# (or explicitly, visibly skipped) — no silent gaps.
check_all_packages_covered() {
  local known=" $TIER1 $TIER2 $TIER3 "
  local excluded_names=""
  local e
  for e in "${EXCLUDED_WITH_REASON[@]}"; do excluded_names="$excluded_names ${e%%:*}"; done

  local missing=()
  local pub dir name
  while IFS= read -r pub; do
    dir=$(dirname "$pub")
    dir=${dir#"$ROOT_DIR"/}
    [[ -d "$ROOT_DIR/$dir/test" ]] || continue
    name=$(basename "$dir")
    [[ " $known " == *" $dir "* ]] && continue
    [[ " $excluded_names " == *" $name "* ]] && continue
    missing+=("$dir")
  done < <(find "$ROOT_DIR/packages" "$ROOT_DIR/examples" "$ROOT_DIR/signal_mesh" \
    -name pubspec.yaml -not -path '*/node_modules/*' -not -path '*/.dart_tool/*' \
    -not -path '*/build/*' 2>/dev/null | sort)

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "⛔️ Packages with tests that are NOT coverage-checked and NOT excluded:"
    printf '   - %s\n' "${missing[@]}"
    echo "   Add each to a TIER or to EXCLUDED_WITH_REASON in tools/test.sh."
    return 1
  fi

  echo "Coverage scope OK — every package with tests is tiered or explicitly excluded:"
  for e in "${EXCLUDED_WITH_REASON[@]}"; do
    echo "  • excluded ${e%%:*} — ${e#*:}"
  done
  return 0
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
  # All tiers - run sequentially. Enforce that every testable package is
  # accounted for before running anything.
  check_all_packages_covered || exit 1
  TIERS_TO_RUN+=("$TIER1")
  TIERS_TO_RUN+=("$TIER2")
  TIERS_TO_RUN+=("$TIER3")
fi

# Clean and recreate logs directory
rm -rf "$LOGS_DIR"
mkdir -p "$LOGS_DIR"

# Ensure coverage CLI dependencies are resolved for this environment
# (paths differ between Mac and Linux container)
(cd "$ROOT_DIR/packages/dart_node_coverage" && dart pub get --offline 2>/dev/null || dart pub get) >/dev/null

# Rebuild native npm modules if needed (architecture differs between Mac and Linux)
if [[ -d "$ROOT_DIR/packages/dart_node_better_sqlite3/node_modules/better-sqlite3" ]]; then
  (cd "$ROOT_DIR/packages/dart_node_better_sqlite3" && npm rebuild better-sqlite3 2>/dev/null) >/dev/null
fi

# Format seconds into human-readable time
format_time() {
  local total_secs=$1
  local mins=$((total_secs / 60))
  local secs=$((total_secs % 60))

  if [[ $mins -gt 0 ]]; then
    echo "${mins}m ${secs}s"
  else
    echo "${secs}s"
  fi
}

# Test a single package (runs in subshell)
test_package() {
  local dir="$1"
  local name=$(basename "$dir")
  local log="$LOGS_DIR/$name.log"
  local full_path="$ROOT_DIR/$dir"

  [[ -d "$full_path" ]] || { echo "SKIP $name (not found)"; return 0; }

  cd "$full_path"

  # Start timer
  local start_time=$SECONDS

  # Clear log file
  > "$log"

  echo "🏁 Starting $name"
  echo "=== Testing $name ===" >> "$log"

  # Build first if needed
  if is_type "$dir" "$BUILD_FIRST" && [[ -f "build.sh" ]]; then
    ./build.sh >> "$log" 2>&1 || {
      local elapsed=$((SECONDS - start_time))
      echo "⛔️ Failed $name (build) - $(format_time $elapsed)"
      return 1
    }
  fi

  # Install npm deps if needed
  [[ -f "package.json" ]] && npm install --silent >> "$log" 2>&1

  local coverage=""

  if is_type "$dir" "$NPM_PACKAGES"; then
    npm test >> "$log" 2>&1 || {
      local elapsed=$((SECONDS - start_time))
      echo "⛔️ Failed $name - $(format_time $elapsed)"
      return 1
    }
  elif is_type "$dir" "$NODE_INTEROP_PACKAGES"; then
    # Node interop packages: use coverage CLI like NODE_PACKAGES
    dart run "$COVERAGE_CLI" >> "$log" 2>&1 || {
      local elapsed=$((SECONDS - start_time))
      echo "⛔️ Failed $name - $(format_time $elapsed)"
      return 1
    }
    coverage=$(calc_coverage "coverage/lcov.info")
  elif is_type "$dir" "$NODE_PACKAGES"; then
    dart run "$COVERAGE_CLI" >> "$log" 2>&1 || {
      local elapsed=$((SECONDS - start_time))
      echo "⛔️ Failed $name - $(format_time $elapsed)"
      return 1
    }
    coverage=$(calc_coverage "coverage/lcov.info")
  elif is_type "$dir" "$BROWSER_PACKAGES"; then
    # Browser packages: run Chrome tests, check coverage if lcov.info exists
    dart test -p chrome --reporter expanded --fail-fast >> "$log" 2>&1 || {
      local elapsed=$((SECONDS - start_time))
      echo "⛔️ Failed $name - $(format_time $elapsed)"
      return 1
    }
    [[ -f "coverage/lcov.info" ]] && coverage=$(calc_coverage "coverage/lcov.info")
  else
    # Standard VM package with coverage
    dart test --coverage=coverage --reporter expanded --fail-fast >> "$log" 2>&1 || {
      local elapsed=$((SECONDS - start_time))
      echo "⛔️ Failed $name - $(format_time $elapsed)"
      return 1
    }
    dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib >> "$log" 2>&1
    coverage=$(calc_coverage "coverage/lcov.info")
  fi

  # Calculate elapsed time
  local elapsed=$((SECONDS - start_time))
  local time_str=$(format_time $elapsed)

  # Check coverage threshold if applicable
  if [[ -n "$coverage" ]]; then
    local threshold
    threshold=$(pkg_threshold "$name")
    if [[ "$coverage" == "0" ]] || (( $(echo "$coverage < $threshold" | bc -l) )); then
      echo "⛔️ Failed $name (coverage ${coverage}% < ${threshold}%) - $time_str"
      return 1
    fi
    # Record measured coverage so the post-run ratchet can raise the floor
    echo "$coverage" > "$LOGS_DIR/$name.coverage"
    echo "✅ Succeeded $name (${coverage}%) - $time_str"
  else
    echo "✅ Succeeded $name - $time_str"
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

# Ratchet coverage thresholds UP after a fully-green run. Each package's stored
# threshold is raised to its measured coverage (never lowered), implementing the
# monotonically-increasing floor in [COVERAGE-THRESHOLDS-JSON]. test_package runs
# in parallel, so measured values are collected from logs/*.coverage and written
# here in a single sequential pass — no concurrent writes to the JSON.
ratchet_thresholds() {
  command -v jq >/dev/null 2>&1 || return 0
  [[ -f "$THRESHOLDS_FILE" ]] || return 0
  local updated=0
  for cov_file in "$LOGS_DIR"/*.coverage; do
    [[ -f "$cov_file" ]] || continue
    local name measured stored
    name=$(basename "$cov_file" .coverage)
    measured=$(cat "$cov_file")
    stored=$(jq -r --arg n "$name" '.packages[$n] // 0' "$THRESHOLDS_FILE")
    if (( $(echo "$measured > $stored" | bc -l) )); then
      local tmp="$THRESHOLDS_FILE.tmp"
      if jq --arg n "$name" --argjson v "$measured" \
          '.packages[$n] = $v' "$THRESHOLDS_FILE" > "$tmp"; then
        mv "$tmp" "$THRESHOLDS_FILE"
        echo "⬆️  Ratcheted $name → ${measured}% (was ${stored}%)"
        updated=1
      else
        rm -f "$tmp"
      fi
    fi
  done
  [[ $updated -eq 1 ]] && \
    echo "Coverage thresholds raised in $(basename "$THRESHOLDS_FILE")"
  return 0
}

# Main
TOTAL_START=$SECONDS

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

  tier_start=$SECONDS
  if ! run_tier "${tier_paths[@]}"; then
    echo ""
    tier_elapsed=$((SECONDS - tier_start))
    if [[ "$TIER_LABEL" == "ALL TIERS" ]]; then
      echo "TIER $tier_num FAILED - $(format_time $tier_elapsed)"
    else
      echo "$TIER_LABEL FAILED - $(format_time $tier_elapsed)"
    fi
    exit 1
  fi
  tier_elapsed=$((SECONDS - tier_start))

  if [[ "$TIER_LABEL" == "ALL TIERS" ]]; then
    echo "TIER $tier_num completed - $(format_time $tier_elapsed)"
  fi

  echo ""
  ((tier_num++))
done

ratchet_thresholds

total_elapsed=$((SECONDS - TOTAL_START))
echo "All tests passed - $(format_time $total_elapsed)"
exit 0
