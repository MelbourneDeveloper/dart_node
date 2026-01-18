/// MCP types for Too Many Cooks VSCode extension.
///
/// Uses typedef records for structural typing as per CLAUDE.md.
library;

/// Agent identity (public info only - no key).
typedef AgentIdentity = ({String agentName, int registeredAt, int lastActive});

/// File lock info.
typedef FileLock = ({
  String filePath,
  String agentName,
  int acquiredAt,
  int expiresAt,
  String? reason,
  int version,
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

/// Agent plan.
typedef AgentPlan = ({
  String agentName,
  String goal,
  String currentTask,
  int updatedAt,
});

/// Notification event types for real-time MCP server updates.
enum NotificationEventType {
  /// A new agent has registered with the MCP server.
  agentRegistered,

  /// A file lock has been acquired by an agent.
  lockAcquired,

  /// A file lock has been released by an agent.
  lockReleased,

  /// A file lock's expiration time has been extended.
  lockRenewed,

  /// A message has been sent between agents.
  messageSent,

  /// An agent's plan has been updated.
  planUpdated,
}

/// Parse notification event type from string.
NotificationEventType? parseNotificationEventType(String value) =>
    switch (value) {
      'agent_registered' => NotificationEventType.agentRegistered,
      'lock_acquired' => NotificationEventType.lockAcquired,
      'lock_released' => NotificationEventType.lockReleased,
      'lock_renewed' => NotificationEventType.lockRenewed,
      'message_sent' => NotificationEventType.messageSent,
      'plan_updated' => NotificationEventType.planUpdated,
      _ => null,
    };
