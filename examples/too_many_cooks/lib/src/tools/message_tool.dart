/// Message tool - inter-agent messaging.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/types.dart';

/// Input schema for message tool.
const messageInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'action': {
      'type': 'string',
      'enum': ['send', 'get', 'mark_read'],
      'description': 'Message action to perform',
    },
    'agent_name': {
      'type': 'string',
      'description': 'Your agent name',
    },
    'agent_key': {
      'type': 'string',
      'description': 'Your secret key',
    },
    'to_agent': {
      'type': 'string',
      'description': 'Recipient name or * for broadcast (for send)',
    },
    'content': {
      'type': 'string',
      'description': 'Message content, max 200 chars (for send)',
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
  'required': ['action', 'agent_name', 'agent_key'],
};

/// Tool config for message.
const messageToolConfig = (
  title: 'Message',
  description: 'Send/receive messages: send, get, mark_read',
  inputSchema: messageInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create message tool handler.
ToolCallback createMessageHandler(
  TooManyCooksDb db,
  NotificationEmitter emitter,
) =>
    (args, meta) async {
      final action = args['action']! as String;
      final agentName = args['agent_name']! as String;
      final agentKey = args['agent_key']! as String;

      return switch (action) {
        'send' => _send(
            db,
            emitter,
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
            content: <Object>[
              (type: 'text', text: '{"error":"Unknown action: $action"}'),
            ],
            isError: true,
          ),
      };
    };

CallToolResult _send(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  String agentName,
  String agentKey,
  String? toAgent,
  String? content,
) {
  if (toAgent == null || content == null) {
    return (
      content: <Object>[
        (type: 'text', text: '{"error":"send requires to_agent and content"}'),
      ],
      isError: true,
    );
  }
  return switch (db.sendMessage(agentName, agentKey, toAgent, content)) {
    Success(:final value) => () {
        // Emit notification
        emitter.emit(eventMessageSent, {
          'message_id': value,
          'from_agent': agentName,
          'to_agent': toAgent,
          'content': content,
        });
        return (
          content: <Object>[
            (type: 'text', text: '{"sent":true,"message_id":"$value"}'),
          ],
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
) =>
    switch (db.getMessages(agentName, agentKey, unreadOnly: unreadOnly)) {
      Success(:final value) => (
          content: <Object>[
            (
              type: 'text',
              text: '{"messages":[${value.map(_messageJson).join(',')}]}',
            ),
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
        (type: 'text', text: '{"error":"mark_read requires message_id"}'),
      ],
      isError: true,
    );
  }
  return switch (db.markRead(messageId, agentName, agentKey)) {
    Success() => (
        content: <Object>[(type: 'text', text: '{"marked":true}')],
        isError: false,
      ),
    Error(:final error) => _errorResult(error),
  };
}

String _messageJson(Message m) => '{"id":"${m.id}",'
    '"from_agent":"${m.fromAgent}",'
    '"content":"${_escapeJson(m.content)}",'
    '"created_at":${m.createdAt}'
    '${m.readAt != null ? ',"read_at":${m.readAt}' : ''}}';

String _escapeJson(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');

CallToolResult _errorResult(DbError e) => (
      content: <Object>[
        (type: 'text', text: '{"error":"${e.code}: ${e.message}"}'),
      ],
      isError: true,
    );
