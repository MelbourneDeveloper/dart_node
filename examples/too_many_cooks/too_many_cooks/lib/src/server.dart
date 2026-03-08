/// MCP server setup for Too Many Cooks.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/config.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/tools/lock_tool.dart';
import 'package:too_many_cooks/src/tools/message_tool.dart';
import 'package:too_many_cooks/src/tools/plan_tool.dart';
import 'package:too_many_cooks/src/tools/register_tool.dart';
import 'package:too_many_cooks/src/tools/status_tool.dart';
import 'package:too_many_cooks/src/types.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart'
    show TooManyCooksDb, createDb;

/// Result of creating the server — includes both MCP server and DB
/// so the HTTP layer can wire up admin routes.
typedef ServerBundle = ({McpServer server, TooManyCooksDb db});

/// Create the Too Many Cooks MCP server with its own DB.
///
/// This creates both the database and a single MCP server
/// instance with per-connection session state. Suitable for
/// Streamable HTTP where there's one connection.
Result<ServerBundle, String> createTooManyCooksServer({
  TooManyCooksConfig? config,
  Logger? logger,
}) {
  final cfg = config ?? defaultConfig;
  final log = logger ?? _createConsoleLogger()
    ..info('Creating Too Many Cooks server');

  final dbResult = createDb(cfg);
  if (dbResult case Error(:final error)) {
    log.error(
      'Failed to create database',
      structuredData: {'error': error},
    );
    return Error(error);
  }
  final db =
      (dbResult as Success<TooManyCooksDb, String>).value;
  log.debug('Database created successfully');

  final serverResult = createMcpServerForDb(db, cfg, log);
  if (serverResult case Error(:final error)) {
    return Error(error);
  }
  final server =
      (serverResult as Success<McpServer, String>).value;

  return Success((server: server, db: db));
}

/// Create an MCP server instance wired to a shared DB.
///
/// Each call creates a fresh MCP server with its own
/// per-connection session state. The DB is shared.
/// Use this for Streamable HTTP where each session needs
/// its own MCP server instance.
Result<McpServer, String> createMcpServerForDb(
  TooManyCooksDb db,
  TooManyCooksConfig config,
  Logger log, {
  AdminPushFn? adminPush,
}) {
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
    log.error(
      'Failed to create MCP server',
      structuredData: {'error': error},
    );
    return Error(error);
  }
  final server =
      (serverResult as Success<McpServer, String>).value;
  log.debug('MCP server created');

  // Create notification emitter — also pushes to admin hub
  final emitter = createNotificationEmitter(
    server,
    adminPush: adminPush,
  );

  // Per-connection session state
  SessionIdentity? session;
  SessionIdentity? getSession() => session;
  void setSession(String name, String key) {
    session = (agentName: name, agentKey: key);
    log.info('Session established for agent: $name');
  }

  // Register tools
  server
    ..registerTool(
      'register',
      registerToolConfig,
      createRegisterHandler(db, emitter, log, setSession),
    )
    ..registerTool(
      'lock',
      lockToolConfig,
      createLockHandler(
        db,
        config,
        emitter,
        log,
        getSession,
      ),
    )
    ..registerTool(
      'message',
      messageToolConfig,
      createMessageHandler(db, emitter, log, getSession),
    )
    ..registerTool(
      'plan',
      planToolConfig,
      createPlanHandler(db, emitter, log, getSession),
    )
    ..registerTool(
      'status',
      statusToolConfig,
      createStatusHandler(db, log),
    );

  log.info('Server initialized with all tools registered');

  return Success(server);
}

/// Creates a logger that writes to console.error.
Logger _createConsoleLogger() => createLoggerWithContext(
  createLoggingContext(
    transports: [logTransport(_logToConsole)],
    minimumLogLevel: LogLevel.debug,
  ),
);

/// Log transport that writes to console.error.
void _logToConsole(
  LogMessage message,
  LogLevel minimumLogLevel,
) {
  if (message.logLevel.index < minimumLogLevel.index) {
    return;
  }
  final level = message.logLevel.name.toUpperCase();
  final data = message.structuredData;
  final dataStr =
      data != null && data.isNotEmpty ? ' $data' : '';
  consoleError(
    '[TMC] [$level] ${message.message}$dataStr',
  );
}
