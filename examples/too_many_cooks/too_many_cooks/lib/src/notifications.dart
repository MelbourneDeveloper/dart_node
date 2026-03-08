/// Notification system for push-based updates.
///
/// All events are pushed automatically to every connected client (agents +
/// VSIX). There is no subscribe tool — subscriptions are managed entirely by
/// the server based on connection state.
library;

import 'dart:async';

import 'package:dart_node_mcp/dart_node_mcp.dart';

/// Event type for agent registration.
const eventAgentRegistered = 'agent_registered';

/// Event type for agent activation (reconnect).
const eventAgentActivated = 'agent_activated';

/// Event type for agent deactivation (disconnect).
const eventAgentDeactivated = 'agent_deactivated';

/// Event type for lock acquisition.
const eventLockAcquired = 'lock_acquired';

/// Event type for lock release.
const eventLockReleased = 'lock_released';

/// Event type for lock renewal.
const eventLockRenewed = 'lock_renewed';

/// Event type for message sent.
const eventMessageSent = 'message_sent';

/// Event type for plan update.
const eventPlanUpdated = 'plan_updated';

/// Callback type for pushing events to the admin hub.
typedef AdminPushFn =
    void Function(String event, Map<String, Object?> payload);

/// Notification emitter - broadcasts events to all connected clients via MCP
/// logging. No subscriber management — events push automatically.
typedef NotificationEmitter = ({
  void Function(String event, Map<String, Object?> payload) emit,
});

/// Create a notification emitter that uses the MCP server's logging
/// and optionally also pushes to the admin event hub (for the VSIX).
NotificationEmitter createNotificationEmitter(
  McpServer server, {
  AdminPushFn? adminPush,
}) {
  void emit(String event, Map<String, Object?> payload) {
    final notificationData = <String, Object?>{
      'event': event,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
    };

    unawaited(
      server
          .sendLoggingMessage((
            level: 'info',
            logger: 'too-many-cooks',
            data: notificationData,
          ))
          .then((_) {}, onError: (_) {}),
    );

    // Also push to admin hub so the VSIX gets real-time updates
    adminPush?.call(event, payload);
  }

  return (emit: emit,);
}
