import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

/// Integration tests verifying the complete MCP server workflow.
///
/// Note: Full integration tests require Node.js runtime with MCP SDK installed.
/// These tests verify type correctness and API contracts that can be checked
/// in a pure Dart environment.
void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('End-to-end workflow types', () {
    test('complete server setup workflow compiles', () {
      // This test verifies that the complete workflow type-checks

      // Step 1: Define server info
      const serverInfo = (name: 'integration-test', version: '1.0.0');

      // Step 2: Define options
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: (subscribe: true, listChanged: true),
          prompts: (listChanged: true),
          logging: (enabled: true),
        ),
        instructions: 'Integration test server',
      );

      // Step 3: Create server (will fail without Node.js)
      final serverResult = McpServer.create(serverInfo, options: options);

      // Step 4: Type checks
      expect(serverResult, isA<Result<McpServer, String>>());
    });

    test('tool registration workflow types', () async {
      // Define tool config
      final toolConfig = (
        title: 'Calculator',
        description: 'Performs basic arithmetic',
        inputSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'operation': {
              'type': 'string',
              'enum': ['add', 'subtract', 'multiply', 'divide'],
            },
            'a': {'type': 'number'},
            'b': {'type': 'number'},
          },
          'required': ['operation', 'a', 'b'],
        },
        outputSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'result': {'type': 'number'},
          },
        },
        annotations: (
          title: 'Calc',
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        ),
      );

      // Define callback
      Future<CallToolResult> toolCallback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async {
        final op = args['operation'] as String;
        final a = args['a'] as num;
        final b = args['b'] as num;

        final result = switch (op) {
          'add' => a + b,
          'subtract' => a - b,
          'multiply' => a * b,
          'divide' => b != 0 ? a / b : double.nan,
          _ => double.nan,
        };

        return (
          content: <Object>[(type: 'text', text: 'Result: $result')],
          isError: false,
        );
      }

      // Test callback
      final result = await toolCallback({
        'operation': 'add',
        'a': 5,
        'b': 3,
      }, null);

      expect(result.isError, isFalse);
      final content = result.content.first as TextContent;
      expect(content.text, equals('Result: 8'));
      expect(toolConfig.title, equals('Calculator'));
    });

    test('resource registration workflow types', () async {
      // Define metadata
      const metadata = (
        description: 'Project configuration',
        mimeType: 'application/json',
      );

      // Define callback
      Future<ReadResourceResult> resourceCallback(String uri) async {
        // Simulate reading a config file
        final config = {
          'name': 'my-project',
          'version': '1.0.0',
          'debug': true,
        };

        return (
          contents: <Object>[
            (
              type: 'resource',
              uri: uri,
              mimeType: 'application/json',
              text: config.toString(),
            ),
          ],
        );
      }

      // Test callback
      final result = await resourceCallback('file:///config.json');

      expect(result.contents, hasLength(1));
      final resource = result.contents.first as ResourceContent;
      expect(resource.uri, equals('file:///config.json'));
      expect(metadata.mimeType, equals('application/json'));
    });

    test('resource template workflow types', () async {
      // Define template
      const template = (
        uriTemplate: 'db:///users/{userId}',
        name: 'User',
        description: 'Access user by ID',
        mimeType: 'application/json',
      );

      // Define metadata
      const metadata = (
        description: 'User record',
        mimeType: 'application/json',
      );

      // Define callback
      Future<ReadResourceResult> templateCallback(
        String uri,
        Map<String, String> variables,
      ) async {
        final userId = variables['userId'];
        final user = {
          'id': userId,
          'name': 'User $userId',
          'email': 'user$userId@example.com',
        };

        return (
          contents: <Object>[
            (
              type: 'resource',
              uri: uri,
              mimeType: 'application/json',
              text: user.toString(),
            ),
          ],
        );
      }

      // Test callback
      final result = await templateCallback('db:///users/123', {
        'userId': '123',
      });

      expect(result.contents, hasLength(1));
      expect(template.uriTemplate, contains('{userId}'));
      expect(metadata.mimeType, equals('application/json'));
    });

    test('prompt registration workflow types', () async {
      // Define config
      final promptConfig = (
        title: 'Code Review',
        description: 'Generate a code review prompt',
        argsSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'language': {'type': 'string'},
            'strictness': {
              'type': 'string',
              'enum': ['relaxed', 'moderate', 'strict'],
            },
          },
          'required': ['language'],
        },
      );

      // Define callback
      Future<GetPromptResult> promptCallback(Map<String, String> args) async {
        final language = args['language'] ?? 'unknown';
        final strictness = args['strictness'] ?? 'moderate';

        return (
          description: 'Code review prompt for $language',
          messages: <PromptMessage>[
            (
              role: 'user',
              content: (
                type: 'text',
                text: 'Review this $language code with $strictness checking.',
              ),
            ),
            (
              role: 'assistant',
              content: (
                type: 'text',
                text:
                    'I will review your $language code. '
                    'Please share the code you would like me to review.',
              ),
            ),
          ],
        );
      }

      // Test callback
      final result = await promptCallback({
        'language': 'dart',
        'strictness': 'strict',
      });

      expect(result.description, contains('dart'));
      expect(result.messages, hasLength(2));
      expect(promptConfig.title, equals('Code Review'));
    });
  });

  group('Multiple registrations', () {
    test('multiple tools can be defined', () {
      final tools = <String, (ToolConfig, ToolCallback)>{
        'echo': (
          (
            title: null,
            description: 'Echo input',
            inputSchema: null,
            outputSchema: null,
            annotations: null,
          ),
          (args, meta) async => (
            content: <Object>[(type: 'text', text: args['message'].toString())],
            isError: false,
          ),
        ),
        'uppercase': (
          (
            title: null,
            description: 'Convert to uppercase',
            inputSchema: null,
            outputSchema: null,
            annotations: null,
          ),
          (args, meta) async => (
            content: <Object>[
              (type: 'text', text: args['text'].toString().toUpperCase()),
            ],
            isError: false,
          ),
        ),
        'reverse': (
          (
            title: null,
            description: 'Reverse string',
            inputSchema: null,
            outputSchema: null,
            annotations: null,
          ),
          (args, meta) async => (
            content: <Object>[
              (
                type: 'text',
                text: args['text'].toString().split('').reversed.join(),
              ),
            ],
            isError: false,
          ),
        ),
      };

      expect(tools, hasLength(3));

      // Test each tool
      for (final entry in tools.entries) {
        final (config, callback) = entry.value;
        expect(config.description, isNotEmpty);
        expect(callback, isA<ToolCallback>());
      }
    });

    test('multiple resources can be defined', () {
      final resources =
          <String, (String, ResourceMetadata, ReadResourceCallback)>{
            'config': (
              'file:///config.json',
              (description: 'Config', mimeType: 'application/json'),
              (uri) async => (contents: <Object>[(type: 'text', text: '{}')]),
            ),
            'readme': (
              'file:///README.md',
              (description: 'Readme', mimeType: 'text/markdown'),
              (uri) async =>
                  (contents: <Object>[(type: 'text', text: '# README')]),
            ),
          };

      expect(resources, hasLength(2));
    });

    test('multiple prompts can be defined', () {
      final prompts = <String, (PromptConfig, PromptCallback)>{
        'greeting': (
          (title: 'Greeting', description: 'Say hello', argsSchema: null),
          (args) async => (
            description: null,
            messages: <PromptMessage>[
              (role: 'assistant', content: (type: 'text', text: 'Hello!')),
            ],
          ),
        ),
        'farewell': (
          (title: 'Farewell', description: 'Say goodbye', argsSchema: null),
          (args) async => (
            description: null,
            messages: <PromptMessage>[
              (role: 'assistant', content: (type: 'text', text: 'Goodbye!')),
            ],
          ),
        ),
      };

      expect(prompts, hasLength(2));
    });
  });

  group('Error handling patterns', () {
    test('tool can return error result', () async {
      Future<CallToolResult> failingTool(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async {
        if (args['fail'] == true) {
          return (
            content: <Object>[(type: 'text', text: 'Intentional failure')],
            isError: true,
          );
        }
        return (content: <Object>[], isError: false);
      }

      final errorResult = await failingTool({'fail': true}, null);
      final successResult = await failingTool({'fail': false}, null);

      expect(errorResult.isError, isTrue);
      expect(successResult.isError, isFalse);
    });

    test('Result pattern matching works', () {
      const impl = (name: 'test', version: '1.0.0');
      final result = McpServer.create(impl);

      final message = switch (result) {
        Success(:final value) => 'Created: ${value.runtimeType}',
        Error(:final error) => 'Failed: $error',
      };

      expect(message, isA<String>());
    });
  });

  group('Notification patterns', () {
    test('logging params support all levels', () {
      final levels = ['debug', 'info', 'notice', 'warning', 'error'];

      for (final level in levels) {
        final params = (
          level: level,
          logger: 'test-logger',
          data: 'Test message for $level',
        );
        expect(params.level, equals(level));
      }
    });

    test('logging params support complex data', () {
      final params = (
        level: 'debug',
        logger: 'test',
        data: {
          'request': {'method': 'tools/call', 'id': 1},
          'response': {'result': 'success'},
          'timing': {'duration_ms': 42},
        },
      );

      expect(params.data, isA<Map<String, Object?>>());
    });
  });

  group('Transport workflow', () {
    test('stdio transport factory exists', () {
      expect(createStdioServerTransport, isA<Function>());
    });

    test('stdio transport with streams factory exists', () {
      expect(createStdioServerTransportWithStreams, isA<Function>());
    });

    test('transport creation returns Result', () {
      final result = createStdioServerTransport();
      expect(result, isA<Result<StdioServerTransport, String>>());
    });
  });

  group('Content type handling', () {
    test('text content in tool result', () async {
      Future<CallToolResult> textTool(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async => (
        content: <Object>[(type: 'text', text: 'Simple text response')],
        isError: false,
      );

      final result = await textTool({}, null);
      final content = result.content.first as TextContent;
      expect(content.type, equals('text'));
    });

    test('image content in tool result', () async {
      Future<CallToolResult> imageTool(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async => (
        content: <Object>[
          (type: 'image', data: 'base64imagedata==', mimeType: 'image/png'),
        ],
        isError: false,
      );

      final result = await imageTool({}, null);
      final content = result.content.first as ImageContent;
      expect(content.type, equals('image'));
      expect(content.mimeType, equals('image/png'));
    });

    test('resource content in result', () async {
      Future<ReadResourceResult> resourceReader(String uri) async => (
        contents: <Object>[
          (
            type: 'resource',
            uri: uri,
            mimeType: 'text/plain',
            text: 'File contents here',
          ),
        ],
      );

      final result = await resourceReader('file:///test.txt');
      final content = result.contents.first as ResourceContent;
      expect(content.type, equals('resource'));
      expect(content.uri, equals('file:///test.txt'));
    });

    test('mixed content types', () async {
      Future<CallToolResult> mixedTool(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async => (
        content: <Object>[
          (type: 'text', text: 'Description'),
          (type: 'image', data: 'base64data', mimeType: 'image/jpeg'),
          (
            type: 'resource',
            uri: 'file:///data.json',
            mimeType: 'application/json',
            text: '{"key": "value"}',
          ),
        ],
        isError: false,
      );

      final result = await mixedTool({}, null);
      expect(result.content, hasLength(3));
    });
  });
}
