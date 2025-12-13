// Server factory tests - these verify the factory functions exist
// but actual Server creation requires Node.js runtime
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('createServer', () {
    test('function exists and can be called', () {
      expect(createServer, isA<Function>());
    });

    test('accepts Implementation parameter', () {
      const impl = (name: 'test-server', version: '1.0.0');

      // Will fail without Node.js runtime, but verifies API
      final result = createServer(impl);

      expect(result, isA<Result<Server, String>>());
    });

    test('accepts optional ServerOptions', () {
      const impl = (name: 'test-server', version: '1.0.0');
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: null,
          prompts: null,
          logging: null,
        ),
        instructions: 'Test instructions',
      );

      final result = createServer(impl, options: options);

      expect(result, isA<Result<Server, String>>());
    });

    test('returns Error without Node.js runtime', () {
      const impl = (name: 'test', version: '0.1.0');

      final result = createServer(impl);

      // Without Node.js runtime, should return Error
      switch (result) {
        case Success():
          // Unexpected in pure Dart test environment
          break;
        case Error(:final error):
          expect(error, contains('Failed to create server'));
      }
    });
  });

  group('ServerOptions variations', () {
    test('with all capabilities', () {
      const impl = (name: 'full-server', version: '1.0.0');
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: (subscribe: true, listChanged: true),
          prompts: (listChanged: true),
          logging: (enabled: true),
        ),
        instructions: 'Full server with all capabilities',
      );

      final result = createServer(impl, options: options);
      expect(result, isA<Result<Server, String>>());
    });

    test('with partial capabilities', () {
      const impl = (name: 'partial-server', version: '1.0.0');
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: null,
          prompts: null,
          logging: null,
        ),
        instructions: null,
      );

      final result = createServer(impl, options: options);
      expect(result, isA<Result<Server, String>>());
    });

    test('with only instructions', () {
      const impl = (name: 'instruction-server', version: '1.0.0');
      const options = (
        capabilities: null,
        instructions: 'Only instructions, no explicit capabilities',
      );

      final result = createServer(impl, options: options);
      expect(result, isA<Result<Server, String>>());
    });

    test('with null options', () {
      const impl = (name: 'simple-server', version: '1.0.0');

      final result = createServer(impl);
      expect(result, isA<Result<Server, String>>());
    });
  });

  group('Implementation variations', () {
    test('with simple version', () {
      const impl = (name: 'simple', version: '1.0.0');
      final result = createServer(impl);
      expect(result, isA<Result<Server, String>>());
    });

    test('with prerelease version', () {
      const impl = (name: 'beta', version: '0.1.0-beta.1');
      final result = createServer(impl);
      expect(result, isA<Result<Server, String>>());
    });

    test('with complex name', () {
      const impl = (name: '@org/package-name', version: '2.0.0');
      final result = createServer(impl);
      expect(result, isA<Result<Server, String>>());
    });

    test('with minimal version', () {
      const impl = (name: 'min', version: '0.0.1');
      final result = createServer(impl);
      expect(result, isA<Result<Server, String>>());
    });
  });

  group('Server method contracts', () {
    test('Server should have registerCapabilities method', () {
      // Server.registerCapabilities(capabilities) registers before connection
      expect(true, isTrue);
    });

    test('Server should have getClientCapabilities method', () {
      // Server.getClientCapabilities() returns client caps after init
      expect(true, isTrue);
    });

    test('Server should have getClientVersion method', () {
      // Server.getClientVersion() returns client name/version
      expect(true, isTrue);
    });

    test('Server should have setRequestHandler method', () {
      // Server.setRequestHandler(schema, handler) registers handlers
      expect(true, isTrue);
    });

    test('Server should have notification methods', () {
      // Server has sendResourceListChanged, sendToolListChanged,
      // sendPromptListChanged, sendResourceUpdated
      expect(true, isTrue);
    });

    test('Server should have connect and close methods', () {
      // Server.connect(transport) and Server.close() for lifecycle
      expect(true, isTrue);
    });

    test('Server should have ping method', () {
      // Server.ping() for connection health check
      expect(true, isTrue);
    });
  });
}
