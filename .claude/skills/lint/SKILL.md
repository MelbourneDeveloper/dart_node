---
name: lint
description: Runs all linters and format checks, then fixes any issues found. Use when the user asks to lint, check code quality, or fix linting errors.
---

# Lint

Run all linters and report issues.

## Steps

1. Run `make lint` (runs format check + cspell + dart analyze on all packages)
2. Report all issues found (file, line, rule, message)
3. If issues found, fix them and re-run to confirm clean

## What `make lint` does

1. `dart format --set-exit-if-changed` on packages/, examples/, tools/build
2. `cspell` spell check on all .md, .dart, .ts files
3. `dart analyze --no-fatal-warnings` on every package and example

## Rules

- Never suppress a lint warning with an ignore comment
- Fix the code to satisfy the linter
- Each package uses the `austerity` lint package — do not bypass its rules
- If a rule seems wrong for a specific case, document why in code comments

## Success criteria

- `make lint` exits with code 0
- Zero warnings or errors output
