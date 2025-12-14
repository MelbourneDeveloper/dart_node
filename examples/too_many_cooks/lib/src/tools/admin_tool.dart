/// Admin tool - administrative operations for VSCode extension.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/types.dart';

/// Input schema for admin tool.
const adminInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'action': {
      'type': 'string',
      'enum': ['delete_lock', 'delete_agent', 'reset_key'],
      'description': 'Admin action to perform',
    },
    'file_path': {
      'type': 'string',
      'description': 'File path (for delete_lock)',
    },
    'agent_name': {
      'type': 'string',
      'description': 'Agent name (for delete_agent)',
    },
  },
  'required': ['action'],
};

/// Tool config for admin.
const adminToolConfig = (
  title: 'Admin Operations',
  description:
      'Admin operations for VSCode extension. REQUIRED: action. '
      'For delete_lock: file_path. For delete_agent: agent_name. '
      'For reset_key: agent_name (returns new key for existing agent). '
      'Example: {"action":"delete_lock","file_path":"/path/file.dart"}',
  inputSchema: adminInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create admin tool handler.
ToolCallback createAdminHandler(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger logger,
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
  final filePath = args['file_path'] as String?;
  final agentName = args['agent_name'] as String?;
  final log = logger.child({'tool': 'admin', 'action': action});

  return switch (action) {
    'delete_lock' => _deleteLock(db, emitter, log, filePath),
    'delete_agent' => _deleteAgent(db, emitter, log, agentName),
    'reset_key' => _resetKey(db, log, agentName),
    _ => (
      content: <Object>[textContent('{"error":"Unknown action: $action"}')],
      isError: true,
    ),
  };
};

CallToolResult _deleteLock(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger log,
  String? filePath,
) {
  if (filePath == null) {
    return (
      content: <Object>[
        textContent('{"error":"delete_lock requires file_path"}'),
      ],
      isError: true,
    );
  }

  return switch (db.adminDeleteLock(filePath)) {
    Success() => () {
      emitter.emit(eventLockReleased, {
        'file_path': filePath,
        'agent_name': 'admin',
        'admin': true,
      });
      log.warn('Admin deleted lock on $filePath');
      return (
        content: <Object>[textContent('{"deleted":true}')],
        isError: false,
      );
    }(),
    Error(:final error) => (
      content: <Object>[
        textContent('{"error":"${error.code}: ${error.message}"}'),
      ],
      isError: true,
    ),
  };
}

CallToolResult _deleteAgent(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger log,
  String? agentName,
) {
  if (agentName == null) {
    return (
      content: <Object>[
        textContent('{"error":"delete_agent requires agent_name"}'),
      ],
      isError: true,
    );
  }

  return switch (db.adminDeleteAgent(agentName)) {
    Success() => () {
      log.warn('Admin deleted agent $agentName');
      return (
        content: <Object>[textContent('{"deleted":true}')],
        isError: false,
      );
    }(),
    Error(:final error) => (
      content: <Object>[
        textContent('{"error":"${error.code}: ${error.message}"}'),
      ],
      isError: true,
    ),
  };
}

CallToolResult _resetKey(TooManyCooksDb db, Logger log, String? agentName) {
  if (agentName == null) {
    return (
      content: <Object>[
        textContent('{"error":"reset_key requires agent_name"}'),
      ],
      isError: true,
    );
  }

  return switch (db.adminResetKey(agentName)) {
    Success(:final value) => () {
      log.warn('Admin reset key for agent $agentName');
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
    Error(:final error) => (
      content: <Object>[
        textContent('{"error":"${error.code}: ${error.message}"}'),
      ],
      isError: true,
    ),
  };
}
