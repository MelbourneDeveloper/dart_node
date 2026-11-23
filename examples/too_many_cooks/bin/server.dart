/// Entry point for Too Many Cooks MCP server.
library;

import 'dart:async';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/too_many_cooks.dart';

Future<void> main() async {
  try {
    await _startServer();
  } catch (e, st) {
    consoleError('[too-many-cooks] Fatal error: $e');
    consoleError('[too-many-cooks] Stack trace: $st');
    rethrow;
  }
}

Future<void> _startServer() async {
  final serverResult = createTooManyCooksServer();

  final server = switch (serverResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  final transportResult = createStdioServerTransport();
  final transport = switch (transportResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  await server.connect(transport);

  // Keep the Dart event loop alive - stdio transport handles stdin listening
  // in the JS layer, but dart2js needs pending async work to stay running.
  await Completer<void>().future;
}
