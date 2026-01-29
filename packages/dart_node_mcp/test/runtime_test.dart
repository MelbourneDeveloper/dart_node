/// Runtime integration tests that exercise actual MCP SDK functionality.
@TestOn('node')
library;

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('Runtime McpServer tests', () {
    test('creates McpServer and registers tool', () {
      const impl = (name: 'runtime-test', version: '1.0.0');
      final serverResult = McpServer.create(impl);

      // Server creation should succeed with MCP SDK installed
      expect(serverResult.isSuccess, isTrue);

      if (serverResult.isSuccess) {
        final server = (serverResult as Success<McpServer, String>).value;

        // Register a real tool
        const config = (
          title: 'Echo Tool',
          description: 'Echoes input',
          inputSchema: null,
          outputSchema: null,
          annotations: null,
        );

        Future<CallToolResult> callback(
          Map<String, Object?> args,
          ToolCallMeta? meta,
        ) async =>
            (
              content: <Map<String, Object?>>[
                {'type': 'text', 'text': 'Echo: ${args['message']}'},
              ],
              isError: false,
            );

        final toolResult = server.registerTool('echo', config, callback);

        // Tool registration should succeed
        expect(toolResult.isSuccess, isTrue);

        if (toolResult.isSuccess) {
          final tool = (toolResult as Success<RegisteredTool, String>).value;
          expect(tool.name, equals('echo'));

          // Test notifications (should not throw)
          server.sendToolListChanged();
        }
      }
    });

    test('creates McpServer and registers resource', () {
      const impl = (name: 'resource-test', version: '1.0.0');
      final serverResult = McpServer.create(impl);

      expect(serverResult.isSuccess, isTrue);

      if (serverResult.isSuccess) {
        final server = (serverResult as Success<McpServer, String>).value;

        const metadata = (
          description: 'Test resource',
          mimeType: 'text/plain',
        );

        Future<ReadResourceResult> callback(String uri) async => (
          contents: <Map<String, Object?>>[
            {
              'type': 'resource',
              'uri': uri,
              'mimeType': 'text/plain',
              'text': 'Resource content',
            },
          ],
        );

        final resourceResult = server.registerResource(
          'test-resource',
          'file:///test.txt',
          metadata,
          callback,
        );

        expect(resourceResult.isSuccess, isTrue);

        if (resourceResult.isSuccess) {
          final resource = (resourceResult as Success<RegisteredResource, String>).value;
          expect(resource.name, equals('test-resource'));
          expect(resource.uri, equals('file:///test.txt'));

          server.sendResourceListChanged();
        }
      }
    });

    test('creates McpServer and registers prompt', () {
      const impl = (name: 'prompt-test', version: '1.0.0');
      final serverResult = McpServer.create(impl);

      expect(serverResult.isSuccess, isTrue);

      if (serverResult.isSuccess) {
        final server = (serverResult as Success<McpServer, String>).value;

        const config = (
          title: 'Test Prompt',
          description: 'A test prompt',
          argsSchema: null,
        );

        Future<GetPromptResult> callback(Map<String, String> args) async => (
          description: 'Test prompt result',
          messages: [
            (role: 'assistant', content: {'type': 'text', 'text': 'Prompt response'}),
          ],
        );

        final promptResult = server.registerPrompt('test-prompt', config, callback);

        expect(promptResult.isSuccess, isTrue);

        if (promptResult.isSuccess) {
          final prompt = (promptResult as Success<RegisteredPrompt, String>).value;
          expect(prompt.name, equals('test-prompt'));

          server.sendPromptListChanged();
        }
      }
    });

    test('creates McpServer with capabilities', () {
      const impl = (name: 'capabilities-test', version: '1.0.0');
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: (subscribe: true, listChanged: true),
          prompts: (listChanged: false),
          logging: (enabled: true),
        ),
        instructions: 'Test server',
      );

      final result = McpServer.create(impl, options: options);

      expect(result.isSuccess, isTrue);

      if (result.isSuccess) {
        final server = (result as Success<McpServer, String>).value;

        // Can access underlying server
        expect(server.server, isNotNull);

        // isConnected should work
        expect(server.isConnected(), isFalse);
      }
    });

    test('creates stdio transport', () {
      final result = createStdioServerTransport();

      // Should create successfully
      expect(result.isSuccess, isTrue);

      if (result.isSuccess) {
        final transport = (result as Success<StdioServerTransport, String>).value;
        expect(transport, isNotNull);
      }
    });

    test('creates low-level Server', () {
      const impl = (name: 'low-level-test', version: '1.0.0');
      final result = createServer(impl);

      expect(result.isSuccess, isTrue);

      if (result.isSuccess) {
        final server = (result as Success<Server, String>).value;
        expect(server, isNotNull);
      }
    });

    test('registers multiple tools and resources on same server', () {
      const impl = (name: 'multi-register-test', version: '1.0.0');
      final serverResult = McpServer.create(impl);

      expect(serverResult.isSuccess, isTrue);

      if (serverResult.isSuccess) {
        final server = (serverResult as Success<McpServer, String>).value;

        // Register first tool
        const config1 = (
          title: null,
          description: 'Tool 1',
          inputSchema: null,
          outputSchema: null,
          annotations: null,
        );

        Future<CallToolResult> callback1(
          Map<String, Object?> args,
          ToolCallMeta? meta,
        ) async =>
            (
              content: <Map<String, Object?>>[
                {'type': 'text', 'text': 'Tool 1'},
              ],
              isError: null,
            );

        final tool1 = server.registerTool('tool1', config1, callback1);
        expect(tool1.isSuccess, isTrue);

        // Register second tool
        const config2 = (
          title: null,
          description: 'Tool 2',
          inputSchema: null,
          outputSchema: null,
          annotations: null,
        );

        Future<CallToolResult> callback2(
          Map<String, Object?> args,
          ToolCallMeta? meta,
        ) async =>
            (
              content: <Map<String, Object?>>[
                {'type': 'text', 'text': 'Tool 2'},
              ],
              isError: null,
            );

        final tool2 = server.registerTool('tool2', config2, callback2);
        expect(tool2.isSuccess, isTrue);

        // Register a resource
        const metadata = (
          description: 'Resource 1',
          mimeType: 'application/json',
        );

        Future<ReadResourceResult> resourceCallback(String uri) async => (
          contents: <Map<String, Object?>>[
            {
              'type': 'resource',
              'uri': uri,
              'mimeType': 'application/json',
              'text': '{}',
            },
          ],
        );

        final resource1 = server.registerResource(
          'resource1',
          'file:///resource1.json',
          metadata,
          resourceCallback,
        );
        expect(resource1.isSuccess, isTrue);

        // All notifications should work
        server.sendToolListChanged();
        server.sendResourceListChanged();
        server.sendPromptListChanged();
      }
    });
  });
}
