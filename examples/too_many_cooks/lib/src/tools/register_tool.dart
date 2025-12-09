/// Register tool - agent registration.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/db/db.dart';

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
ToolCallback createRegisterHandler(TooManyCooksDb db) =>
    (args, meta) async => switch (db.register(args['name']! as String)) {
          Success(:final value) => (
              content: <Object>[
                (
                  type: 'text',
                  text: '{"agent_name":"${value.agentName}",'
                      '"agent_key":"${value.agentKey}"}',
                ),
              ],
              isError: false,
            ),
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
