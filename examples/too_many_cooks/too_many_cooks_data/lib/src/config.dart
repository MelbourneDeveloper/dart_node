/// Configuration for Too Many Cooks data layer.
library;

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
