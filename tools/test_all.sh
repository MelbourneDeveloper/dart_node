name: CI

on:
  pull_request:
    branches: [main]

env:
  MIN_COVERAGE: ${{ vars.MIN_COVERAGE }}
  TIER1: >-
    packages/dart_logging
    packages/dart_node_core
  TIER2: >-
    packages/reflux
    packages/dart_node_express
    packages/dart_node_ws
    packages/dart_node_better_sqlite3
    packages/dart_node_mcp
    packages/dart_node_react_native
    packages/dart_node_react
  TIER3: >-
    examples/backend
    examples/frontend
    examples/markdown_editor
    examples/mobile
    examples/too_many_cooks

jobs:
  ci:
    name: Lint, Test & Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup

      - name: Install tools
        run: |
          npm install -g cspell
          dart pub global activate coverage

      - name: Get all dependencies
        run: |
          for dir in packages/* examples/* tools/build; do
            if [ -d "$dir" ] && [ -f "$dir/pubspec.yaml" ]; then
              echo "::group::$dir"
              cd $dir && dart pub get && cd - > /dev/null
              echo "::endgroup::"
            fi
          done

      - name: Spell check
        run: cspell "**/*.md" "**/*.dart" "**/*.ts" --no-progress

      - name: Check formatting
        run: |
          dart format --set-exit-if-changed packages/
          dart format --set-exit-if-changed examples/
          dart format --set-exit-if-changed tools/build

      - name: Analyze
        run: |
          for dir in packages/* examples/* tools/build; do
            if [ -d "$dir" ] && [ -f "$dir/pubspec.yaml" ]; then
              echo "::group::Analyzing $dir"
              cd $dir && dart analyze --no-fatal-warnings && cd - > /dev/null
              echo "::endgroup::"
            fi
          done

      - name: Test Tier 1
        run: ./tools/test_tier.sh $MIN_COVERAGE $TIER1

      - name: Test Tier 2
        run: ./tools/test_tier.sh $MIN_COVERAGE $TIER2

      - name: Test Tier 3
        run: ./tools/test_tier.sh $MIN_COVERAGE $TIER3
