/// Plan tool - agent plan management.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/types.dart';

/// Input schema for plan tool.
const planInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'action': {
      'type': 'string',
      'enum': ['update', 'get', 'list'],
      'description': 'Plan action to perform',
    },
    'agent_name': {
      'type': 'string',
      'description': 'Agent name (required for update, optional for get)',
    },
    'agent_key': {
      'type': 'string',
      'description': 'Your secret key (required for update)',
    },
    'goal': {
      'type': 'string',
      'description': 'Your goal, max 100 chars (for update)',
    },
    'current_task': {
      'type': 'string',
      'description': 'What you are doing now, max 100 chars (for update)',
    },
  },
  'required': ['action'],
};

/// Tool config for plan.
const planToolConfig = (
  title: 'Plan',
  description: 'Manage agent plans: update, get, list. REQUIRED: action. '
      'For update: agent_name, agent_key, goal, current_task. '
      'For get: agent_name. Example update: {"action":"update",'
      ' "agent_name":"me","agent_key":"xxx","goal":"Fix bug",'
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
) =>
    (args, meta) async {
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

      return switch (action) {
        'update' => _update(
            db,
            emitter,
            log,
            args['agent_name'] as String?,
            args['agent_key'] as String?,
            args['goal'] as String?,
            args['current_task'] as String?,
          ),
        'get' => _get(db, args['agent_name'] as String?),
        'list' => _list(db),
        _ => (
            content: <Object>[
              textContent('{"error":"Unknown action: $action"}'),
            ],
            isError: true,
          ),
      };
    };

CallToolResult _update(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger log,
  String? agentName,
  String? agentKey,
  String? goal,
  String? currentTask,
) {
  if (agentName == null ||
      agentKey == null ||
      goal == null ||
      currentTask == null) {
    return (
      content: <Object>[
        textContent(
          '{"error":"update requires '
          'agent_name, agent_key, goal, current_task"}',
        ),
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

CallToolResult _get(TooManyCooksDb db, String? agentName) {
  if (agentName == null) {
    return (
      content: <Object>[
        textContent( '{"error":"get requires agent_name"}'),
      ],
      isError: true,
    );
  }
  return switch (db.getPlan(agentName)) {
    Success(:final value) when value == null => (
        content: <Object>[textContent( '{"plan":null}')],
        isError: false,
      ),
    Success(:final value) => (
        content: <Object>[
          textContent( '{"plan":${_planJson(value!)}}'),
        ],
        isError: false,
      ),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _list(TooManyCooksDb db) => switch (db.listPlans()) {
      Success(:final value) => (
          content: <Object>[
            textContent('{"plans":[${value.map(_planJson).join(',')}]}'),
          ],
          isError: false,
        ),
      Error(:final error) => _errorResult(error),
    };

String _planJson(AgentPlan p) => '{"agent_name":"${p.agentName}",'
    '"goal":"${_escapeJson(p.goal)}",'
    '"current_task":"${_escapeJson(p.currentTask)}",'
    '"updated_at":${p.updatedAt}}';

String _escapeJson(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');

CallToolResult _errorResult(DbError e) => (
      content: <Object>[
        textContent( '{"error":"${e.code}: ${e.message}"}'),
      ],
      isError: true,
    );
