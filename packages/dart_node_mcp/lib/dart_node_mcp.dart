/// MCP (Model Context Protocol) server bindings for Dart on Node.js.
///
/// This package provides typed Dart bindings for the @modelcontextprotocol/sdk
/// npm package, enabling you to build MCP servers in Dart that run on Node.js.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:dart_node_mcp/dart_node_mcp.dart';
/// import 'package:nadz/nadz.dart';
///
/// Future<void> main() async {
///   // Create server
///   final serverResult = McpServer.create(
///     (name: 'my-server', version: '1.0.0'),
///   );
///
///   final server = switch (serverResult) {
///     Success(:final value) => value,
///     Error(:final error) => throw Exception(error),
///   };
///
///   // Register a tool
///   server.registerTool(
///     'echo',
///     (description: 'Echo input back', inputSchema: null, ...),
///     (args, meta) async => (
///       content: [(type: 'text', text: args['message'] as String)],
///       isError: false,
///     ),
///   );
///
///   // Create transport and connect
///   final transportResult = createStdioServerTransport();
///   final transport = switch (transportResult) {
///     Success(:final value) => value,
///     Error(:final error) => throw Exception(error),
///   };
///
///   await server.connect(transport);
/// }
/// ```
library;

export 'src/callbacks.dart';
export 'src/mcp_server.dart' show McpServer;
export 'src/registered.dart';
export 'src/server.dart' show Server, createServer;
export 'src/stdio_transport.dart'
    show
        StdioServerTransport,
        createStdioServerTransport,
        createStdioServerTransportWithStreams;
export 'src/transport.dart'
    show
        Transport,
        TransportCloseCallback,
        TransportErrorCallback,
        TransportMessageCallback;
export 'src/types.dart';
