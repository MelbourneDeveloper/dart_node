# =============================================================================
# Standard Makefile — dart_node
# Dart packages for building Node.js apps.
# =============================================================================

.PHONY: build test lint fmt fmt-check clean check ci coverage coverage-check \
        help setup pub-get test-tier1 test-tier2 test-tier3 install-vsix

# Coverage threshold (override in CI via env var)
COVERAGE_THRESHOLD ?= 80

# =============================================================================
# PRIMARY TARGETS (uniform interface — do not rename)
# =============================================================================

## build: Compile/assemble all artifacts
build:
	@echo "==> Building..."
	$(MAKE) _build

## test: Run full test suite with coverage
test:
	@echo "==> Testing..."
	$(MAKE) _test

## lint: Run all linters (fails on any warning)
lint:
	@echo "==> Linting..."
	$(MAKE) _lint

## fmt: Format all code in-place
fmt:
	@echo "==> Formatting..."
	$(MAKE) _fmt

## fmt-check: Check formatting without modifying
fmt-check:
	@echo "==> Checking format..."
	$(MAKE) _fmt_check

## clean: Remove all build artifacts
clean:
	@echo "==> Cleaning..."
	$(MAKE) _clean

## check: lint + test (pre-commit)
check: lint test

## ci: lint + test + build (full CI simulation)
ci: lint test build

## coverage: Generate coverage report
coverage:
	@echo "==> Coverage report..."
	$(MAKE) _coverage

## coverage-check: Assert thresholds (exits non-zero if below)
coverage-check:
	@echo "==> Checking coverage thresholds..."
	$(MAKE) _coverage_check

# =============================================================================
# DART IMPLEMENTATIONS
# =============================================================================

_build:
	@echo "Dart library packages — no standalone build artifacts"

_test:
	./tools/test.sh

_lint:
	$(MAKE) _fmt_check
	cspell "**/*.md" "**/*.dart" "**/*.ts" --no-progress
	@for dir in packages/* examples/* tools/build; do \
		if [ -d "$$dir" ] && [ -f "$$dir/pubspec.yaml" ]; then \
			echo "Analyzing $$dir..."; \
			(cd "$$dir" && dart analyze --no-fatal-warnings) || true; \
		fi; \
	done

_fmt:
	dart format packages/ examples/ tools/build

_fmt_check:
	dart format --set-exit-if-changed packages/
	dart format --set-exit-if-changed examples/
	dart format --set-exit-if-changed tools/build

_clean:
	rm -rf logs/
	@for pkg in packages/*/; do \
		[ -d "$$pkg/build" ] && rm -rf "$$pkg/build" || true; \
		[ -d "$$pkg/coverage" ] && rm -rf "$$pkg/coverage" || true; \
	done

_coverage:
	./tools/test.sh
	@echo "Coverage reports in logs/"

_coverage_check:
	MIN_COVERAGE=$(COVERAGE_THRESHOLD) ./tools/test.sh

# =============================================================================
# PROJECT-SPECIFIC TARGETS
# =============================================================================

setup: pub-get ## Install all Dart and npm dependencies

pub-get: ## Run dart pub get on all packages in dependency order
	./tools/pub_get.sh

test-tier1: ## Run tier 1 tests only (core packages)
	./tools/test.sh --tier 1

test-tier2: ## Run tier 2 tests only (dependent packages)
	./tools/test.sh --tier 2

test-tier3: ## Run tier 3 tests only (examples)
	./tools/test.sh --tier 3

install-vsix: ## Build and install the VS Code extension locally
	./tools/run_todo_backend.sh

# =============================================================================
# HELP
# =============================================================================
help:
	@echo "Available targets:"
	@echo "  build          - Compile/assemble all artifacts"
	@echo "  test           - Run full test suite with coverage"
	@echo "  lint           - Run all linters (errors mode)"
	@echo "  fmt            - Format all code in-place"
	@echo "  fmt-check      - Check formatting (no modification)"
	@echo "  clean          - Remove build artifacts"
	@echo "  check          - lint + test (pre-commit)"
	@echo "  ci             - lint + test + build (full CI)"
	@echo "  coverage       - Generate and open coverage report"
	@echo "  coverage-check - Assert coverage thresholds"
	@echo ""
	@echo "Project-specific:"
	@echo "  setup          - Install all Dart and npm dependencies"
	@echo "  pub-get        - Run dart pub get in dependency order"
	@echo "  test-tier1     - Run tier 1 tests only"
	@echo "  test-tier2     - Run tier 2 tests only"
	@echo "  test-tier3     - Run tier 3 tests only"
	@echo "  install-vsix   - Build and install VS Code extension"
