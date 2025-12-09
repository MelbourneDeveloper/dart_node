/// Status tool - system overview.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';

import '../db/db.dart';
import '../types.dart';

/// Input schema for status tool (no inputs required).
const statusInputSchema = <String, Object?>{
  'type': 'object',
  'properties': <String, Object?>{},
};

/// Tool config for status.
const statusToolConfig = (
  title: 'Status',
  description: 'Get system overview: agents, locks, plans',
  inputSchema: statusInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create status tool handler.
ToolCallback createStatusHandler(TooManyCooksDb db) => (args, meta) async {
      final agentsResult = db.listAgents();
      final locksResult = db.listLocks();
      final plansResult = db.listPlans();

      if (agentsResult case Error(:final error)) return _errorResult(error);
      if (locksResult case Error(:final error)) return _errorResult(error);
      if (plansResult case Error(:final error)) return _errorResult(error);

      final agents = (agentsResult as Success).value as List<AgentIdentity>;
      final locks = (locksResult as Success).value as List<FileLock>;
      final plans = (plansResult as Success).value as List<AgentPlan>;

      final agentsJson = agents
          .map(
            (a) => '{"name":"${a.agentName}","last_active":${a.lastActive}}',
          )
          .join(',');

      final locksJson = locks
          .map(
            (l) => '{"file_path":"${l.filePath}",'
                '"agent_name":"${l.agentName}",'
                '"expires_at":${l.expiresAt}'
                '${l.reason != null ? ',"reason":"${l.reason}"' : ''}}',
          )
          .join(',');

      final plansJson = plans
          .map(
            (p) => '{"agent_name":"${p.agentName}",'
                '"goal":"${_escapeJson(p.goal)}",'
                '"current_task":"${_escapeJson(p.currentTask)}"}',
          )
          .join(',');

      return (
        content: <Object>[
          (
            type: 'text',
            text: '{"agents":[$agentsJson],'
                '"locks":[$locksJson],'
                '"plans":[$plansJson]}',
          ),
        ],
        isError: false,
      );
    };

String _escapeJson(String s) =>
    s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n');

CallToolResult _errorResult(DbError e) => (
      content: <Object>[
        (type: 'text', text: '{"error":"${e.code}: ${e.message}"}'),
      ],
      isError: true,
    );
