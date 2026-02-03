/// MCP-specific types for Too Many Cooks server.
library;

// Re-export all types from shared package.
export 'package:too_many_cooks_data/too_many_cooks_data.dart'
    show
        AgentIdentity,
        AgentPlan,
        AgentRegistration,
        DbError,
        FileLock,
        LockResult,
        Message,
        errDatabase,
        errLockExpired,
        errLockHeld,
        errNotFound,
        errUnauthorized,
        errValidation;

/// Create text content for MCP tool responses.
/// Uses Map which is required for dart2js compatibility with records.
Map<String, Object?> textContent(String text) => <String, Object?>{
  'type': 'text',
  'text': text,
};
