/// Subscribe tool - notification subscriptions.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:too_many_cooks/src/notifications.dart';

/// Input schema for subscribe tool.
const subscribeInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'action': {
      'type': 'string',
      'enum': ['subscribe', 'unsubscribe', 'list'],
      'description': 'Subscribe, unsubscribe, or list subscribers',
    },
    'subscriber_id': {
      'type': 'string',
      'description': 'Unique subscriber identifier (e.g., "vscode-extension")',
    },
    'events': {
      'type': 'array',
      'items': {'type': 'string'},
      'description': 'Event types to subscribe to, or ["*"] for all. '
          'Events: agent_registered, lock_acquired, lock_released, '
          'lock_renewed, message_sent, plan_updated',
    },
  },
  'required': ['action'],
};

/// Tool config for subscribe.
const subscribeToolConfig = (
  title: 'Subscribe',
  description: 'Subscribe to real-time notifications for state changes',
  inputSchema: subscribeInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create subscribe tool handler.
ToolCallback createSubscribeHandler(NotificationEmitter emitter) =>
    (args, meta) async {
      final action = args['action']! as String;

      return switch (action) {
        'subscribe' => _subscribe(
            emitter,
            args['subscriber_id'] as String?,
            args['events'] as List<Object?>?,
          ),
        'unsubscribe' => _unsubscribe(
            emitter,
            args['subscriber_id'] as String?,
          ),
        'list' => _list(emitter),
        _ => (
            content: <Object>[
              (type: 'text', text: '{"error":"Unknown action: $action"}'),
            ],
            isError: true,
          ),
      };
    };

CallToolResult _subscribe(
  NotificationEmitter emitter,
  String? subscriberId,
  List<Object?>? events,
) {
  if (subscriberId == null) {
    return (
      content: <Object>[
        (
          type: 'text',
          text: '{"error":"subscribe requires subscriber_id"}',
        ),
      ],
      isError: true,
    );
  }

  // Default to all events if not specified
  final eventList = events?.map((e) => e.toString()).toList() ?? ['*'];

  // Validate event types
  final validEvents = [...allEventTypes, '*'];
  final invalidEvents =
      eventList.where((e) => !validEvents.contains(e)).toList();
  if (invalidEvents.isNotEmpty) {
    return (
      content: <Object>[
        (
          type: 'text',
          text: '{"error":"Invalid event types: ${invalidEvents.join(', ')}"}',
        ),
      ],
      isError: true,
    );
  }

  emitter.addSubscriber((subscriberId: subscriberId, events: eventList));

  return (
    content: <Object>[
      (
        type: 'text',
        text: '{"subscribed":true,"subscriber_id":"$subscriberId",'
            '"events":["${eventList.join('","')}"]}',
      ),
    ],
    isError: false,
  );
}

CallToolResult _unsubscribe(NotificationEmitter emitter, String? subscriberId) {
  if (subscriberId == null) {
    return (
      content: <Object>[
        (
          type: 'text',
          text: '{"error":"unsubscribe requires subscriber_id"}',
        ),
      ],
      isError: true,
    );
  }

  emitter.removeSubscriber(subscriberId);

  return (
    content: <Object>[
      (
        type: 'text',
        text: '{"unsubscribed":true,"subscriber_id":"$subscriberId"}',
      ),
    ],
    isError: false,
  );
}

CallToolResult _list(NotificationEmitter emitter) {
  final subscribers = emitter.getSubscribers();
  final json = subscribers
      .map(
        (s) => '{"subscriber_id":"${s.subscriberId}",'
            '"events":["${s.events.join('","')}"]}',
      )
      .join(',');

  return (
    content: <Object>[
      (type: 'text', text: '{"subscribers":[$json]}'),
    ],
    isError: false,
  );
}
