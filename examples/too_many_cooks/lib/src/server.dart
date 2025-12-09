/// MCP server setup for Too Many Cooks.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';

import 'config.dart';
import 'db/db.dart';
import 'tools/lock_tool.dart';
import 'tools/message_tool.dart';
import 'tools/plan_tool.dart';
import 'tools/register_tool.dart';
import 'tools/status_tool.dart';

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
  final server = (serverResult as Success<McpServer, String>).value;

  // Register tools
  server.registerTool('register', registerToolConfig, createRegisterHandler(db));
  server.registerTool('lock', lockToolConfig, createLockHandler(db, config));
  server.registerTool('message', messageToolConfig, createMessageHandler(db));
  server.registerTool('plan', planToolConfig, createPlanHandler(db));
  server.registerTool('status', statusToolConfig, createStatusHandler(db));

  return Success(server);
}
