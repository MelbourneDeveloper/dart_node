/// Status tool - system overview.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/types.dart';

/// Input schema for status tool (no inputs required).
const statusInputSchema = <String, Object?>{
  'type': 'object',
  'properties': <String, Object?>{},
};

/// Tool config for status.
const statusToolConfig = (
  title: 'Status',
  description: 'Get system overview: agents, locks, plans, messages',
  inputSchema: statusInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create status tool handler.
ToolCallback createStatusHandler(TooManyCooksDb db, Logger logger) =>
    (args, meta) async {
      final log = logger.child({'tool': 'status'});

      // Get agents
      final agentsResult = db.listAgents();
      if (agentsResult case Error(:final error)) {
        return _errorResult(error);
      }
      final agents = (agentsResult as Success<List<AgentIdentity>, DbError>)
          .value
          .map(_agentJson)
          .join(',');

      // Get locks
      final locksResult = db.listLocks();
      if (locksResult case Error(:final error)) {
        return _errorResult(error);
      }
      final locks = (locksResult as Success<List<FileLock>, DbError>)
          .value
          .map(_lockJson)
          .join(',');

      // Get plans
      final plansResult = db.listPlans();
      if (plansResult case Error(:final error)) {
        return _errorResult(error);
      }
      final plans = (plansResult as Success<List<AgentPlan>, DbError>)
          .value
          .map(_planJson)
          .join(',');

      // Get messages
      final messagesResult = db.listAllMessages();
      if (messagesResult case Error(:final error)) {
        return _errorResult(error);
      }
      final messages = (messagesResult as Success<List<Message>, DbError>)
          .value
          .map(_messageJson)
          .join(',');

      log.debug('Status queried');

      return (
        content: <Object>[
          textContent(
            '{"agents":[$agents],"locks":[$locks],'
            '"plans":[$plans],"messages":[$messages]}',
          ),
        ],
        isError: false,
      );
    };

String _agentJson(AgentIdentity a) => '{"agent_name":"${a.agentName}",'
    '"registered_at":${a.registeredAt},'
    '"last_active":${a.lastActive}}';

String _lockJson(FileLock l) => '{"file_path":"${l.filePath}",'
    '"agent_name":"${l.agentName}",'
    '"acquired_at":${l.acquiredAt},'
    '"expires_at":${l.expiresAt}'
    '${l.reason != null ? ',"reason":"${_escapeJson(l.reason!)}"' : ''}}';

String _planJson(AgentPlan p) => '{"agent_name":"${p.agentName}",'
    '"goal":"${_escapeJson(p.goal)}",'
    '"current_task":"${_escapeJson(p.currentTask)}",'
    '"updated_at":${p.updatedAt}}';

String _messageJson(Message m) => '{"id":"${m.id}",'
    '"from_agent":"${m.fromAgent}",'
    '"to_agent":"${m.toAgent}",'
    '"content":"${_escapeJson(m.content)}",'
    '"created_at":${m.createdAt}'
    '${m.readAt != null ? ',"read_at":${m.readAt}' : ''}}';

String _escapeJson(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');

CallToolResult _errorResult(DbError e) => (
      content: <Object>[
        textContent('{"error":"${e.code}: ${e.message}"}'),
      ],
      isError: true,
    );
