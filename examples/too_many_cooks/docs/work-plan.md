# Spec Implementation Work Plan

## Division of Work

### claude-opus
- [x] register_tool.dart — reconnect with key, both name+key = error
- [x] subscribe_tool.dart — DELETE the file entirely
- [x] DB schema — add `active` column to identity table
- [x] DB ops — add `activate(name)` and `deactivate(name)` to TooManyCooksDb typedef + impl
- [x] DB ops — add `lookupByKey`, `adminSendMessage`
- [x] too_many_cooks_data — 8 new activate/deactivate tests (76 total)
- [x] VSIX test_helpers.dart — fix dart:io → Node.js APIs (os.tmpdir, fs.mkdtempSync)
- [x] run_tests.sh — runs all 3 packages (data + MCP + VSIX)

### claude-code
- [x] integration_test.dart — remove subscribe tests, add register reconnect tests
- [x] server.dart — remove subscribe tool registration + import
- [x] notifications.dart — remove subscriber gating, add agent_activated/agent_deactivated events, auto-push
- [x] notifications_test.dart — rewrite for new auto-push model (no subscribers)
- [x] Fix schema validation tests (MCP SDK Zod returns errors differently)
- [x] Fix notification emitter error handling for stdio transport
- [x] Fix build: must use scripts/mcp.sh build (preamble required)
- [x] VSIX extension_activation_test.dart — 5 dart tests pass
- [x] VSIX suite tests — 98 tests pass via `npm test`

## Current Blockers

None — all blockers resolved.

## Status — VERIFIED
- `dart analyze` clean (0 errors) across ALL 3 packages
- **too_many_cooks_data**: 76 tests pass (`dart test`) — includes activate/deactivate/lookupByKey
- **too_many_cooks (MCP server)**: 69 tests pass (`dart test`) — 25 integration (spawn real MCP process) + 44 unit
- **too_many_cooks_vscode_extension**: 5 dart tests (`dart test`) + 98 E2E suite tests (`npm test`) = 103 tests
  - Suite tests are END-TO-END: VSCode Extension Host + real SQLite DB + real MCP tools
  - MCP server must be built BEFORE suite tests (run_tests.sh handles this)
- **Total: 248 tests passing**
- Server builds correctly with preamble via scripts/mcp.sh build
- `scripts/e2e.sh` runs ALL tests in correct order:
  1. Data package tests (`dart test`)
  2. MCP server build (compile JS + add preamble)
  3. MCP server tests (`dart test` — spawns real server process)
  4. VSIX dart tests (`dart test`)
  5. VSIX E2E suite tests (`npm test` — real Extension Host + real DB)

## Remaining Spec Items
- [ ] Server-side deactivation on disconnect (mark agent inactive when SSE drops)
- [ ] Admin REST endpoints (/admin/delete-lock, /admin/delete-agent, etc.)
- [ ] /admin/events SSE endpoint for VSIX
- [ ] VSCode extension — further development (UI, real-time updates, etc.)
