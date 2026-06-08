# CLAUDE.md

<!-- agent-pmo:76596cb -->

Dart packages for building Node.js apps. Strongly Typed Dart layer over JS interop.

## Rules

⛔️ NEVER KILL (pkill) THE VSCODE PROCESS!!!
- Do not use Git unless asked by user

**Language & Types**
- All Dart, minimal JS. Use `dart:js_interop` (not deprecated `dart:js_util`/`package:js`)
- AVOID `JSObject`/`JSAny`/`dynamic`!
- Prefer typedef records over classes for data (structural typing)
- Literals are illegal. Move all literals to named constants
- ILLEGAL: `as`, `late`, `!`, `.then()`, global state

**Architecture**
- NO DUPLICATION—search before adding, move don't copy
- Return `Result<T,E>` (nadz) instead of throwing exceptions
- Functions < 20 lines, files < 500 LOC
- Switch expressions/ternaries over if/else (except in declarative contexts)
- Where Typescript code exists with no Dart wrapper, create the Dart wrapper APIs and add to the appropriate packages.
- Keep all app state in one place. No global state

**Testing**
- 100% coverage with high-level integration tests, not unit tests/mocks
- Tests in separate files, not groups. Dart only (JS only for interop testing)
- Never skip tests. Never remove assertions. Failing tests OK, silent failures = ⛔️ ILLEGAL. Aggressively unskip tests.
- Fixing bugs: write test that fails because of bug -> run test to verify failure -> fix bug -> run test to verify pass
- NO PLACEHOLDERS—throw if incomplete

**Dependencies**
- All packages require: `austerity` (linting), `nadz` (Result types)
- `node_preamble` for dart2js Node.js compatibility

**Pull Requests**
- Keep the documentation tight
- Use the template: .github/PULL_REQUEST_TEMPLATE.md
- Only use git diff with main. Ignore commit messages

**Releases (Shipwright `[SWR-VERSION-BUILD-STAMPING]`)**
- Every `version:` in `packages/*/pubspec.yaml` MUST stay `0.0.0-dev` on every branch. The real version is
  stamped from the git tag in the CI runner working tree at publish time — NEVER committed, pushed, branched,
  or PR'd back. Releases produce ZERO source churn.
- ⛔️ ILLEGAL: bumping a `version:` in source, or a PR that turns a `0.0.0-dev` placeholder into a real version.
- Internal deps stay as local `path:` deps in source; `tools/prepare_publish.dart <version>` rewrites them
  in-runner. Only CHANGELOG entries are committed for a release.

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
  jsx_demo/             # JSX syntax demo
```

## Duplication — Deslop ([CI-DESLOP])

Code duplication is debt and is gated in CI by Deslop (threshold in `.deslop.toml`,
ratcheted DOWN only). Use the Deslop MCP tools to prevent duplication:

- **BEFORE** writing any function, method, class, helper, fixture, or test setup →
  call `find-similar`. `signals.fused ≥ 0.85` or an `identical`/`nearly_identical`
  bucket → reuse the existing code, do not duplicate. `0.6 ≤ fused < 0.85` → review
  the canonical occurrence and bias toward reuse. `fused < 0.6` or empty → proceed.
- **AFTER** changing code → `rescan`, then `top-offenders` (worst clusters) and
  `cluster-by-id` (members + signals for a cluster you plan to merge). Use
  `report-for-file` / `report-for-range` for a specific file/selection. Call
  `schema-doc` once per session to learn the report shape.
- **NEVER** silence findings by raising the threshold, marking code `hidden`, or
  splitting it into trivially different shapes.

## Git Discipline ([BRANCH-AGENT])

- **NEVER push to `main` directly.** Every change ships via PR → CI green → merge.
- **NEVER list yourself (the agent) as a commit co-author.** No `Co-Authored-By`.
- **Work on exactly ONE branch at a time.** Reuse the existing feature branch.
- **NEVER start a new branch when a feature branch already exists.** Check first.
- **If multiple feature branches exist, merge them into one IMMEDIATELY**, before
  any other work.
- **Worktrees are forbidden.** Never run `git worktree`.

## Autonomy ([AGENT-AUTONOMY])

- **Act autonomously. Do NOT stop to ask the user questions.** When something is
  ambiguous, choose the most reasonable default, record the assumption, continue
  to completion. No mid-task pauses for confirmation. Deliver finished work plus a
  short summary of any assumptions made.

## Auto-memory ([AGENT-AUTOMEMORY])

Auto-memory is OFF (`"autoMemoryEnabled": false` in `.claude/settings.json`). All
persistent rules go through a reviewed PR to this file — never auto-captured memory.