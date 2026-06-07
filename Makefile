# agent-pmo:76596cb
# =============================================================================
# Standard Makefile — dart_node
# Dart packages for building Node.js apps. Cross-platform (Linux, macOS, Windows).
# =============================================================================

.PHONY: build test lint fmt clean ci setup \
        pub-get test-tier1 test-tier2 test-tier3 install-vsix help

# ---------------------------------------------------------------------------
# OS Detection ([MAKE-CROSS-PLATFORM])
# ---------------------------------------------------------------------------
ifeq ($(OS),Windows_NT)
  SHELL := powershell.exe
  .SHELLFLAGS := -NoProfile -Command
  RM = Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  MKDIR = New-Item -ItemType Directory -Force
  HOME ?= $(USERPROFILE)
else
  RM = rm -rf
  MKDIR = mkdir -p
endif

# Coverage — single source of truth is coverage-thresholds.json
# ([COVERAGE-THRESHOLDS-JSON]). No env vars, no GitHub repo variables.
COVERAGE_THRESHOLDS_FILE := coverage-thresholds.json

# =============================================================================
# Standard Targets (canonical names — do not rename or add synonyms)
# =============================================================================

## build: Compile/assemble all artifacts
build:
	@echo "==> Building..."
	@echo "Dart library packages — no standalone build artifacts"

## test: Fail-fast tests + coverage + threshold enforcement ([TEST-RULES]).
##       Threshold is read from coverage-thresholds.json.
test:
	@echo "==> Testing (fail-fast + coverage + threshold)..."
	MIN_COVERAGE=$$(jq -r '.default_threshold' $(COVERAGE_THRESHOLDS_FILE)) ./tools/test.sh

## lint: Run all linters/analyzers (read-only). Does NOT format.
lint:
	@echo "==> Linting..."
	cspell "**/*.md" "**/*.dart" "**/*.ts" --no-progress
	@for dir in packages/* examples/* tools/build; do \
		if [ -d "$$dir" ] && [ -f "$$dir/pubspec.yaml" ]; then \
			echo "Analyzing $$dir..."; \
			(cd "$$dir" && dart analyze --no-fatal-warnings) || exit 1; \
		fi; \
	done

## fmt: Format all code in-place. Pass CHECK=1 for read-only check (CI use).
fmt:
	@echo "==> Formatting$(if $(CHECK), (check mode),)..."
	dart format$(if $(CHECK), --set-exit-if-changed,) packages/ examples/

## clean: Remove all build artifacts
clean:
	@echo "==> Cleaning..."
	$(RM) logs
	@for pkg in packages/*/; do \
		[ -d "$$pkg/build" ] && $(RM) "$$pkg/build" || true; \
		[ -d "$$pkg/coverage" ] && $(RM) "$$pkg/coverage" || true; \
	done

## ci: lint + test + build (full CI simulation)
ci: lint test build

## setup: Install all Dart and npm dependencies (devcontainer hook)
setup: pub-get

# =============================================================================
# Repo-Specific Targets
# Owned by the repo. Preserved verbatim per [MAKE-REPO-SPECIFIC].
# =============================================================================

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
	@echo "Standard targets:"
	@echo "  build        - Compile/assemble all artifacts"
	@echo "  test         - Fail-fast tests + coverage + threshold enforcement"
	@echo "  lint         - All linters/analyzers (read-only, no formatting)"
	@echo "  fmt          - Format all code in-place (CHECK=1 for read-only CI check)"
	@echo "  clean        - Remove build artifacts"
	@echo "  ci           - lint + test + build (full CI simulation)"
	@echo "  setup        - Install all Dart and npm dependencies"
	@echo ""
	@echo "Repo-specific:"
	@echo "  pub-get      - Run dart pub get in dependency order"
	@echo "  test-tier1   - Run tier 1 tests only"
	@echo "  test-tier2   - Run tier 2 tests only"
	@echo "  test-tier3   - Run tier 3 tests only"
	@echo "  install-vsix - Build and install VS Code extension"
