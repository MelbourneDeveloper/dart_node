/// Status tool - system overview.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/types.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

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
          .map(agentIdentityToJson)
          .join(',');

      // Get locks
      final locksResult = db.listLocks();
      if (locksResult case Error(:final error)) {
        return _errorResult(error);
      }
      final locks = (locksResult as Success<List<FileLock>, DbError>).value
          .map(fileLockToJson)
          .join(',');

      // Get plans
      final plansResult = db.listPlans();
      if (plansResult case Error(:final error)) {
        return _errorResult(error);
      }
      final plans = (plansResult as Success<List<AgentPlan>, DbError>).value
          .map(agentPlanToJson)
          .join(',');

      // Get messages
      final messagesResult = db.listAllMessages();
      if (messagesResult case Error(:final error)) {
        return _errorResult(error);
      }
      final messages = (messagesResult as Success<List<Message>, DbError>).value
          .map(messageToJson)
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

CallToolResult _errorResult(DbError e) =>
    (content: <Object>[textContent(dbErrorToJson(e))], isError: true);
