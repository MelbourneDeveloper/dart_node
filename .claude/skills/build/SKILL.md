---
name: build
description: Builds all artifacts for this repo. Use when the user asks to build, compile, or produce artifacts, or when verifying that the project compiles cleanly.
---

# Build

Build all artifacts for this repo.

## Steps

1. Run `make clean` to remove stale artifacts
2. Run `make build`
3. Report what was built and where the artifacts are

## Notes

This is a Dart library monorepo — `make build` verifies that all packages compile cleanly. There are no standalone build artifacts (libraries are consumed via pub.dev).

To build specific components:
- Backend example: `dart run tools/build/build.dart backend`
- VS Code extension: see `/build-extension` skill

## Success criteria

- Exit code 0 from `make build`
- No warnings printed to stderr
