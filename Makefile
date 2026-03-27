.PHONY: help setup test test-tier1 test-tier2 test-tier3 pub-get install-vsix clean

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

setup: pub-get ## Install all Dart and npm dependencies

pub-get: ## Run dart pub get on all packages in dependency order
	./tools/pub_get.sh

test: ## Run all tests with coverage (all tiers)
	./tools/test.sh

test-tier1: ## Run tier 1 tests only (core packages)
	./tools/test.sh --tier 1

test-tier2: ## Run tier 2 tests only (dependent packages)
	./tools/test.sh --tier 2

test-tier3: ## Run tier 3 tests only (examples)
	./tools/test.sh --tier 3

install-vsix: ## Build and install the VS Code extension locally
	./tools/run_todo_backend.sh

lint: ## Analyze all Dart packages
	@for pkg in packages/dart_logging packages/dart_node_core packages/dart_node_express \
	            packages/dart_node_ws packages/dart_node_mcp packages/dart_node_react \
	            packages/dart_node_react_native packages/dart_node_better_sqlite3 \
	            packages/reflux packages/dart_jsx packages/dart_node_coverage; do \
	  [ -d "$$pkg" ] && echo "Analyzing $$pkg..." && (cd "$$pkg" && dart analyze) || true; \
	done

fmt: ## Format all Dart packages
	@for pkg in packages/dart_logging packages/dart_node_core packages/dart_node_express \
	            packages/dart_node_ws packages/dart_node_mcp packages/dart_node_react \
	            packages/dart_node_react_native packages/dart_node_better_sqlite3 \
	            packages/reflux packages/dart_jsx packages/dart_node_coverage; do \
	  [ -d "$$pkg" ] && (cd "$$pkg" && dart format .) || true; \
	done

clean: ## Remove build artifacts and logs
	rm -rf logs/
	@for pkg in packages/*/; do \
	  [ -d "$$pkg/build" ] && rm -rf "$$pkg/build" || true; \
	  [ -d "$$pkg/coverage" ] && rm -rf "$$pkg/coverage" || true; \
	done

ci: setup test ## Full CI pipeline (setup + all tests)
