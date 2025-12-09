/// Stdio server transport for CLI-based MCP servers.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_mcp/src/transport.dart';
import 'package:meta/meta.dart';
import 'package:nadz/nadz.dart';

/// Stdio server transport (matches TypeScript StdioServerTransport).
///
/// Uses stdin/stdout for communication, suitable for CLI tools.
extension type StdioServerTransport._(JSObject _) implements Transport {
  /// Start listening for messages on stdin.
  ///
  /// This is called automatically by server.connect().
  @redeclare
  external JSPromise<JSAny?> start();

  /// Send a JSON-RPC message to stdout.
  @redeclare
  external JSPromise<JSAny?> send(JSObject message);

  /// Close the transport and release resources.
  @redeclare
  external JSPromise<JSAny?> close();
}

/// Create stdio transport with default stdin/stdout.
///
/// Returns [Success] with the transport or [Error] with message on failure.
Result<StdioServerTransport, String> createStdioServerTransport() {
  try {
    final sdkModule = requireModule(
      '@modelcontextprotocol/sdk/server/stdio.js',
    );
    final transportClass = (sdkModule as JSObject)['StdioServerTransport'];
    final jsTransportClass = transportClass as JSFunction;
    final transport = jsTransportClass
        .callAsConstructor<StdioServerTransport>();
    return Success(transport);
  } catch (e) {
    return Error('Failed to create stdio transport: $e');
  }
}

/// Create stdio transport with custom stdin/stdout streams.
///
/// Returns [Success] with the transport or [Error] with message on failure.
Result<StdioServerTransport, String> createStdioServerTransportWithStreams(
  JSObject stdin,
  JSObject stdout,
) {
  try {
    final sdkModule = requireModule(
      '@modelcontextprotocol/sdk/server/stdio.js',
    );
    final transportClass = (sdkModule as JSObject)['StdioServerTransport'];
    final jsTransportClass = transportClass as JSFunction;
    final transport = jsTransportClass.callAsConstructor<StdioServerTransport>(
      stdin,
      stdout,
    );
    return Success(transport);
  } catch (e) {
    return Error('Failed to create stdio transport with streams: $e');
  }
}
