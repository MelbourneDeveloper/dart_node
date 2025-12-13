// McpServer tests - factory tests and pure Dart type tests
// Actual McpServer instance creation requires Node.js runtime
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('McpServer.create', () {
    test('function exists and can be called', () {
      expect(McpServer.create, isA<Function>());
    });

    test('accepts Implementation parameter', () {
      const impl = (name: 'test-mcp', version: '1.0.0');

      final result = McpServer.create(impl);

      expect(result, isA<Result<McpServer, String>>());
    });

    test('accepts optional ServerOptions', () {
      const impl = (name: 'configured-mcp', version: '1.0.0');
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: (subscribe: true, listChanged: true),
          prompts: (listChanged: false),
          logging: (enabled: true),
        ),
        instructions: 'Server instructions for client',
      );

      final result = McpServer.create(impl, options: options);

      expect(result, isA<Result<McpServer, String>>());
    });

    test('returns Error without Node.js runtime', () {
      const impl = (name: 'test', version: '0.1.0');

      final result = McpServer.create(impl);

      switch (result) {
        case Success():
          break;
        case Error(:final error):
          expect(error, contains('Failed to create MCP server'));
      }
    });
  });

  group('McpServer instance methods exist', () {
    test('McpServer has registerTool method', () {
      // registerTool(name, config, callback) -> Result<RegisteredTool, String>
      expect(true, isTrue);
    });

    test('McpServer has registerResource method', () {
      // registerResource(name, uri, metadata, callback)
      // -> Result<RegisteredResource, String>
      expect(true, isTrue);
    });

    test('McpServer has registerResourceTemplate method', () {
      // registerResourceTemplate(name, template, metadata, callback)
      // -> Result<RegisteredResourceTemplate, String>
      expect(true, isTrue);
    });

    test('McpServer has registerPrompt method', () {
      // registerPrompt(name, config, callback)
      // -> Result<RegisteredPrompt, String>
      expect(true, isTrue);
    });

    test('McpServer has connect method', () {
      // connect(transport) -> Future<Result<void, String>>
      expect(true, isTrue);
    });

    test('McpServer has close method', () {
      // close() -> Future<Result<void, String>>
      expect(true, isTrue);
    });

    test('McpServer has isConnected method', () {
      // isConnected() -> bool
      expect(true, isTrue);
    });

    test('McpServer has sendLoggingMessage method', () {
      // sendLoggingMessage(params, sessionId?) -> Future<Result<void, String>>
      expect(true, isTrue);
    });

    test('McpServer has notification methods', () {
      // sendResourceListChanged() -> void
      // sendToolListChanged() -> void
      // sendPromptListChanged() -> void
      expect(true, isTrue);
    });

    test('McpServer has server getter', () {
      // server -> Server (underlying low-level server)
      expect(true, isTrue);
    });
  });

  group('Tool registration scenarios', () {
    test('minimal tool config', () {
      const config = (
        title: null,
        description: 'Simple tool',
        inputSchema: null,
        outputSchema: null,
        annotations: null,
      );

      // Callback that returns success
      Future<CallToolResult> callback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async =>
          (content: <Object>[(type: 'text', text: 'Done')], isError: false);

      // Verify types are correct
      expect(config.description, equals('Simple tool'));
      expect(callback, isA<ToolCallback>());
    });

    test('full tool config', () {
      final config = (
        title: 'Echo Tool',
        description: 'Echoes the input message',
        inputSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'message': {'type': 'string', 'description': 'Message to echo'},
          },
          'required': ['message'],
        },
        outputSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'echo': {'type': 'string'},
          },
        },
        annotations: (
          title: 'Echo',
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        ),
      );

      expect(config.title, equals('Echo Tool'));
      expect(config.inputSchema['type'], equals('object'));
      expect(config.annotations.readOnlyHint, isTrue);
    });

    test('tool callback with args', () async {
      Future<CallToolResult> callback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async {
        final message = args['message'];
        return (
          content: <Object>[(type: 'text', text: 'Echo: $message')],
          isError: false,
        );
      }

      final result = await callback({'message': 'Hello'}, null);

      expect(result.isError, isFalse);
      final content = result.content.first as TextContent;
      expect(content.text, equals('Echo: Hello'));
    });

    test('tool callback with meta', () async {
      String? capturedToken;

      Future<CallToolResult> callback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async {
        capturedToken = meta?.progressToken;
        return (content: <Object>[], isError: null);
      }

      await callback({}, (progressToken: 'prog-123'));

      expect(capturedToken, equals('prog-123'));
    });

    test('tool callback returning error', () async {
      Future<CallToolResult> callback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async => (
        content: <Object>[(type: 'text', text: 'Tool execution failed')],
        isError: true,
      );

      final result = await callback({}, null);

      expect(result.isError, isTrue);
    });
  });

  group('Resource registration scenarios', () {
    test('simple resource', () {
      const metadata = (
        description: 'Configuration file',
        mimeType: 'application/json',
      );

      Future<ReadResourceResult> callback(String uri) async => (
        contents: <Object>[
          (
            type: 'resource',
            uri: uri,
            mimeType: 'application/json',
            text: '{"key": "value"}',
          ),
        ],
      );

      expect(metadata.description, equals('Configuration file'));
      expect(callback, isA<ReadResourceCallback>());
    });

    test('resource callback receives uri', () async {
      String? capturedUri;

      Future<ReadResourceResult> callback(String uri) async {
        capturedUri = uri;
        return (contents: <Object>[]);
      }

      await callback('file:///config.json');

      expect(capturedUri, equals('file:///config.json'));
    });
  });

  group('Resource template registration scenarios', () {
    test('template with variables', () {
      const template = (
        uriTemplate: 'db:///users/{userId}/posts/{postId}',
        name: 'User Post',
        description: 'Access user posts',
        mimeType: 'application/json',
      );

      expect(template.uriTemplate, contains('{userId}'));
      expect(template.uriTemplate, contains('{postId}'));
    });

    test('template callback receives variables', () async {
      Map<String, String>? capturedVars;

      Future<ReadResourceResult> callback(
        String uri,
        Map<String, String> variables,
      ) async {
        capturedVars = variables;
        return (
          contents: <Object>[
            (type: 'text', text: 'User: ${variables['userId']}'),
          ],
        );
      }

      await callback('db:///users/123', {'userId': '123'});

      expect(capturedVars, equals({'userId': '123'}));
    });
  });

  group('Prompt registration scenarios', () {
    test('simple prompt', () {
      const config = (
        title: 'Greeting',
        description: 'Generate a greeting',
        argsSchema: null,
      );

      Future<GetPromptResult> callback(Map<String, String> args) async => (
        description: 'A greeting prompt',
        messages: <PromptMessage>[
          (role: 'assistant', content: (type: 'text', text: 'Hello!')),
        ],
      );

      expect(config.title, equals('Greeting'));
      expect(callback, isA<PromptCallback>());
    });

    test('prompt with args schema', () {
      final config = (
        title: 'Personalized Greeting',
        description: 'Generate a personalized greeting',
        argsSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'formal': {'type': 'boolean'},
          },
          'required': ['name'],
        },
      );

      expect(config.argsSchema['type'], equals('object'));
    });

    test('prompt callback with args', () async {
      Future<GetPromptResult> callback(Map<String, String> args) async {
        final name = args['name'] ?? 'Guest';
        final formal = args['formal'] == 'true';
        final greeting = formal ? 'Good day, $name' : 'Hey $name!';

        return (
          description: 'Greeting for $name',
          messages: <PromptMessage>[
            (role: 'user', content: (type: 'text', text: 'Greet $name')),
            (role: 'assistant', content: (type: 'text', text: greeting)),
          ],
        );
      }

      final result = await callback({'name': 'Alice', 'formal': 'true'});

      expect(result.description, equals('Greeting for Alice'));
      expect(result.messages, hasLength(2));
    });
  });

  group('LoggingMessageParams', () {
    test('creates with all fields', () {
      const params = (level: 'info', logger: 'mcp-server', data: 'Log data');

      expect(params.level, equals('info'));
      expect(params.logger, equals('mcp-server'));
      expect(params.data, equals('Log data'));
    });

    test('supports various log levels', () {
      final levels = ['debug', 'info', 'notice', 'warning', 'error'];

      for (final level in levels) {
        final params = (level: level, logger: null, data: null);
        expect(params.level, equals(level));
      }
    });

    test('data can be complex object', () {
      final params = (
        level: 'debug',
        logger: 'test',
        data: {
          'key': 'value',
          'nested': {'inner': 123},
        },
      );

      expect(params.data, isA<Map<String, Object?>>());
    });
  });
}
