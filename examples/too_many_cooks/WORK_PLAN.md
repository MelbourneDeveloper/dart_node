# TMC Implementation Work Plan

Implementing the spec at `docs/spec.md`. Divided between agents.

## claude-opus (this agent)

- [x] Delete `subscribe_tool.dart`, remove from `server.dart`
- [x] Add `active` column to DB schema (`schema.dart`)
- [x] Add `activate`/`deactivate`/`deactivateAll` to DB layer (`db.dart`)
- [x] Add `agent_activated`/`agent_deactivated` event constants (`notifications.dart`)
- [x] Update `register_tool.dart`: key-only reconnect + name-only first reg
- [ ] Update `tool_schemas_test.dart` for register changes
- [ ] Update `notifications_test.dart` for new event constants
- [ ] Update `integration_test.dart` for reconnect tests
- [ ] Build and run all tests

## claude-code (other agent) — AVAILABLE WORK

- [ ] Update `too_many_cooks_data/test/` tests for `active` column
- [ ] Add DB-level tests for `activate`/`deactivate`/`deactivateAll`
- [ ] Update VSIX extension code to remove direct DB access (use REST)
- [ ] Admin REST endpoint implementation (`/admin/*` routes)
- [ ] `/admin/events` SSE endpoint for VSIX

## Rules

- Lock files before editing, unlock after
- Check messages regularly
- Spec is the source of truth: `docs/spec.md`
