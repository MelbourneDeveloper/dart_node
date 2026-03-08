---
name: build-extension
description: Build, test, and package VSCode extensions in the dart_node repo
argument-hint: "[too-many-cooks|dart-node-vsix] [build|test|package|install]"
disable-model-invocation: true
allowed-tools: Bash
---

# Build VSCode Extensions

This repo has one VSCode extension component:

| Component | Location | What it is |
|-----------|----------|------------|
| **dart_node_vsix** | `packages/dart_node_vsix/` | The SDK package — Dart bindings for the VSCode extension API (commands, tree views, webviews, status bar, etc.) |

## dart_node_vsix SDK package

**Test the SDK** (Dart tests compiled to JS, run in VSCode):
```bash
cd packages/dart_node_vsix && npm install && npm run compile && npm test
```

**What it provides** — Dart bindings for:
- `commands`, `window`, `workspace`, `statusBar`
- `TreeView`, `Webview`, `OutputChannel`
- `ExtensionContext`, `Disposable`
- `Mocha` test API bindings
- JS interop helpers (`Promise`, `EventEmitter`)

## Architecture

Both use the same pattern: Dart → `dart compile js` → wrapper script → VSCode-compatible JS module.

The wrapper scripts (`scripts/wrap-extension.js`, `scripts/wrap-tests.js`) bridge dart2js output to VSCode's CommonJS `require`/`module.exports` system and inject polyfills (navigator, self) needed by dart2js async scheduling.
