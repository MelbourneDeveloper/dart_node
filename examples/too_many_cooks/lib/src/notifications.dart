/// Notification system for push-based updates.
library;

import 'dart:async';

import 'package:dart_node_mcp/dart_node_mcp.dart';

/// Event type for agent registration.
const eventAgentRegistered = 'agent_registered';

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

/// All possible event types.
const allEventTypes = [
  eventAgentRegistered,
  eventLockAcquired,
  eventLockReleased,
  eventLockRenewed,
  eventMessageSent,
  eventPlanUpdated,
];

/// Subscriber record.
typedef Subscriber = ({
  String subscriberId,
  List<String> events, // Event types or ['*'] for all
});

/// Notification payload.
typedef NotificationPayload = ({
  String event,
  int timestamp,
  Map<String, Object?> payload,
});

/// Notification emitter - broadcasts events to subscribers via MCP logging.
typedef NotificationEmitter = ({
  void Function(Subscriber subscriber) addSubscriber,
  void Function(String subscriberId) removeSubscriber,
  void Function(String event, Map<String, Object?> payload) emit,
  List<Subscriber> Function() getSubscribers,
});

/// Create a notification emitter that uses the MCP server's logging.
NotificationEmitter createNotificationEmitter(McpServer server) {
  final subscribers = <String, Subscriber>{};

  void addSubscriber(Subscriber subscriber) {
    subscribers[subscriber.subscriberId] = subscriber;
  }

  void removeSubscriber(String subscriberId) {
    subscribers.remove(subscriberId);
  }

  List<Subscriber> getSubscribers() => subscribers.values.toList();

  void emit(String event, Map<String, Object?> payload) {
    // Only emit if there are subscribers interested in this event
    final interestedSubscribers = subscribers.values.where(
      (s) => s.events.contains('*') || s.events.contains(event),
    );

    if (interestedSubscribers.isEmpty) return;

    // Send notification via MCP logging message
    final notificationData = <String, Object?>{
      'event': event,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
    };

    unawaited(
      server.sendLoggingMessage((
        level: 'info',
        logger: 'too-many-cooks',
        data: notificationData,
      )),
    );
  }

  return (
    addSubscriber: addSubscriber,
    removeSubscriber: removeSubscriber,
    emit: emit,
    getSubscribers: getSubscribers,
  );
}
