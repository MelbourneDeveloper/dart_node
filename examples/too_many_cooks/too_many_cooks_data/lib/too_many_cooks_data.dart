/// Shared data access layer for Too Many Cooks multi-agent coordination.
///
/// This package provides direct database access for both the MCP server
/// and VSCode extension, enabling coordinated file locking, messaging,
/// and plan sharing between AI agents.
library;

export 'src/config.dart';
export 'src/db.dart';
export 'src/schema.dart';
export 'src/types.dart';
