/// MCP server setup for Too Many Cooks.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/config.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/tools/lock_tool.dart';
import 'package:too_many_cooks/src/tools/message_tool.dart';
import 'package:too_many_cooks/src/tools/plan_tool.dart';
import 'package:too_many_cooks/src/tools/register_tool.dart';
import 'package:too_many_cooks/src/tools/status_tool.dart';

/// Create the Too Many Cooks MCP server.
Result<McpServer, String> createTooManyCooksServer({
  TooManyCooksConfig config = defaultConfig,
}) {
  // Create database
  final dbResult = createDb(config);
  if (dbResult case Error(:final error)) return Error(error);
  final db = (dbResult as Success<TooManyCooksDb, String>).value;

  // Create MCP server
  final serverResult = McpServer.create(
    (name: 'too-many-cooks', version: '0.1.0'),
  );
  if (serverResult case Error(:final error)) return Error(error);

  // Register tools
  return Success(
    (serverResult as Success<McpServer, String>).value
      ..registerTool(
        'register',
        registerToolConfig,
        createRegisterHandler(db),
      )
      ..registerTool(
        'lock',
        lockToolConfig,
        createLockHandler(db, config),
      )
      ..registerTool(
        'message',
        messageToolConfig,
        createMessageHandler(db),
      )
      ..registerTool(
        'plan',
        planToolConfig,
        createPlanHandler(db),
      )
      ..registerTool(
        'status',
        statusToolConfig,
        createStatusHandler(db),
      ),
  );
}
