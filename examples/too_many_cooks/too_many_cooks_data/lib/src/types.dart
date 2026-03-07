/// Core types for Too Many Cooks data layer.
library;

/// Agent identity (public info only - no key).
typedef AgentIdentity = ({String agentName, int registeredAt, int lastActive});

/// Agent registration result (includes secret key).
typedef AgentRegistration = ({String agentName, String agentKey});

/// File lock info.
typedef FileLock = ({
  String filePath,
  String agentName,
  int acquiredAt,
  int expiresAt,
  String? reason,
  int version,
});

/// Lock acquisition result.
typedef LockResult = ({bool acquired, FileLock? lock, String? error});

/// Inter-agent message.
typedef Message = ({
  String id,
  String fromAgent,
  String toAgent,
  String content,
  int createdAt,
  int? readAt,
});

/// Agent plan (what they're doing and why).
typedef AgentPlan = ({
  String agentName,
  String goal,
  String currentTask,
  int updatedAt,
});

/// Database error.
typedef DbError = ({String code, String message});

/// Error code for resource not found.
const errNotFound = 'NOT_FOUND';

/// Error code for unauthorized access.
const errUnauthorized = 'UNAUTHORIZED';

/// Error code when lock is held by another agent.
const errLockHeld = 'LOCK_HELD';

/// Error code when lock has expired.
const errLockExpired = 'LOCK_EXPIRED';

/// Error code for validation failures.
const errValidation = 'VALIDATION';

/// Error code for database errors.
const errDatabase = 'DATABASE';

// ============================================================================
// JSON Serialization - SINGLE SOURCE OF TRUTH
// Both MCP server and VSCode extension use these.
// ============================================================================

/// Escape special characters for JSON string values.
String escapeJson(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');

/// Serialize AgentIdentity to JSON string.
String agentIdentityToJson(AgentIdentity a) =>
    '{"agent_name":"${a.agentName}",'
    '"registered_at":${a.registeredAt},'
    '"last_active":${a.lastActive}}';

/// Serialize AgentRegistration to JSON string.
String agentRegistrationToJson(AgentRegistration r) =>
    '{"agent_name":"${r.agentName}","agent_key":"${r.agentKey}"}';

/// Serialize FileLock to JSON string.
String fileLockToJson(FileLock l) =>
    '{"file_path":"${l.filePath}",'
    '"agent_name":"${l.agentName}",'
    '"acquired_at":${l.acquiredAt},'
    '"expires_at":${l.expiresAt},'
    '"version":${l.version}'
    '${l.reason != null ? ',"reason":"${escapeJson(l.reason!)}"' : ''}}';

/// Serialize LockResult to JSON string.
String lockResultToJson(LockResult r) => r.acquired
    ? '{"acquired":true,"lock":${fileLockToJson(r.lock!)}}'
    : '{"acquired":false,"error":"${r.error}"}';

/// Serialize Message to JSON string.
String messageToJson(Message m) =>
    '{"id":"${m.id}",'
    '"from_agent":"${m.fromAgent}",'
    '"to_agent":"${m.toAgent}",'
    '"content":"${escapeJson(m.content)}",'
    '"created_at":${m.createdAt}'
    '${m.readAt != null ? ',"read_at":${m.readAt}' : ''}}';

/// Serialize AgentPlan to JSON string.
String agentPlanToJson(AgentPlan p) =>
    '{"agent_name":"${p.agentName}",'
    '"goal":"${escapeJson(p.goal)}",'
    '"current_task":"${escapeJson(p.currentTask)}",'
    '"updated_at":${p.updatedAt}}';

/// Serialize DbError to JSON string.
String dbErrorToJson(DbError e) => '{"error":"${e.code}: ${e.message}"}';
