/// Register tool - agent registration.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/types.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

/// Input schema for register tool.
const registerInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'name': {
      'type': 'string',
      'description':
          'MANDATORY. Your unique agent name, 1-50 chars. '
          'This is the only valid field.',
    },
  },
  'required': ['name'],
  'additionalProperties': false,
};

/// Tool config for register.
const registerToolConfig = (
  title: 'Register Agent',
  description:
      'Register a new agent. Returns secret key - store it! '
      'The ONLY parameter is "name" (string, MANDATORY) - your unique agent '
      'name 1-50 chars. Do NOT pass any other fields. '
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
        content: <Object>[textContent(agentRegistrationToJson(value))],
        isError: false,
      );
    }(),
    Error(:final error) => () {
      log.warn('Registration failed: ${error.code}');
      return (
        content: <Object>[textContent(dbErrorToJson(error))],
        isError: true,
      );
    }(),
  };
};
