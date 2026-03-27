/// Streamable HTTP server transport for HTTP-based MCP servers.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_mcp/src/transport.dart';
import 'package:meta/meta.dart';
import 'package:nadz/nadz.dart';

/// Streamable HTTP server transport (matches TypeScript
/// StreamableHTTPServerTransport).
///
/// Handles MCP protocol over Streamable HTTP transport.
/// Each session gets its own transport instance.
extension type StreamableHttpTransport._(JSObject _) implements Transport {
  @redeclare
  external JSPromise<JSAny?> start();

  @redeclare
  external JSPromise<JSAny?> send(JSObject message);

  @redeclare
  external JSPromise<JSAny?> close();

  /// The session ID for this transport, if in stateful
  /// mode.
  external String? get sessionId;

  /// Handle an incoming HTTP request.
  ///
  /// [req] and [res] are Node.js IncomingMessage and
  /// ServerResponse objects (or Express req/res which
  /// extend them).
  /// [parsedBody] is an optional pre-parsed request body.
  external JSPromise<JSAny?> handleRequest(
    JSObject req,
    JSObject res, [
    JSAny? parsedBody,
  ]);
}

/// Options for creating a StreamableHttpTransport.
typedef StreamableHttpTransportOptions = ({
  JSFunction? sessionIdGenerator,
  JSFunction? onsessioninitialized,
});

/// Create a stateful Streamable HTTP transport.
///
/// Each call creates a new transport for one session.
/// Use [onSessionInitialized] to capture the session ID.
Result<StreamableHttpTransport, String> createStreamableHttpTransport({
  String Function()? sessionIdGenerator,
  void Function(String sessionId)? onSessionInitialized,
}) {
  try {
    final sdkModule = requireModule(
      '@modelcontextprotocol/sdk/server/streamableHttp.js',
    );
    final transportClass =
        (sdkModule as JSObject)['StreamableHTTPServerTransport'] as JSFunction;

    final options = JSObject();
    if (sessionIdGenerator != null) {
      options['sessionIdGenerator'] = (() => sessionIdGenerator().toJS).toJS;
    }
    if (onSessionInitialized != null) {
      options['onsessioninitialized'] = ((JSString sid) => onSessionInitialized(
        sid.toDart,
      )).toJS;
    }

    final transport = transportClass.callAsConstructor<StreamableHttpTransport>(
      options,
    );
    return Success(transport);
  } catch (e) {
    return Error('Failed to create StreamableHTTP transport: $e');
  }
}
