#!/bin/bash
# Run tests with coverage in parallel for multiple packages
# Usage: ./tools/test_parallel.sh <min_coverage> <package1> <package2> ...

MIN_COVERAGE=$1
shift

pids=""
for dir in "$@"; do
  name=$(basename "$dir")
  (
    cd "$dir"
    dart test --coverage=coverage
    dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
    COVERAGE=$(awk -F: '/^LF:/ { total += $2 } /^LH:/ { covered += $2 } END { if (total > 0) printf "%.1f", (covered / total) * 100; else print "0" }' coverage/lcov.info)
    echo "$name coverage: ${COVERAGE}%"
    if [ -z "$COVERAGE" ] || [ "$COVERAGE" = "0" ] || [ "$(echo "$COVERAGE < $MIN_COVERAGE" | bc -l)" -eq 1 ]; then
      echo "Coverage ${COVERAGE}% is below ${MIN_COVERAGE}% threshold"
      exit 1
    fi
  ) &
  pids="$pids $!"
done

failed=0
for pid in $pids; do
  wait $pid || failed=1
done
exit $failed
