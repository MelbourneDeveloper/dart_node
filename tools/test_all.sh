#!/bin/bash
# Run tests on all packages and examples with coverage where appropriate
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COVERAGE_CLI="$ROOT_DIR/packages/dart_node_coverage/bin/coverage.dart"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================"
echo "Running all tests with coverage"
echo "============================================"

# Node.js packages - use our coverage analyzer
NODE_PACKAGES=(
  "dart_node_core"
  "dart_node_express"
  "dart_node_ws"
  "dart_node_better_sqlite3"
  "dart_node_mcp"
  "dart_node_react_native"
)

# Browser packages - use standard dart test (no Node.js coverage)
BROWSER_PACKAGES=(
  "dart_node_react"
)

# VM-only packages - use standard dart test with coverage
VM_PACKAGES=(
  "dart_node_coverage"
  "dart_jsx"
  "dart_logging"
  "reflux"
)

# Examples
EXAMPLES=(
  "backend"
)

FAILED=()
PASSED=()

run_node_coverage() {
  local pkg=$1
  local pkg_dir="$ROOT_DIR/packages/$pkg"

  if [ ! -d "$pkg_dir" ]; then
    echo -e "${YELLOW}SKIP${NC} $pkg (not found)"
    return
  fi

  echo ""
  echo -e "${YELLOW}Testing${NC} $pkg (Node.js + coverage)..."

  cd "$pkg_dir"
  dart pub get

  if dart run "$COVERAGE_CLI"; then
    echo -e "${GREEN}PASS${NC} $pkg"
    PASSED+=("$pkg")
  else
    echo -e "${RED}FAIL${NC} $pkg"
    FAILED+=("$pkg")
  fi
}

run_vm_test() {
  local pkg=$1
  local pkg_dir="$ROOT_DIR/packages/$pkg"

  if [ ! -d "$pkg_dir" ]; then
    echo -e "${YELLOW}SKIP${NC} $pkg (not found)"
    return
  fi

  echo ""
  echo -e "${YELLOW}Testing${NC} $pkg (VM)..."

  cd "$pkg_dir"
  dart pub get

  if dart test; then
    echo -e "${GREEN}PASS${NC} $pkg"
    PASSED+=("$pkg")
  else
    echo -e "${RED}FAIL${NC} $pkg"
    FAILED+=("$pkg")
  fi
}

run_browser_test() {
  local pkg=$1
  local pkg_dir="$ROOT_DIR/packages/$pkg"

  if [ ! -d "$pkg_dir" ]; then
    echo -e "${YELLOW}SKIP${NC} $pkg (not found)"
    return
  fi

  echo ""
  echo -e "${YELLOW}Testing${NC} $pkg (Browser)..."

  cd "$pkg_dir"
  dart pub get

  if dart test; then
    echo -e "${GREEN}PASS${NC} $pkg"
    PASSED+=("$pkg")
  else
    echo -e "${RED}FAIL${NC} $pkg"
    FAILED+=("$pkg")
  fi
}

run_example_test() {
  local example=$1
  local example_dir="$ROOT_DIR/examples/$example"

  if [ ! -d "$example_dir" ]; then
    echo -e "${YELLOW}SKIP${NC} examples/$example (not found)"
    return
  fi

  if [ ! -d "$example_dir/test" ]; then
    echo -e "${YELLOW}SKIP${NC} examples/$example (no tests)"
    return
  fi

  echo ""
  echo -e "${YELLOW}Testing${NC} examples/$example..."

  cd "$example_dir"
  dart pub get

  if dart test; then
    echo -e "${GREEN}PASS${NC} examples/$example"
    PASSED+=("examples/$example")
  else
    echo -e "${RED}FAIL${NC} examples/$example"
    FAILED+=("examples/$example")
  fi
}

# Run Node.js packages with coverage
echo ""
echo "--- Node.js Packages (with coverage) ---"
for pkg in "${NODE_PACKAGES[@]}"; do
  run_node_coverage "$pkg"
done

# Run VM packages
echo ""
echo "--- VM Packages ---"
for pkg in "${VM_PACKAGES[@]}"; do
  run_vm_test "$pkg"
done

# Run Browser packages
echo ""
echo "--- Browser Packages ---"
for pkg in "${BROWSER_PACKAGES[@]}"; do
  run_browser_test "$pkg"
done

# Run examples
echo ""
echo "--- Examples ---"
for example in "${EXAMPLES[@]}"; do
  run_example_test "$example"
done

# Summary
echo ""
echo "============================================"
echo "SUMMARY"
echo "============================================"
echo -e "${GREEN}Passed:${NC} ${#PASSED[@]}"
for p in "${PASSED[@]}"; do
  echo "  ✓ $p"
done

if [ ${#FAILED[@]} -gt 0 ]; then
  echo -e "${RED}Failed:${NC} ${#FAILED[@]}"
  for f in "${FAILED[@]}"; do
    echo "  ✗ $f"
  done
  exit 1
else
  echo ""
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
