/// Plan tool - agent plan management.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/types.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

/// Input schema for plan tool.
const planInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'action': {
      'type': 'string',
      'enum': ['update', 'get', 'list'],
      'description': 'Plan action to perform',
    },
    'goal': {
      'type': 'string',
      'maxLength': 100,
      'description': 'Your goal (for update). MUST be 100 chars or less.',
    },
    'current_task': {
      'type': 'string',
      'maxLength': 100,
      'description':
          'What you are doing now (for update). '
          'MUST be 100 chars or less.',
    },
  },
  'required': ['action'],
};

/// Tool config for plan.
const planToolConfig = (
  title: 'Plan',
  description:
      'Manage your plan. You must register first (except list). '
      'REQUIRED: action (update|get|list). '
      'For update: goal, current_task. '
      'Example: {"action":"update","goal":"Fix bug",'
      ' "current_task":"Reading code"}',
  inputSchema: planInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create plan tool handler.
ToolCallback createPlanHandler(
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
  final log = logger.child({'tool': 'plan', 'action': action});

  // list doesn't need auth
  if (action == 'list') return _list(db);

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

  return switch (action) {
    'update' => _update(
      db,
      emitter,
      log,
      agentName,
      agentKey,
      args['goal'] as String?,
      args['current_task'] as String?,
    ),
    'get' => _get(db, agentName),
    _ => (
      content: <Object>[textContent('{"error":"Unknown action: $action"}')],
      isError: true,
    ),
  };
};

CallToolResult _update(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger log,
  String agentName,
  String agentKey,
  String? goal,
  String? currentTask,
) {
  if (goal == null || currentTask == null) {
    return (
      content: <Object>[
        textContent('{"error":"update requires goal, current_task"}'),
      ],
      isError: true,
    );
  }
  return switch (db.updatePlan(agentName, agentKey, goal, currentTask)) {
    Success() => () {
      emitter.emit(eventPlanUpdated, {
        'agent_name': agentName,
        'goal': goal,
        'current_task': currentTask,
      });
      log.info('Plan updated for $agentName: $currentTask');
      return (
        content: <Object>[textContent('{"updated":true}')],
        isError: false,
      );
    }(),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _get(TooManyCooksDb db, String agentName) =>
    switch (db.getPlan(agentName)) {
      Success(:final value) when value == null => (
        content: <Object>[textContent('{"plan":null}')],
        isError: false,
      ),
      Success(:final value) => (
        content: <Object>[textContent('{"plan":${agentPlanToJson(value!)}}')],
        isError: false,
      ),
      Error(:final error) => _errorResult(error),
    };

CallToolResult _list(TooManyCooksDb db) => switch (db.listPlans()) {
  Success(:final value) => (
    content: <Object>[
      textContent('{"plans":[${value.map(agentPlanToJson).join(',')}]}'),
    ],
    isError: false,
  ),
  Error(:final error) => _errorResult(error),
};

CallToolResult _errorResult(DbError e) =>
    (content: <Object>[textContent(dbErrorToJson(e))], isError: true);
