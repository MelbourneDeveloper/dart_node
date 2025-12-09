/// SQL schema for Too Many Cooks database.
library;

/// Schema version for migrations.
const schemaVersion = 1;

/// Create all tables SQL.
const createTablesSql = '''
CREATE TABLE IF NOT EXISTS identity (
  agent_name TEXT PRIMARY KEY,
  agent_key TEXT NOT NULL UNIQUE,
  registered_at INTEGER NOT NULL,
  last_active INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS locks (
  file_path TEXT PRIMARY KEY,
  agent_name TEXT NOT NULL,
  acquired_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  reason TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (agent_name) REFERENCES identity(agent_name)
);

CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  from_agent TEXT NOT NULL,
  to_agent TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  read_at INTEGER,
  FOREIGN KEY (from_agent) REFERENCES identity(agent_name)
);

CREATE INDEX IF NOT EXISTS idx_messages_inbox
ON messages(to_agent, read_at, created_at DESC);

CREATE TABLE IF NOT EXISTS plans (
  agent_name TEXT PRIMARY KEY,
  goal TEXT NOT NULL,
  current_task TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (agent_name) REFERENCES identity(agent_name)
);

CREATE TABLE IF NOT EXISTS schema_version (
  version INTEGER PRIMARY KEY
);

INSERT OR IGNORE INTO schema_version (version) VALUES ($schemaVersion);
''';
