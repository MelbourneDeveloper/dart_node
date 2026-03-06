/// Register tool - agent registration and reconnection.
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
          'Your unique agent name, 1-50 chars. '
          'For FIRST registration only. Do NOT send with key.',
    },
    'key': {
      'type': 'string',
      'description':
          'Your secret key from a previous registration. '
          'For RECONNECT only. Do NOT send with name.',
    },
  },
};

/// Tool config for register.
const registerToolConfig = (
  title: 'Register Agent',
  description:
      'Register a new agent or reconnect with an existing key. '
      'FIRST TIME: pass "name" only. Returns key — store it! '
      'RECONNECT: pass "key" only. Server looks up your name. '
      'Passing both name and key is an error. '
      'Example first: {"name": "my-agent"} '
      'Example reconnect: {"key": "abc123..."}',
  inputSchema: registerInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create register tool handler.
ToolCallback createRegisterHandler(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger logger,
  SessionSetter setSession,
) => (args, meta) async {
  final nameArg = args['name'] as String?;
  final keyArg = args['key'] as String?;
  final hasName = nameArg != null && nameArg.isNotEmpty;
  final hasKey = keyArg != null && keyArg.isNotEmpty;

  // Both = error, neither = error
  if (hasName && hasKey) {
    return (
      content: <Object>[
        textContent(
          '{"error":"validation: pass name OR key, not both"}',
        ),
      ],
      isError: true,
    );
  }
  if (!hasName && !hasKey) {
    return (
      content: <Object>[
        textContent(
          '{"error":"missing_parameter: name or key required"}',
        ),
      ],
      isError: true,
    );
  }

  // Reconnect path: key only
  if (hasKey) {
    final log = logger.child({'tool': 'register', 'mode': 'reconnect'});
    return switch (db.lookupByKey(keyArg)) {
      Success(:final value) => () {
        setSession(value, keyArg);
        db.activate(value);
        emitter.emit(eventAgentActivated, {'agent_name': value});
        log.info('Agent reconnected: $value');
        return (
          content: <Object>[
            textContent(
              '{"agent_name":"$value","agent_key":"$keyArg"}',
            ),
          ],
          isError: false,
        );
      }(),
      Error(:final error) => () {
        log.warn('Reconnect failed: ${error.code}');
        return (
          content: <Object>[textContent(dbErrorToJson(error))],
          isError: true,
        );
      }(),
    };
  }

  // First registration: name only
  final name = nameArg!;
  final log = logger.child({
    'tool': 'register',
    'agentName': name,
  });
  return switch (db.register(name)) {
    Success(:final value) => () {
      setSession(value.agentName, value.agentKey);
      db.activate(value.agentName);
      emitter.emit(eventAgentRegistered, {
        'agent_name': value.agentName,
        'registered_at': DateTime.now().millisecondsSinceEpoch,
      });
      log.info('Agent registered: ${value.agentName}');
      return (
        content: <Object>[
          textContent(agentRegistrationToJson(value)),
        ],
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
