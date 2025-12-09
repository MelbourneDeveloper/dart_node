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

/// Error codes.
const errNotFound = 'NOT_FOUND';
const errUnauthorized = 'UNAUTHORIZED';
const errLockHeld = 'LOCK_HELD';
const errLockExpired = 'LOCK_EXPIRED';
const errValidation = 'VALIDATION';
const errDatabase = 'DATABASE';
