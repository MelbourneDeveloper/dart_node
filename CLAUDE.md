# CLAUDE.md

Dart packages for building Node.js apps. Strongly Typed Dart layer over JS interop.

## Rules

⛔️ NEVER KILL (pkill) THE VSCODE PROCESS!!!
- Do not use Git unless asked by user

## Multi-Agent Coordination (Too Many Cooks)
- Keep your key! It's critical. Do not lose it!
- Check messages regularly, lock files before editing, unlock after
- Don't edit locked files; signal intent via plans and messages

**Language & Types**
- All Dart, minimal JS. Use `dart:js_interop` (not deprecated `dart:js_util`/`package:js`)
- AVOID `JSObject`/`JSAny`/`dynamic`!
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

# Web & Translation

- Optimize for AI Search and SEO
https://developers.google.com/search/blog/2025/05/succeeding-in-ai-search
https://developers.google.com/search/docs/fundamentals/seo-starter-guide

- Always translate the English version to the target language directly. 
- Be careful of cultural differences. 
- Avoid literal translations that may offend the reader. 
- Keep the code examples the same as the original but translate the comments to the target language
- Minimize CSS. 
- Don't name CSS after sections. Name them after the HTML element

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