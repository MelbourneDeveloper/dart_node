---
name: ci-prep
description: Prepares the current branch for CI by running the exact same checks locally, fixing issues at each step. Use before pushing a branch or when the user wants to verify the branch will pass CI.
---

# CI Prep

Prepare the current state for CI. Ensures the branch will pass CI before pushing.

## Steps

### Step 1 — Analyze the CI workflow

1. Read `.github/workflows/ci.yml`
2. The CI runs these jobs in order:
   - **lint**: format check, spell check, dart analyze
   - **test**: tier 1, tier 2, tier 3 tests with coverage
   - **build**: `make build`
   - **website**: website build + Playwright tests (independent)

### Step 2 — Run each CI step locally, in order

1. **Format check**: `make fmt-check`
   - If fails: run `make fmt` to fix, then re-check
2. **Spell check**: `cspell "**/*.md" "**/*.dart" "**/*.ts" --no-progress`
   - If fails: add words to cspell dictionary or fix typos
3. **Analyze**: `dart analyze --no-fatal-warnings` on all packages
   - If fails: fix lint errors in the reported files
4. **Test Tier 1**: `./tools/test.sh --tier 1`
5. **Test Tier 2**: `./tools/test.sh --tier 2`
6. **Test Tier 3**: `./tools/test.sh --tier 3`
7. **Build**: `make build`

### Step 3 — Report

- List every step that was run and its result (pass/fail/fixed)
- If any step could not be fixed, report what failed and why
- Confirm whether the branch is ready to push

## Rules

- Do not push if any step fails
- Fix issues found in each step before moving to the next
- Never skip steps or suppress errors
