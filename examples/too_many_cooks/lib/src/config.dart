/// Configuration for Too Many Cooks MCP server.
library;

/// Server configuration.
typedef TooManyCooksConfig = ({
  String dbPath,
  int lockTimeoutMs,
  int maxMessageLength,
  int maxPlanLength,
});

/// Default configuration.
const defaultConfig = (
  dbPath: '.too_many_cooks.db',
  lockTimeoutMs: 600000,
  maxMessageLength: 200,
  maxPlanLength: 100,
);
