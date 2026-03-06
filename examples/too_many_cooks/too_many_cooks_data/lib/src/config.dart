/// Configuration for Too Many Cooks data layer.
///
/// SINGLE SOURCE OF TRUTH for database path resolution.
/// Both the MCP server and VSCode extension MUST use this package
/// to resolve the database path. The database is ALWAYS at
/// `${workspaceFolder}/.too_many_cooks/data.db`.
library;

import 'dart:js_interop';

/// Data layer configuration.
typedef TooManyCooksDataConfig = ({
  String dbPath,
  int lockTimeoutMs,
  int maxMessageLength,
  int maxPlanLength,
});

/// Resolve database path for a workspace folder.
/// Returns `${workspaceFolder}/.too_many_cooks/data.db`
String resolveDbPath(String workspaceFolder) =>
    '$workspaceFolder/.too_many_cooks/data.db';

/// Default configuration values.
const defaultLockTimeoutMs = 600000;
const defaultMaxMessageLength = 200;
const defaultMaxPlanLength = 100;

/// Create config with explicit dbPath.
TooManyCooksDataConfig createDataConfig({
  required String dbPath,
  int lockTimeoutMs = defaultLockTimeoutMs,
  int maxMessageLength = defaultMaxMessageLength,
  int maxPlanLength = defaultMaxPlanLength,
}) => (
  dbPath: dbPath,
  lockTimeoutMs: lockTimeoutMs,
  maxMessageLength: maxMessageLength,
  maxPlanLength: maxPlanLength,
);

/// Create config from workspace folder.
TooManyCooksDataConfig createDataConfigFromWorkspace(String workspaceFolder) =>
    createDataConfig(dbPath: resolveDbPath(workspaceFolder));

// === Workspace resolution (Node.js process) ===

@JS('process')
external _Process get _process;

extension type _Process(JSObject _) implements JSObject {
  external _Env get env;
  external String cwd();
}

extension type _Env(JSObject _) implements JSObject {
  @JS('TMC_WORKSPACE')
  external JSString? get tmcWorkspace;
}

/// Get workspace folder from TMC_WORKSPACE env var or process.cwd().
///
/// This is the canonical way to resolve the workspace for the MCP server.
/// The VSCode extension should pass its workspace folder explicitly
/// via [createDataConfigFromWorkspace].
String getWorkspaceFolder() =>
    _process.env.tmcWorkspace?.toDart ?? _process.cwd();

/// Default configuration using the resolved workspace folder.
/// Used by the MCP server when no explicit config is provided.
final defaultConfig = createDataConfigFromWorkspace(getWorkspaceFolder());
