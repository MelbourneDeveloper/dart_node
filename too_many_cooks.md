# Too Many Cooks - Multi-Agent Git Coordination MCP Server

## Overview

"Too Many Cooks" is an MCP server enabling multiple AI agents to safely edit a git repository simultaneously. It provides concurrency control through advisory file locking, agent identity verification, inter-agent messaging, and plan visibility.

**Location**: `examples/too_many_cooks/`

**Tech Stack**:
- Dart on Node.js via dart_node
- `better-sqlite3` via JS interop (new package: `packages/dart_node_better_sqlite3/`)
- MCP via `dart_node_mcp`
- All FP: typedef records, pure functions, `Result<T,E>` from nadz

---

## Database Schema

### Table: `identity`
Agent registration and liveness tracking.

```sql
CREATE TABLE identity (
  agent_name TEXT PRIMARY KEY,        -- Unique display name (visible to others)
  agent_key TEXT NOT NULL UNIQUE,     -- Secret key (NOT visible to others)
  registered_at INTEGER NOT NULL,     -- Unix timestamp ms
  last_active INTEGER NOT NULL        -- Updated on EVERY tool call
);
```

### Table: `locks`
File-level advisory locks with lease expiration.

```sql
CREATE TABLE locks (
  file_path TEXT PRIMARY KEY,         -- Absolute or repo-relative path
  agent_name TEXT NOT NULL,           -- Who holds the lock
  acquired_at INTEGER NOT NULL,       -- Unix timestamp ms
  expires_at INTEGER NOT NULL,        -- Auto-expire time
  reason TEXT,                        -- Brief: why locked (~100 chars)
  version INTEGER NOT NULL DEFAULT 1, -- Optimistic concurrency
  FOREIGN KEY (agent_name) REFERENCES identity(agent_name)
);
```

### Table: `messages`
Short inter-agent messages (~200 char limit).

```sql
CREATE TABLE messages (
  id TEXT PRIMARY KEY,                -- UUID
  from_agent TEXT NOT NULL,           -- Sender name
  to_agent TEXT NOT NULL,             -- Recipient name (or '*' for broadcast)
  content TEXT NOT NULL,              -- Max ~200 chars
  created_at INTEGER NOT NULL,        -- Unix timestamp ms
  read_at INTEGER,                    -- NULL until read
  FOREIGN KEY (from_agent) REFERENCES identity(agent_name)
);

CREATE INDEX idx_messages_inbox ON messages(to_agent, read_at, created_at DESC);
```

### Table: `plans`
One plan per agent - what they're doing and why.

```sql
CREATE TABLE plans (
  agent_name TEXT PRIMARY KEY,        -- One plan per agent
  goal TEXT NOT NULL,                 -- Brief goal (~100 chars)
  current_task TEXT NOT NULL,         -- What they're doing now (~100 chars)
  updated_at INTEGER NOT NULL,        -- Unix timestamp ms
  FOREIGN KEY (agent_name) REFERENCES identity(agent_name)
);
```

---

## Configuration

```dart
typedef TooManyCooksConfig = ({
  String dbPath,              // SQLite database path
  int lockTimeoutMs,          // Default: 600000 (10 minutes)
  int maxMessageLength,       // Default: 200
  int maxPlanLength,          // Default: 100 per field
});

const defaultConfig = (
  dbPath: '.too_many_cooks.db',
  lockTimeoutMs: 600000,
  maxMessageLength: 200,
  maxPlanLength: 100,
);
```

---

## Core Types (typedef records)

```dart
// Identity
typedef AgentIdentity = ({
  String agentName,
  int registeredAt,
  int lastActive,
});

typedef AgentRegistration = ({
  String agentName,
  String agentKey,  // Only returned on registration
});

// Locks
typedef FileLock = ({
  String filePath,
  String agentName,
  int acquiredAt,
  int expiresAt,
  String? reason,
  int version,
});

typedef LockResult = ({
  bool acquired,
  FileLock? lock,
  String? error,  // e.g., "held by agent-X until ..."
});

// Messages
typedef Message = ({
  String id,
  String fromAgent,
  String toAgent,
  String content,
  int createdAt,
  int? readAt,
});

// Plans
typedef AgentPlan = ({
  String agentName,
  String goal,
  String currentTask,
  int updatedAt,
});
```

---

## Data Access Layer

Haskell-style typeclass pattern using typedef of function signatures:

```dart
/// Database operations - all return Result<T, DbError>
typedef TypedefName = ({

// [...]

});

//Create a type class for each of these

  // Identity
  Result<AgentRegistration, DbError> Function(String agentName) register,
  Result<AgentIdentity, DbError> Function(String agentName, String agentKey) authenticate,
  Result<List<AgentIdentity>, DbError> Function() listAgents,
  Result<void, DbError> Function(String agentName, String agentKey) heartbeat,

  // Locks
  Result<LockResult, DbError> Function(String filePath, String agentName, String agentKey, String? reason) acquireLock,
  Result<void, DbError> Function(String filePath, String agentName, String agentKey) releaseLock,
  Result<void, DbError> Function(String filePath, String agentName, String agentKey) forceReleaseLock, // For expired locks
  Result<FileLock?, DbError> Function(String filePath) queryLock,
  Result<List<FileLock>, DbError> Function() listLocks,
  Result<void, DbError> Function(String filePath, String agentName, String agentKey) renewLock,

  // Messages
  Result<void, DbError> Function(String fromAgent, String fromKey, String toAgent, String content) sendMessage,
  Result<List<Message>, DbError> Function(String agentName, String agentKey, {bool unreadOnly}) getMessages,
  Result<void, DbError> Function(String messageId, String agentName, String agentKey) markRead,

  // Plans
  Result<void, DbError> Function(String agentName, String agentKey, String goal, String currentTask) updatePlan,
  Result<AgentPlan?, DbError> Function(String agentName) getPlan,
  Result<List<AgentPlan>, DbError> Function() listPlans,

/// Error types
typedef DbError = ({String code, String message});

// Error codes
const errNotFound = 'NOT_FOUND';
const errUnauthorized = 'UNAUTHORIZED';
const errLockHeld = 'LOCK_HELD';
const errLockExpired = 'LOCK_EXPIRED';
const errValidation = 'VALIDATION';
const errDatabase = 'DATABASE';
```

---

## File Protection (chmod)

No chmod for now. Only logical file locks - not physical

---

## MCP Tools

### Identity Tools

#### `register_agent`
Register a new agent identity.
```dart
Input: { name: string }
Output: { agent_name: string, agent_key: string }
```
- Generates unique key (UUID)
- Returns key ONLY on registration (store it!)

#### `list_agents`
List all registered agents (names + last_active only).
```dart
Input: { }
Output: { agents: [{ name: string, last_active: int }] }
```

### Lock Tools

#### `acquire_lock`
Acquire exclusive lock on a file.
```dart
Input: {
  file_path: string,
  agent_name: string,
  agent_key: string,
  reason?: string  // Brief: why you need this
}
Output: {
  acquired: bool,
  lock?: { file_path, agent_name, expires_at, reason },
  error?: string
}
```
- Fails if already locked (unless expired)

#### `release_lock`
Release a lock you hold.
```dart
Input: { file_path: string, agent_name: string, agent_key: string }
Output: { released: bool }
```

#### `force_release_lock`
Release an EXPIRED lock held by another agent.
```dart
Input: { file_path: string, agent_name: string, agent_key: string }
Output: { released: bool, error?: string }
```
- Only works if lock.expires_at < now
- Restores chmod

#### `renew_lock`
Extend expiration on your lock.
```dart
Input: { file_path: string, agent_name: string, agent_key: string }
Output: { renewed: bool, new_expires_at: int }
```

#### `query_lock`
Check if a file is locked.
```dart
Input: { file_path: string }
Output: { locked: bool, lock?: { file_path, agent_name, expires_at, reason } }
```

#### `list_locks`
List all active locks.
```dart
Input: { }
Output: { locks: [{ file_path, agent_name, expires_at, reason }] }
```

### Message Tools

#### `send_message`
Send a short message to another agent.
```dart
Input: {
  agent_name: string,
  agent_key: string,
  to_agent: string,  // Or '*' for broadcast
  content: string    // Max 200 chars
}
Output: { sent: bool, message_id: string }
```

#### `get_messages`
Retrieve your messages.
```dart
Input: {
  agent_name: string,
  agent_key: string,
  unread_only?: bool  // Default: true
}
Output: { messages: [{ id, from_agent, content, created_at, read_at }] }
```

#### `mark_message_read`
Mark a message as read.
```dart
Input: { message_id: string, agent_name: string, agent_key: string }
Output: { marked: bool }
```

### Plan Tools

#### `update_plan`
Set/update your current plan.
```dart
Input: {
  agent_name: string,
  agent_key: string,
  goal: string,         // Max 100 chars - overall objective
  current_task: string  // Max 100 chars - what you're doing NOW
}
Output: { updated: bool }
```

#### `get_plan`
Get a specific agent's plan.
```dart
Input: { agent_name: string }
Output: { plan?: { agent_name, goal, current_task, updated_at } }
```

#### `list_plans`
List all agents' plans.
```dart
Input: { }
Output: { plans: [{ agent_name, goal, current_task, updated_at }] }
```

---

## Packages to Create

### 1. `packages/dart_node_better_sqlite3/`

Dart bindings for better-sqlite3 npm package.

```dart
// Core types
typedef Database = ({
  Result<Statement, String> Function(String sql) prepare,
  Result<void, String> Function(String sql) exec,
  Result<void, String> Function() close,
  void Function(String pragma) pragma,
});

typedef Statement = ({
  Result<List<Map<String, Object?>>, String> Function([List<Object?>? params]) all,
  Result<Map<String, Object?>?, String> Function([List<Object?>? params]) get,
  Result<RunResult, String> Function([List<Object?>? params]) run,
});

typedef RunResult = ({int changes, int lastInsertRowid});

// Factory
Result<Database, String> openDatabase(String path);
```

Key implementation notes:
- Enable WAL mode: `db.pragma('journal_mode = WAL')`
- Set busy timeout: `db.pragma('busy_timeout = 5000')`
- Use IMMEDIATE transactions for writes

### 2. `examples/too_many_cooks/`

The MCP server implementation.

```
examples/too_many_cooks/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── too_many_cooks.dart           # Main export
│   └── src/
│       ├── types.dart                # All typedef records
│       ├── config.dart               # Configuration
│       ├── db/
│       │   ├── schema.dart           # SQL schema constants
│       │   ├── db.dart               # TooManyCooksDb implementation
│       │   └── migrations.dart       # Schema versioning
│       ├── file_protection.dart      # chmod operations
│       ├── tools/
│       │   ├── identity_tools.dart   # register_agent, list_agents
│       │   ├── lock_tools.dart       # acquire_lock, release_lock, etc.
│       │   ├── message_tools.dart    # send_message, get_messages, etc.
│       │   └── plan_tools.dart       # update_plan, get_plan, list_plans
│       └── server.dart               # MCP server setup
├── bin/
│   └── server.dart                   # Entry point
└── test/
    ├── db_test.dart
    ├── lock_test.dart
    ├── message_test.dart
    ├── plan_test.dart
    └── integration_test.dart
```

---

## Key Implementation Details

### Authentication on Every Call

Every tool that takes `agent_name` + `agent_key` MUST:
1. Verify key matches the registered agent
2. Update `last_active` timestamp on success
3. Return `UNAUTHORIZED` error on mismatch

```dart
Result<void, DbError> authenticateAndUpdateActivity(
  Database db,
  String agentName,
  String agentKey,
) {
  final result = db.prepare('''
    UPDATE identity
    SET last_active = ?
    WHERE agent_name = ? AND agent_key = ?
  ''').run([DateTime.now().millisecondsSinceEpoch, agentName, agentKey]);

  return switch (result) {
    Success(:final value) when value.changes == 0 =>
      Error((code: errUnauthorized, message: 'Invalid agent credentials')),
    Success(_) => Success(null),
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}
```

### Lock Expiry Check

Any agent can force-release expired locks:

```dart
Result<void, DbError> forceReleaseLock(
  Database db,
  String filePath,
  String requestingAgent,
  String requestingKey,
) {
  // 1. Authenticate requesting agent (updates their last_active)
  // 2. Check if lock exists and is expired
  // 3. If expired: restore chmod, delete lock
  // 4. If not expired: return error with holder info
}
```

### Optimistic Concurrency for Locks

Use version column to prevent race conditions:

```dart
// Acquire: INSERT OR fail if exists
// Release: DELETE WHERE version = expected_version
// Renew: UPDATE ... SET version = version + 1 WHERE version = ?
```

---

## VSCode Extension

*[Placeholder - to be designed separately]*

---

## Usage Example

```dart
import 'package:too_many_cooks/too_many_cooks.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';

Future<void> main() async {
  final serverResult = createTooManyCooksServer(
    config: defaultConfig,
  );

  final server = switch (serverResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  final transportResult = createStdioServerTransport();
  final transport = switch (transportResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  await server.connect(transport);
}
```

---

## Implementation Order

1. **dart_node_better_sqlite3** - SQLite bindings package
2. **too_many_cooks/db** - Schema + data access layer
3. **too_many_cooks/file_protection** - chmod operations
4. **too_many_cooks/tools** - MCP tool implementations
5. **too_many_cooks/server** - Wire it all together
6. **Tests** - Comprehensive test suite
