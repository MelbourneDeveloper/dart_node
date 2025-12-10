/// Core types for Too Many Cooks MCP server.
library;

/// Agent identity (public info only - no key).
typedef AgentIdentity = ({
  String agentName,
  int registeredAt,
  int lastActive,
});

/// Agent registration result (includes secret key).
typedef AgentRegistration = ({
  String agentName,
  String agentKey,
});

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
typedef LockResult = ({
  bool acquired,
  FileLock? lock,
  String? error,
});

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

/// Create text content for MCP tool responses.
/// Uses Map which is required for dart2js compatibility with records.
Map<String, Object?> textContent(String text) =>
    <String, Object?>{'type': 'text', 'text': text};
