/// Multi-agent Git coordination MCP server.
///
/// Enables multiple AI agents to safely edit a git repository simultaneously
/// through advisory file locking, identity verification, inter-agent messaging,
/// and plan visibility.
library;

export 'src/config.dart';
export 'src/db/db.dart' show createDb;
export 'src/server.dart';
export 'src/types.dart';
