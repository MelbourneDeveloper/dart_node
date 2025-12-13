#!/bin/bash
# Run tests with coverage for Node.js packages using dart_node_coverage
# Usage: ./tools/test_node_coverage.sh <min_coverage> <package1> <package2> ...
#
# Example:
#   ./tools/test_node_coverage.sh 80 packages/dart_node_core packages/dart_node_express

set -e

MIN_COVERAGE=$1
shift

if [ -z "$MIN_COVERAGE" ]; then
  echo "Usage: $0 <min_coverage> <package1> <package2> ..."
  echo "Example: $0 80 packages/dart_node_core packages/dart_node_express"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
COVERAGE_CLI="$ROOT_DIR/packages/dart_node_coverage/bin/coverage.dart"

# Ensure coverage tool dependencies are available
echo "Ensuring dart_node_coverage dependencies..."
cd "$ROOT_DIR/packages/dart_node_coverage" && dart pub get > /dev/null 2>&1
cd "$ROOT_DIR"

failed=0
for dir in "$@"; do
  name=$(basename "$dir")
  echo ""
  echo "=========================================="
  echo "Testing $name with coverage"
  echo "=========================================="

  cd "$ROOT_DIR/$dir"

  # Run coverage CLI
  if dart run "$COVERAGE_CLI"; then
    # Calculate coverage
    if [ -f "coverage/lcov.info" ]; then
      COVERAGE=$(awk -F: '/^LF:/ { total += $2 } /^LH:/ { covered += $2 } END { if (total > 0) printf "%.1f", (covered / total) * 100; else print "0" }' coverage/lcov.info)
      echo "$name coverage: ${COVERAGE}%"

      if [ -z "$COVERAGE" ] || [ "$COVERAGE" = "0" ]; then
        echo "ERROR: No coverage data collected for $name"
        failed=1
      elif [ "$(echo "$COVERAGE < $MIN_COVERAGE" | bc -l)" -eq 1 ]; then
        echo "ERROR: Coverage ${COVERAGE}% is below ${MIN_COVERAGE}% threshold"
        failed=1
      else
        echo "OK: $name meets coverage threshold"
      fi
    else
      echo "ERROR: No lcov.info file generated for $name"
      failed=1
    fi
  else
    echo "ERROR: Tests failed for $name"
    failed=1
  fi

  cd "$ROOT_DIR"
done

echo ""
echo "=========================================="
if [ $failed -eq 0 ]; then
  echo "All packages passed coverage threshold!"
else
  echo "Some packages failed coverage check"
fi
echo "=========================================="

exit $failed
