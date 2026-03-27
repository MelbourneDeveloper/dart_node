---
name: code-dedup
description: Searches for duplicate code, duplicate tests, and dead code, then safely merges or removes them. Use when the user says "deduplicate", "find duplicates", "remove dead code", "DRY up", or "code dedup". Requires test coverage — refuses to touch untested code.
---

# Code Dedup

Carefully search for duplicate code, duplicate tests, and dead code across the repo. Merge duplicates and delete dead code — but only when test coverage proves the change is safe.

## Prerequisites — hard gate

Before touching ANY code, verify these conditions. If any fail, stop and report why.

1. Run `make test` — all tests must pass. If tests fail, stop.
2. Run `make coverage-check` — coverage must meet the repo threshold (80%). If not, stop.
3. This is a Dart repo with static typing via `austerity` — proceed.

## Steps

### Step 1 — Inventory test coverage

1. Run `make test` and note coverage per package from the output
2. Only packages WITH coverage are candidates for dedup

### Step 2 — Scan for dead code

1. Look for unused exports, functions, classes, variables across all packages
2. Use `dart analyze` output for unused element warnings
3. Grep the entire codebase for references before marking as dead
4. List all dead code found. Do NOT delete yet.

### Step 3 — Scan for duplicate code

1. Look for functions with identical or near-identical logic across packages
2. Check across package boundaries
3. List all duplicates found. Do NOT merge yet.

### Step 4 — Scan for duplicate tests

1. Look for tests that verify the same behavior
2. Look for test helpers duplicated across test files
3. List all duplicate tests found. Do NOT delete yet.

### Step 5 — Apply changes (one at a time)

For each change: **change -> test -> verify coverage -> continue or revert**.

- After each change: run `./tools/test.sh`
- If tests fail or coverage drops: **revert immediately**

### Step 6 — Final verification

1. Run `make test` — all tests must still pass
2. Run `make lint` and `make fmt-check` — code must be clean
3. Report: what was removed, what was merged, final coverage vs baseline

## Rules

- **No test coverage = do not touch.**
- **Coverage must not drop.**
- **One change at a time.**
- **When in doubt, leave it.** False dedup is worse than duplication.
- **Three similar lines is fine.** Only dedup substantial (>10 lines) or 3+ copies.
