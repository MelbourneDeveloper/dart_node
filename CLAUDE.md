# CLAUDE.md

Dart packages for building Node.js apps. Typed Dart layer over JS interop.

## Multi-Agent Coordination (Too Many Cooks)
- Keep your key! It's critical. Do not lose it!
- Check messages regularly, lock files before editing, unlock after
- Don't edit locked files; signal intent via plans and messages
- Coordinator: keep delegating via messages. Worker: keep asking for tasks via messages
- Clean up expired locks routinely
- Do not use Git unless asked by user

## Code Rules

**Language & Types**
- All Dart, minimal JS. Use `dart:js_interop` (not deprecated `dart:js_util`/`package:js`)
- Never expose `JSObject`/`JSAny`/`dynamic` in public APIs—always typed
- Prefer typedef records over classes for data (structural typing)
- ILLEGAL: `as`, `late`, `!`, `.then()`, global state

**Architecture**
- NO DUPLICATION—search before adding, move don't copy
- Return `Result<T,E>` (nadz) instead of throwing exceptions
- Functions < 20 lines, files < 500 LOC
- Switch expressions/ternaries over if/else (except in declarative contexts)

**Testing**
- 100% coverage with high-level integration tests, not unit tests/mocks
- Tests in separate files, not groups. Dart only (JS only for interop testing)
- Never skip tests. Never remove assertions. Failing tests OK, silent failures ILLEGAL
- NO PLACEHOLDERS—throw if incomplete

**Dependencies**
- All packages require: `austerity` (linting), `nadz` (Result types)
- `node_preamble` for dart2js Node.js compatibility

## Codebase Structure

```
packages/
  dart_node_core/       # Core Node.js interop
  dart_node_express/    # Express.js bindings
  dart_node_react/      # React bindings
  dart_node_react_native/ # React Native bindings
  dart_node_ws/         # WebSocket bindings
  dart_node_better_sqlite3/ # SQLite bindings
  dart_node_mcp/        # MCP protocol
  dart_jsx/             # JSX transpiler for Dart
  dart_logging/         # Logging utilities
  reflux/               # State management

examples/
  backend/              # Express server example
  frontend/             # React web example
  mobile/               # React Native example
  too_many_cooks/       # Multi-agent coordination server
  jsx_demo/             # JSX syntax demo
```

## Build & Test
```bash
dart run tools/build/build.dart    # Build all
dart test                          # Run tests
dart analyze                       # Lint check
```
