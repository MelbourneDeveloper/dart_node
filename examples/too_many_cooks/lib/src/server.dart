/// MCP server setup for Too Many Cooks.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/config.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/tools/admin_tool.dart';
import 'package:too_many_cooks/src/tools/lock_tool.dart';
import 'package:too_many_cooks/src/tools/message_tool.dart';
import 'package:too_many_cooks/src/tools/plan_tool.dart';
import 'package:too_many_cooks/src/tools/register_tool.dart';
import 'package:too_many_cooks/src/tools/status_tool.dart';
import 'package:too_many_cooks/src/tools/subscribe_tool.dart';

/// Create the Too Many Cooks MCP server.
Result<McpServer, String> createTooManyCooksServer({
  TooManyCooksConfig? config,
  Logger? logger,
}) {
  final cfg = config ?? defaultConfig;
  final log = logger ?? _createNoOpLogger()
    ..info('Creating Too Many Cooks server');

  // Create database
  final dbResult = createDb(cfg);
  if (dbResult case Error(:final error)) {
    log.error('Failed to create database', structuredData: {'error': error});
    return Error(error);
  }
  final db = (dbResult as Success<TooManyCooksDb, String>).value;
  log.debug('Database created successfully');

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
  if (serverResult case Error(:final error)) {
    log.error('Failed to create MCP server', structuredData: {'error': error});
    return Error(error);
  }
  final server = (serverResult as Success<McpServer, String>).value;
  log.debug('MCP server created');

  // Create notification emitter
  final emitter = createNotificationEmitter(server);

  // Register tools
  server
    ..registerTool(
      'register',
      registerToolConfig,
      createRegisterHandler(db, emitter, log),
    )
    ..registerTool(
      'lock',
      lockToolConfig,
      createLockHandler(db, cfg, emitter, log),
    )
    ..registerTool(
      'message',
      messageToolConfig,
      createMessageHandler(db, emitter, log),
    )
    ..registerTool('plan', planToolConfig, createPlanHandler(db, emitter, log))
    ..registerTool('status', statusToolConfig, createStatusHandler(db, log))
    ..registerTool(
      'subscribe',
      subscribeToolConfig,
      createSubscribeHandler(emitter),
    )
    ..registerTool(
      'admin',
      adminToolConfig,
      createAdminHandler(db, emitter, log),
    );

  log.info('Server initialized with all tools registered');

  return Success(server);
}

/// Creates a no-op logger that supports child() for when no logger is provided
Logger _createNoOpLogger() => createLoggerWithContext(createLoggingContext());
