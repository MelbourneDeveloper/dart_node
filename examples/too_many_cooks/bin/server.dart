/// Entry point for Too Many Cooks MCP server.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/too_many_cooks.dart';

Future<void> main() async {
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
}
