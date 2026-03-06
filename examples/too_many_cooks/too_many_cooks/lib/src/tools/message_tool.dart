/// Message tool - inter-agent messaging.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/types.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

/// Input schema for message tool.
const messageInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'action': {
      'type': 'string',
      'enum': ['send', 'get', 'mark_read'],
      'description': 'Message action to perform',
    },
    'to_agent': {
      'type': 'string',
      'description': 'Recipient name or * for broadcast (for send)',
    },
    'content': {
      'type': 'string',
      'maxLength': 200,
      'description': 'Message content (for send). MUST be 200 chars or less.',
    },
    'message_id': {
      'type': 'string',
      'description': 'Message ID (for mark_read)',
    },
    'unread_only': {
      'type': 'boolean',
      'description': 'Only return unread messages (default: true)',
    },
  },
  'required': ['action'],
};

/// Tool config for message.
const messageToolConfig = (
  title: 'Message',
  description:
      'Send/receive messages. You must register first. '
      'REQUIRED: action (send|get|mark_read). '
      'For send: to_agent, content. For mark_read: message_id. '
      'Example send: {"action":"send","to_agent":"other","content":"hello"}',
  inputSchema: messageInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create message tool handler.
ToolCallback createMessageHandler(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger logger,
  SessionGetter getSession,
) => (args, meta) async {
  final actionArg = args['action'];
  if (actionArg == null || actionArg is! String) {
    return (
      content: <Object>[
        textContent('{"error":"missing_parameter: action is required"}'),
      ],
      isError: true,
    );
  }
  final action = actionArg;

  // Hidden agent_key override for multi-agent integration testing
  final keyOverride = args['agent_key'] as String?;
  final String agentName;
  final String agentKey;
  if (keyOverride != null) {
    agentKey = keyOverride;
    switch (db.lookupByKey(keyOverride)) {
      case Success(:final value):
        agentName = value;
      case Error(:final error):
        return _errorResult(error);
    }
  } else {
    final session = getSession();
    if (session == null) {
      return (
        content: <Object>[
          textContent('{"error":"not_registered: call register first"}'),
        ],
        isError: true,
      );
    }
    agentName = session.agentName;
    agentKey = session.agentKey;
  }
  final log = logger.child({'tool': 'message', 'action': action});

  return switch (action) {
    'send' => _send(
      db,
      emitter,
      log,
      agentName,
      agentKey,
      args['to_agent'] as String?,
      args['content'] as String?,
    ),
    'get' => _get(
      db,
      agentName,
      agentKey,
      args['unread_only'] as bool? ?? true,
    ),
    'mark_read' => _markRead(
      db,
      agentName,
      agentKey,
      args['message_id'] as String?,
    ),
    _ => (
      content: <Object>[textContent('{"error":"Unknown action: $action"}')],
      isError: true,
    ),
  };
};

CallToolResult _send(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger log,
  String agentName,
  String agentKey,
  String? toAgent,
  String? content,
) {
  if (toAgent == null || content == null) {
    return (
      content: <Object>[
        textContent('{"error":"send requires to_agent and content"}'),
      ],
      isError: true,
    );
  }
  return switch (db.sendMessage(agentName, agentKey, toAgent, content)) {
    Success(:final value) => () {
      emitter.emit(eventMessageSent, {
        'message_id': value,
        'from_agent': agentName,
        'to_agent': toAgent,
        'content': content,
      });
      log.info('Message sent from $agentName to $toAgent');
      return (
        content: <Object>[textContent('{"sent":true,"message_id":"$value"}')],
        isError: false,
      );
    }(),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _get(
  TooManyCooksDb db,
  String agentName,
  String agentKey,
  bool unreadOnly,
) => switch (db.getMessages(agentName, agentKey, unreadOnly: unreadOnly)) {
  Success(:final value) => (
    content: <Object>[
      textContent('{"messages":[${value.map(messageToJson).join(',')}]}'),
    ],
    isError: false,
  ),
  Error(:final error) => _errorResult(error),
};

CallToolResult _markRead(
  TooManyCooksDb db,
  String agentName,
  String agentKey,
  String? messageId,
) {
  if (messageId == null) {
    return (
      content: <Object>[
        textContent('{"error":"mark_read requires message_id"}'),
      ],
      isError: true,
    );
  }
  return switch (db.markRead(messageId, agentName, agentKey)) {
    Success() => (
      content: <Object>[textContent('{"marked":true}')],
      isError: false,
    ),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _errorResult(DbError e) =>
    (content: <Object>[textContent(dbErrorToJson(e))], isError: true);
