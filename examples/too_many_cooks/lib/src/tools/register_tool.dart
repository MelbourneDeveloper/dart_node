/// Register tool - agent registration.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/notifications.dart';

/// Input schema for register tool.
const registerInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'name': {
      'type': 'string',
      'description': 'Unique agent name (1-50 chars)',
    },
  },
  'required': ['name'],
};

/// Tool config for register.
const registerToolConfig = (
  title: 'Register Agent',
  description: 'Register a new agent. Returns secret key - store it!',
  inputSchema: registerInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create register tool handler.
ToolCallback createRegisterHandler(
  TooManyCooksDb db,
  NotificationEmitter emitter,
) =>
    (args, meta) async {
      final name = args['name']! as String;
      final result = db.register(name);

      return switch (result) {
        Success(:final value) => () {
            // Emit notification
            emitter.emit(eventAgentRegistered, {
              'agent_name': value.agentName,
              'registered_at': DateTime.now().millisecondsSinceEpoch,
            });

            return (
              content: <Object>[
                (
                  type: 'text',
                  text: '{"agent_name":"${value.agentName}",'
                      '"agent_key":"${value.agentKey}"}',
                ),
              ],
              isError: false,
            );
          }(),
        Error(:final error) => (
            content: <Object>[
              (
                type: 'text',
                text: '{"error":"${error.code}: ${error.message}"}',
              ),
            ],
            isError: true,
          ),
      };
    };
