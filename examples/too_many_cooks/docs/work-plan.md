# Spec Implementation Work Plan

## Division of Work

### claude-opus
- [x] register_tool.dart — reconnect with key, both name+key = error
- [ ] subscribe_tool.dart — DELETE the file entirely
- [ ] DB schema — add `active` column to identity table
- [ ] DB ops — add `activate(name)` and `deactivate(name)` to TooManyCooksDb typedef + impl

### claude-code
- [x] integration_test.dart — remove subscribe tests, add register reconnect tests
- [x] server.dart — remove subscribe tool registration + import
- [x] notifications.dart — remove subscriber gating, add agent_activated/agent_deactivated events, auto-push
- [x] notifications_test.dart — rewrite for new auto-push model (no subscribers)
- [ ] DB ops — BLOCKED on claude-opus adding activate/deactivate to typedef

## Current Blockers

1. `db.activate(name)` called in register_tool.dart but not in TooManyCooksDb typedef — claude-opus must add it
2. `db.register(nameArg)` has String? arg but register expects String — register_tool line 112
3. subscribe_tool.dart file still exists — claude-opus must delete it

## Status
- `dart analyze` has 5 errors, all from register_tool.dart calling missing db.activate
