/// Entry point for Too Many Cooks MCP server.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:dart_node_core/dart_node_core.dart';
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

/// Writes to stderr (safe for MCP stdio transport).
@JS('process.stderr.write')
external void _stderrWrite(JSString data);

/// Keep the Node.js event loop alive using setInterval.
/// dart2js Completer.future doesn't keep the JS event loop running.
@JS('setInterval')
external void _setInterval(JSFunction callback, int delay);

Future<void> _startServer() async {
  _stderrWrite('[TMC] Creating server...\n'.toJS);
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

  _stderrWrite('[TMC] Connecting to transport...\n'.toJS);
  await server.connect(transport);
  _stderrWrite('[TMC] Server connected and running.\n'.toJS);

  // Keep the Node.js event loop alive - setInterval creates pending work
  // that prevents the process from exiting. The stdio transport handles
  // stdin listening in the JS layer.
  _setInterval((() {}).toJS, 60000);

  // Never resolve - server runs until killed
  await Completer<void>().future;
}
