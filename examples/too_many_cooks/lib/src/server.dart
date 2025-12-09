/// MCP server setup for Too Many Cooks.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/config.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/tools/lock_tool.dart';
import 'package:too_many_cooks/src/tools/message_tool.dart';
import 'package:too_many_cooks/src/tools/plan_tool.dart';
import 'package:too_many_cooks/src/tools/register_tool.dart';
import 'package:too_many_cooks/src/tools/status_tool.dart';
import 'package:too_many_cooks/src/tools/subscribe_tool.dart';

/// Create the Too Many Cooks MCP server.
Result<McpServer, String> createTooManyCooksServer({
  TooManyCooksConfig config = defaultConfig,
}) {
  // Create database
  final dbResult = createDb(config);
  if (dbResult case Error(:final error)) return Error(error);
  final db = (dbResult as Success<TooManyCooksDb, String>).value;

  // Create MCP server with logging capability enabled
  final serverResult = McpServer.create(
    (name: 'too-many-cooks', version: '0.1.0'),
    options: (
      capabilities: (
        tools: (listChanged: true),
        resources: null,
        prompts: null,
        logging: (enabled: true),
      ),
      instructions: null,
    ),
  );
  if (serverResult case Error(:final error)) return Error(error);
  final server = (serverResult as Success<McpServer, String>).value;

  // Create notification emitter
  final emitter = createNotificationEmitter(server);

  // Register tools
  server
    ..registerTool(
      'register',
      registerToolConfig,
      createRegisterHandler(db, emitter),
    )
    ..registerTool(
      'lock',
      lockToolConfig,
      createLockHandler(db, config, emitter),
    )
    ..registerTool(
      'message',
      messageToolConfig,
      createMessageHandler(db, emitter),
    )
    ..registerTool(
      'plan',
      planToolConfig,
      createPlanHandler(db, emitter),
    )
    ..registerTool(
      'status',
      statusToolConfig,
      createStatusHandler(db),
    )
    ..registerTool(
      'subscribe',
      subscribeToolConfig,
      createSubscribeHandler(emitter),
    );

  return Success(server);
}
