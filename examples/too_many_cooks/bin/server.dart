/// Entry point for Too Many Cooks MCP server.
library;

import 'dart:async';
import 'dart:js_interop';

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

/// Keep the Node.js event loop alive using setInterval.
/// dart2js Completer.future doesn't keep the JS event loop running.
@JS('setInterval')
external void _setInterval(JSFunction callback, int delay);

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

  // Keep the Node.js event loop alive - setInterval creates pending work
  // that prevents the process from exiting. The stdio transport handles
  // stdin listening in the JS layer.
  _setInterval((() {}).toJS, 60000);

  // Never resolve - server runs until killed
  await Completer<void>().future;
}
