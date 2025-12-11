/// Register tool - agent registration.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/types.dart';

/// Input schema for register tool.
const registerInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'name': {'type': 'string', 'description': 'Unique agent name (1-50 chars)'},
  },
  'required': ['name'],
};

/// Tool config for register.
const registerToolConfig = (
  title: 'Register Agent',
  description:
      'Register a new agent. Returns secret key - store it! '
      'REQUIRED: name (string) - unique agent name 1-50 chars. '
      'Example: {"name": "my-agent"}',
  inputSchema: registerInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create register tool handler.
ToolCallback createRegisterHandler(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger logger,
) => (args, meta) async {
  final nameArg = args['name'];
  if (nameArg == null || nameArg is! String || nameArg.isEmpty) {
    return (
      content: <Object>[
        textContent('{"error":"missing_parameter: name is required"}'),
      ],
      isError: true,
    );
  }
  final name = nameArg;
  final log = logger.child({'tool': 'register', 'agentName': name});

  final result = db.register(name);

  return switch (result) {
    Success(:final value) => () {
      emitter.emit(eventAgentRegistered, {
        'agent_name': value.agentName,
        'registered_at': DateTime.now().millisecondsSinceEpoch,
      });
      log.info('Agent registered: ${value.agentName}');

      return (
        content: <Object>[
          textContent(
            '{"agent_name":"${value.agentName}",'
            '"agent_key":"${value.agentKey}"}',
          ),
        ],
        isError: false,
      );
    }(),
    Error(:final error) => () {
      log.warn('Registration failed: ${error.code}');
      return (
        content: <Object>[
          textContent('{"error":"${error.code}: ${error.message}"}'),
        ],
        isError: true,
      );
    }(),
  };
};
