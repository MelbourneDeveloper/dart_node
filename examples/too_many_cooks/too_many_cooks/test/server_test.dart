/// Tests for server.dart - createTooManyCooksServer.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks/src/server.dart';

void main() {
  group('createTooManyCooksServer', () {
    test('creates server with default config', () {
      final result = createTooManyCooksServer();
      expect(result, isA<Success<McpServer, String>>());
    });

    test('creates server with custom config', () {
      final config = (
        dbPath: '.test_server_${DateTime.now().millisecondsSinceEpoch}.db',
        lockTimeoutMs: 5000,
        maxMessageLength: 100,
        maxPlanLength: 50,
      );
      final logger = createLoggerWithContext(createLoggingContext());
      final result = createTooManyCooksServer(config: config, logger: logger);
      expect(result, isA<Success<McpServer, String>>());
    });

    test('fails with invalid db path', () {
      const config = (
        dbPath: '/nonexistent/path/that/does/not/exist/db.sqlite',
        lockTimeoutMs: 5000,
        maxMessageLength: 100,
        maxPlanLength: 50,
      );
      final result = createTooManyCooksServer(config: config);
      expect(result, isA<Error<McpServer, String>>());
    });
  });
}
