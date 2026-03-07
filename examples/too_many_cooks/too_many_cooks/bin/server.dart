/// Entry point for Too Many Cooks MCP server.
///
/// Starts a single Express HTTP server on port 4040 with:
/// - `/mcp` — MCP Streamable HTTP for agent connections
/// - `/admin/*` — REST + SSE for the VSCode extension
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

Future<void> main() async {
  _stderrWrite('[TMC] Server starting...\n'.toJS);
  try {
    await _startServer();
  } catch (e, st) {
    _stderrWrite('[TMC] Fatal error: $e\n'.toJS);
    _stderrWrite('[TMC] Stack trace: $st\n'.toJS);
    consoleError('[too-many-cooks] Fatal error: $e');
    consoleError('[too-many-cooks] Stack trace: $st');
    rethrow;
  }
}

@JS('process.stderr.write')
external void _stderrWrite(JSString data);

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

Future<void> _startServer() async {
  _stderrWrite('[TMC] Creating server...\n'.toJS);

  final cfg = defaultConfig;
  final log = _createLogger();

  // Create shared database
  final dbResult = createDb(cfg);
  final db = switch (dbResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };
  _stderrWrite('[TMC] Database created.\n'.toJS);

  // Session tracking for Streamable HTTP
  final transports =
      <String, StreamableHttpTransport>{};

  // Create Express app
  final app = express();

  // Admin REST endpoints (VSIX)
  registerAdminRoutes(app, db);

  // MCP Streamable HTTP routes
  final postFn =
      _mcpPostHandler(transports, db, cfg, log);
  final getDeleteFn =
      _mcpGetDeleteHandler(transports);
  app
    ..post('/mcp', _asyncHandler(postFn))
    ..get('/mcp', _asyncHandler(getDeleteFn))
    ..delete('/mcp', _asyncHandler(getDeleteFn));

  // Start listening
  const port = 4040;
  app.listen(
    port,
    (() {
      _stderrWrite(
        '[TMC] Server listening on port $port\n'
            .toJS,
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
            _stderrWrite(
              '[TMC] Session init: $sid\n'.toJS,
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
        _stderrWrite(
          '[TMC] Session closed: $sid\n'.toJS,
        );
        transports.remove(sid);
      }
    }).toJS;

    final serverResult =
        createMcpServerForDb(db, cfg, log);
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

/// Wrap an async handler for Express.
JSFunction _asyncHandler(
  Future<void> Function(Request, Response) fn,
) => ((Request req, Response res) {
  unawaited(fn(req, res).catchError((Object e) {
    _stderrWrite('[TMC] Request error: $e\n'.toJS);
  }));
}).toJS;

Logger _createLogger() => createLoggerWithContext(
  createLoggingContext(
    transports: [logTransport(_logToStderr)],
    minimumLogLevel: LogLevel.debug,
  ),
);

void _logToStderr(
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
  final line =
      '[TMC] [$level] ${message.message}$dataStr\n';
  _stderrWrite(line.toJS);
}
