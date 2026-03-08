/// Entry point for Too Many Cooks MCP server.
///
/// Starts a single Express HTTP server on port 4040 with:
/// - `/mcp` — MCP Streamable HTTP for agent connections
/// - `/admin/*` — REST + Streamable HTTP for the VSCode
///   extension
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_express/dart_node_express.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/too_many_cooks.dart';

@JS('setInterval')
external void _setInterval(
  JSFunction callback,
  int delay,
);

@JS('globalThis.crypto.randomUUID')
external String _jsRandomUUID();

String _randomUUID() => _jsRandomUUID();

// JSON-RPC bad request error response.
// ignore: lines_longer_than_80_chars
const _badRequestJson = '{"jsonrpc":"2.0","error":{"code":-32000,"message":"Bad Request"},"id":null}';

Future<void> main() async {
  final log = _createLogger()
    ..info('Server starting...');
  try {
    await _startServer(log);
  } catch (e, st) {
    log.fatal(
      'Fatal error',
      structuredData: {'error': '$e', 'stackTrace': '$st'},
    );
    rethrow;
  }
}

Future<void> _startServer(Logger log) async {
  log.info('Creating server...');

  final cfg = defaultConfig;

  // Create shared database
  final dbResult = createDb(cfg);
  final db = switch (dbResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };
  log.info('Database created.');

  // Session tracking for MCP Streamable HTTP
  final transports =
      <String, StreamableHttpTransport>{};

  // Admin event hub for Streamable HTTP push
  final adminHub = createAdminEventHub();

  // Create Express app
  final app = express();

  // Admin REST endpoints (VSIX)
  registerAdminRoutes(app, db, adminHub);

  // Admin Streamable HTTP routes (/admin/events)
  final adminPostFn =
      _adminPostHandler(adminHub, log);
  final adminGetDeleteFn =
      _adminGetDeleteHandler(adminHub);
  app
    ..post(
      '/admin/events',
      _asyncHandler(adminPostFn, log),
    )
    ..get(
      '/admin/events',
      _asyncHandler(adminGetDeleteFn, log),
    )
    ..delete(
      '/admin/events',
      _asyncHandler(adminGetDeleteFn, log),
    );

  // MCP Streamable HTTP routes
  final postFn =
      _mcpPostHandler(transports, db, cfg, log, adminHub);
  final getDeleteFn =
      _mcpGetDeleteHandler(transports);
  app
    ..post('/mcp', _asyncHandler(postFn, log))
    ..get('/mcp', _asyncHandler(getDeleteFn, log))
    ..delete('/mcp', _asyncHandler(getDeleteFn, log));

  // Start listening
  const port = 4040;
  app.listen(
    port,
    (() {
      log.info(
        'Server listening',
        structuredData: {'port': port},
      );
    }).toJS,
  );

  // Keep event loop alive
  _setInterval((() {}).toJS, 60000);
  await Completer<void>().future;
}

/// Check if a parsed JSON body is an MCP initialize
/// request.
bool _isInitializeRequest(JSAny? body) {
  if (body == null || body.isUndefinedOrNull) {
    return false;
  }
  try {
    final obj = body as JSObject;
    final method = obj['method'];
    if (method == null || method.isUndefinedOrNull) {
      return false;
    }
    return (method as JSString).toDart == 'initialize';
  } on Object {
    return false;
  }
}

/// Get a request header value.
String? _getHeader(Request req, String name) {
  final headers =
      (req as JSObject)['headers'] as JSObject?;
  if (headers == null) return null;
  final value = headers[name];
  if (value == null || value.isUndefinedOrNull) {
    return null;
  }
  return (value as JSString).toDart;
}

/// POST /mcp handler — session init or existing session.
Future<void> Function(Request, Response)
    _mcpPostHandler(
  Map<String, StreamableHttpTransport> transports,
  TooManyCooksDb db,
  TooManyCooksConfig cfg,
  Logger log,
  AdminEventHub adminHub,
) => (req, res) async {
  final sessionId =
      _getHeader(req, 'mcp-session-id');
  final body = req.body;

  if (sessionId != null &&
      transports.containsKey(sessionId)) {
    await transports[sessionId]
        ?.handleRequest(
          req as JSObject,
          res as JSObject,
          body,
        )
        .toDart;
    return;
  }

  if (sessionId == null &&
      _isInitializeRequest(body)) {
    late final StreamableHttpTransport transport;
    final transportResult =
        createStreamableHttpTransport(
          sessionIdGenerator: _randomUUID,
          onSessionInitialized: (sid) {
            log.info(
              'Session init',
              structuredData: {'sessionId': sid},
            );
            transports[sid] = transport;
          },
        );
    transport = switch (transportResult) {
      Success(:final value) => value,
      Error(:final error) => throw Exception(error),
    };

    (transport as JSObject)['onclose'] = (() {
      final sid = transport.sessionId;
      if (sid != null) {
        log.info(
          'Session closed',
          structuredData: {'sessionId': sid},
        );
        transports.remove(sid);
      }
    }).toJS;

    final serverResult = createMcpServerForDb(
      db, cfg, log,
      adminPush: adminHub.pushEvent,
    );
    final server = switch (serverResult) {
      Success(:final value) => value,
      Error(:final error) => throw Exception(error),
    };
    await server.connect(transport);

    await transport
        .handleRequest(
          req as JSObject,
          res as JSObject,
          body,
        )
        .toDart;
    return;
  }

  res
    ..status(400)
    ..send(_badRequestJson);
};

/// GET/DELETE /mcp handler — requires existing session.
Future<void> Function(Request, Response)
    _mcpGetDeleteHandler(
  Map<String, StreamableHttpTransport> transports,
) => (req, res) async {
  final sessionId =
      _getHeader(req, 'mcp-session-id');
  if (sessionId == null ||
      !transports.containsKey(sessionId)) {
    res
      ..status(400)
      ..send('Invalid or missing session ID');
    return;
  }
  await transports[sessionId]
      ?.handleRequest(
        req as JSObject,
        res as JSObject,
      )
      .toDart;
};

/// POST /admin/events — Streamable HTTP init or
/// existing session.
Future<void> Function(Request, Response)
    _adminPostHandler(
  AdminEventHub hub,
  Logger log,
) => (req, res) async {
  final sessionId =
      _getHeader(req, 'mcp-session-id');
  final body = req.body;

  if (sessionId != null &&
      hub.transports.containsKey(sessionId)) {
    await hub.transports[sessionId]
        ?.handleRequest(
          req as JSObject,
          res as JSObject,
          body,
        )
        .toDart;
    return;
  }

  if (sessionId == null &&
      _isInitializeRequest(body)) {
    late final StreamableHttpTransport transport;
    final transportResult =
        createStreamableHttpTransport(
          sessionIdGenerator: _randomUUID,
          onSessionInitialized: (sid) {
            log.info(
              'Admin session init',
              structuredData: {'sessionId': sid},
            );
            hub.transports[sid] = transport;
          },
        );
    transport = switch (transportResult) {
      Success(:final value) => value,
      Error(:final error) => throw Exception(error),
    };

    (transport as JSObject)['onclose'] = (() {
      final sid = transport.sessionId;
      if (sid != null) {
        log.info(
          'Admin session closed',
          structuredData: {'sessionId': sid},
        );
        hub.transports.remove(sid);
        hub.servers.remove(sid);
      }
    }).toJS;

    final serverResult = McpServer.create(
      (name: 'too-many-cooks', version: '0.1.0'),
      options: (
        capabilities: (
          tools: null,
          resources: null,
          prompts: null,
          logging: (enabled: true),
        ),
        instructions: null,
      ),
    );
    final server = switch (serverResult) {
      Success(:final value) => value,
      Error(:final error) => throw Exception(error),
    };
    await server.connect(transport);

    // Track server for event pushing
    final sid = transport.sessionId;
    if (sid != null) {
      hub.servers[sid] = server;
    }

    await transport
        .handleRequest(
          req as JSObject,
          res as JSObject,
          body,
        )
        .toDart;
    return;
  }

  res
    ..status(400)
    ..send(_badRequestJson);
};

/// GET/DELETE /admin/events — requires existing admin
/// session.
Future<void> Function(Request, Response)
    _adminGetDeleteHandler(
  AdminEventHub hub,
) => (req, res) async {
  final sessionId =
      _getHeader(req, 'mcp-session-id');
  if (sessionId == null ||
      !hub.transports.containsKey(sessionId)) {
    res
      ..status(400)
      ..send('Invalid or missing session ID');
    return;
  }
  await hub.transports[sessionId]
      ?.handleRequest(
        req as JSObject,
        res as JSObject,
      )
      .toDart;
};

/// Wrap an async handler for Express.
JSFunction _asyncHandler(
  Future<void> Function(Request, Response) fn,
  Logger log,
) => ((Request req, Response res) {
  unawaited(fn(req, res).catchError((Object e) {
    log.error(
      'Request error',
      structuredData: {'error': '$e'},
    );
  }));
}).toJS;

String _resolveLogFilePath() {
  final logsDir = pathJoin([getWorkspaceFolder(), 'logs']);
  if (!existsSync(logsDir)) {
    mkdirSync(logsDir, recursive: true);
  }
  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  return pathJoin([logsDir, 'mcp-server-$timestamp.log']);
}

Logger _createLogger() {
  final logFilePath = _resolveLogFilePath();
  return createLoggerWithContext(
    createLoggingContext(
      transports: [
        logTransport(_createConsoleTransport()),
        logTransport(_createFileTransport(logFilePath)),
      ],
      minimumLogLevel: LogLevel.debug,
    ),
  );
}

String _formatLogLine(LogMessage message) {
  final level = message.logLevel.name.toUpperCase();
  final data = message.structuredData;
  final dataStr =
      data != null && data.isNotEmpty ? ' $data' : '';
  return '[TMC] [${message.timestamp.toIso8601String()}] '
      '[$level] ${message.message}$dataStr\n';
}

LogFunction _createConsoleTransport() =>
    (message, minimumLogLevel) {
      if (message.logLevel.index < minimumLogLevel.index) {
        return;
      }
      consoleError(_formatLogLine(message).trimRight());
    };

LogFunction _createFileTransport(String filePath) =>
    (message, minimumLogLevel) {
      if (message.logLevel.index < minimumLogLevel.index) {
        return;
      }
      appendFileSync(filePath, _formatLogLine(message));
    };
