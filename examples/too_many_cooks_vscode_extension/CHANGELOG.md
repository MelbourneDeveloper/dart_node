# Changelog

All notable changes to the "Too Many Cooks" extension will be documented in this file.

## [0.3.0] - 2025-06-14

### Changed
- Uses `npx too-many-cooks` by default - same server as Claude Code
- Shared SQLite database ensures both VSCode and Claude Code see the same state

### Added
- Admin commands: Force Release Lock, Remove Agent
- Send Message command with broadcast support
- Real-time polling (2s interval) for cross-process updates
- Comprehensive logging via Output Channel

### Fixed
- Server path configuration removed in favor of unified npx approach

## [0.1.0] - 2025-01-01

### Added

- Initial release
- Agents panel showing registered agents and activity status
- File Locks panel displaying current locks and holders
- Messages panel for inter-agent communication
- Plans panel showing agent goals and current tasks
- Auto-connect on startup (configurable)
- Manual refresh command
- Dashboard view
