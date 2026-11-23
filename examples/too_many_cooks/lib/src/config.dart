/// Configuration for Too Many Cooks MCP server.
library;

import 'dart:js_interop';

/// Server configuration.
typedef TooManyCooksConfig = ({
  String dbPath,
  int lockTimeoutMs,
  int maxMessageLength,
  int maxPlanLength,
});

@JS('process')
external _Process get _process;

extension type _Process(JSObject _) implements JSObject {
  external _Env get env;
}

extension type _Env(JSObject _) implements JSObject {
  @JS('HOME')
  external JSString? get home;
}

/// Get default database path in user home directory.
/// All MCP server instances MUST use this same path for shared state.
String _getDefaultDbPath() {
  final home = _process.env.home?.toDart ?? '/tmp';
  return '$home/.too_many_cooks/data.db';
}

/// Default configuration.
final defaultConfig = (
  dbPath: _getDefaultDbPath(),
  lockTimeoutMs: 600000,
  maxMessageLength: 200,
  maxPlanLength: 100,
);
