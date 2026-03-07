/// Multi-agent Git coordination MCP server.
///
/// Enables multiple AI agents to safely edit a git repository simultaneously
/// through advisory file locking, identity verification, inter-agent messaging,
/// and plan visibility.
library;

export 'package:too_many_cooks_data/too_many_cooks_data.dart'
    show TooManyCooksDb, createDb;

export 'src/admin_routes.dart';
export 'src/config.dart';
export 'src/server.dart';
export 'src/types.dart';
