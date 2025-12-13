// Pure Dart type tests - import only types.dart to avoid JS interop
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_mcp/src/types.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('Implementation', () {
    test('creates with name and version', () {
      const impl = (name: 'test-server', version: '1.0.0');

      expect(impl.name, equals('test-server'));
      expect(impl.version, equals('1.0.0'));
    });

    test('supports different version formats', () {
      const impl = (name: 'my-mcp', version: '0.1.0-beta.1');

      expect(impl.version, equals('0.1.0-beta.1'));
    });
  });

  group('ServerOptions', () {
    test('creates with null capabilities', () {
      const options = (capabilities: null, instructions: null);

      expect(options.capabilities, isNull);
      expect(options.instructions, isNull);
    });

    test('creates with instructions only', () {
      const options = (
        capabilities: null,
        instructions: 'System instructions for the server',
      );

      expect(
        options.instructions,
        equals('System instructions for the server'),
      );
    });
  });

  group('ServerCapabilities', () {
    test('creates with all capabilities', () {
      const caps = (
        tools: (listChanged: true),
        resources: (subscribe: true, listChanged: true),
        prompts: (listChanged: false),
        logging: (enabled: true),
      );

      expect(caps.tools.listChanged, isTrue);
      expect(caps.resources.subscribe, isTrue);
      expect(caps.resources.listChanged, isTrue);
      expect(caps.prompts.listChanged, isFalse);
      expect(caps.logging.enabled, isTrue);
    });

    test('creates with partial capabilities', () {
      const caps = (
        tools: (listChanged: true),
        resources: null,
        prompts: null,
        logging: null,
      );

      expect(caps.tools.listChanged, isTrue);
      expect(caps.resources, isNull);
    });
  });

  group('ToolConfig', () {
    test('creates with minimal config', () {
      const config = (
        title: null,
        description: 'A simple tool',
        inputSchema: null,
        outputSchema: null,
        annotations: null,
      );

      expect(config.description, equals('A simple tool'));
      expect(config.inputSchema, isNull);
    });

    test('creates with full config', () {
      final config = (
        title: 'Echo Tool',
        description: 'Echoes input back',
        inputSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'message': {'type': 'string'},
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
      expect(config.annotations.destructiveHint, isFalse);
    });
  });

  group('ToolAnnotations', () {
    test('creates with all hints', () {
      const annotations = (
        title: 'My Tool',
        readOnlyHint: true,
        destructiveHint: false,
        idempotentHint: true,
        openWorldHint: false,
      );

      expect(annotations.title, equals('My Tool'));
      expect(annotations.readOnlyHint, isTrue);
      expect(annotations.destructiveHint, isFalse);
      expect(annotations.idempotentHint, isTrue);
      expect(annotations.openWorldHint, isFalse);
    });

    test('creates with null hints', () {
      const annotations = (
        title: null,
        readOnlyHint: null,
        destructiveHint: null,
        idempotentHint: null,
        openWorldHint: null,
      );

      expect(annotations.title, isNull);
      expect(annotations.readOnlyHint, isNull);
    });
  });

  group('ResourceMetadata', () {
    test('creates with description and mimeType', () {
      const metadata = (
        description: 'Configuration file',
        mimeType: 'application/json',
      );

      expect(metadata.description, equals('Configuration file'));
      expect(metadata.mimeType, equals('application/json'));
    });

    test('creates with null values', () {
      const metadata = (description: null, mimeType: null);

      expect(metadata.description, isNull);
      expect(metadata.mimeType, isNull);
    });
  });

  group('ResourceTemplate', () {
    test('creates with URI template', () {
      const template = (
        uriTemplate: 'file:///{path}',
        name: 'File Resource',
        description: 'Access files by path',
        mimeType: 'text/plain',
      );

      expect(template.uriTemplate, equals('file:///{path}'));
      expect(template.name, equals('File Resource'));
      expect(template.description, equals('Access files by path'));
      expect(template.mimeType, equals('text/plain'));
    });

    test('creates with minimal template', () {
      const template = (
        uriTemplate: 'db:///{table}/{id}',
        name: null,
        description: null,
        mimeType: null,
      );

      expect(template.uriTemplate, equals('db:///{table}/{id}'));
      expect(template.name, isNull);
    });
  });

  group('PromptConfig', () {
    test('creates with full config', () {
      final config = (
        title: 'Greeting Prompt',
        description: 'Generates a personalized greeting',
        argsSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'formal': {'type': 'boolean'},
          },
        },
      );

      expect(config.title, equals('Greeting Prompt'));
      expect(config.description, equals('Generates a personalized greeting'));
      expect(config.argsSchema['type'], equals('object'));
    });

    test('creates with minimal config', () {
      const config = (title: null, description: null, argsSchema: null);

      expect(config.title, isNull);
      expect(config.argsSchema, isNull);
    });
  });

  group('LoggingMessageParams', () {
    test('creates with all params', () {
      const params = (
        level: 'info',
        logger: 'my-server',
        data: 'Log message data',
      );

      expect(params.level, equals('info'));
      expect(params.logger, equals('my-server'));
      expect(params.data, equals('Log message data'));
    });

    test('supports different log levels', () {
      for (final level in ['debug', 'info', 'notice', 'warning', 'error']) {
        final params = (level: level, logger: null, data: null);
        expect(params.level, equals(level));
      }
    });
  });

  group('Content types', () {
    test('TextContent creates correctly', () {
      const content = (type: 'text', text: 'Hello, world!');

      expect(content.type, equals('text'));
      expect(content.text, equals('Hello, world!'));
    });

    test('ImageContent creates correctly', () {
      const content = (
        type: 'image',
        data: 'base64encodeddata==',
        mimeType: 'image/png',
      );

      expect(content.type, equals('image'));
      expect(content.data, equals('base64encodeddata=='));
      expect(content.mimeType, equals('image/png'));
    });

    test('ResourceContent creates correctly', () {
      const content = (
        type: 'resource',
        uri: 'file:///config.json',
        mimeType: 'application/json',
        text: '{"key": "value"}',
      );

      expect(content.type, equals('resource'));
      expect(content.uri, equals('file:///config.json'));
      expect(content.mimeType, equals('application/json'));
      expect(content.text, equals('{"key": "value"}'));
    });

    test('ResourceContent with null optionals', () {
      const content = (
        type: 'resource',
        uri: 'file:///data.bin',
        mimeType: null,
        text: null,
      );

      expect(content.uri, equals('file:///data.bin'));
      expect(content.mimeType, isNull);
      expect(content.text, isNull);
    });
  });

  group('CallToolResult', () {
    test('creates success result', () {
      final result = (
        content: <Object>[(type: 'text', text: 'Success!')],
        isError: false,
      );

      expect(result.content, hasLength(1));
      expect(result.isError, isFalse);
    });

    test('creates error result', () {
      final result = (
        content: <Object>[(type: 'text', text: 'Error occurred')],
        isError: true,
      );

      expect(result.isError, isTrue);
    });

    test('creates with multiple content items', () {
      final result = (
        content: <Object>[
          (type: 'text', text: 'Part 1'),
          (type: 'text', text: 'Part 2'),
          (type: 'image', data: 'imagedata', mimeType: 'image/png'),
        ],
        isError: null,
      );

      expect(result.content, hasLength(3));
      expect(result.isError, isNull);
    });
  });

  group('ReadResourceResult', () {
    test('creates with contents', () {
      final result = (
        contents: <Object>[
          (
            type: 'resource',
            uri: 'file:///test.txt',
            mimeType: 'text/plain',
            text: 'File contents',
          ),
        ],
      );

      expect(result.contents, hasLength(1));
    });

    test('creates with empty contents', () {
      const result = (contents: <Object>[]);

      expect(result.contents, isEmpty);
    });
  });

  group('PromptMessage', () {
    test('creates user message', () {
      const message = (role: 'user', content: (type: 'text', text: 'Hello'));

      expect(message.role, equals('user'));
    });

    test('creates assistant message', () {
      const message = (
        role: 'assistant',
        content: (type: 'text', text: 'Hi there!'),
      );

      expect(message.role, equals('assistant'));
    });
  });

  group('GetPromptResult', () {
    test('creates with description and messages', () {
      final result = (
        description: 'A greeting prompt',
        messages: <PromptMessage>[
          (role: 'user', content: (type: 'text', text: 'Say hello to {name}')),
        ],
      );

      expect(result.description, equals('A greeting prompt'));
      expect(result.messages, hasLength(1));
    });

    test('creates without description', () {
      final result = (
        description: null,
        messages: <PromptMessage>[
          (role: 'assistant', content: (type: 'text', text: 'Response')),
        ],
      );

      expect(result.description, isNull);
      expect(result.messages, hasLength(1));
    });
  });

  group('ToolCallMeta', () {
    test('creates with progressToken', () {
      const meta = (progressToken: 'token-123');

      expect(meta.progressToken, equals('token-123'));
    });

    test('creates with null progressToken', () {
      const meta = (progressToken: null);

      expect(meta.progressToken, isNull);
    });
  });

  group('ResourceUpdatedParams', () {
    test('creates with uri', () {
      const params = (uri: 'file:///updated.txt');

      expect(params.uri, equals('file:///updated.txt'));
    });
  });

  group('JsonRpcMessage', () {
    test('creates request message', () {
      const message = (
        jsonrpc: '2.0',
        method: 'tools/call',
        params: {'name': 'echo'},
        id: 1,
        result: null,
        error: null,
      );

      expect(message.jsonrpc, equals('2.0'));
      expect(message.method, equals('tools/call'));
      expect(message.id, equals(1));
    });

    test('creates response message', () {
      const message = (
        jsonrpc: '2.0',
        method: null,
        params: null,
        id: 1,
        result: {'success': true},
        error: null,
      );

      expect(message.result, equals({'success': true}));
      expect(message.error, isNull);
    });

    test('creates error response', () {
      const message = (
        jsonrpc: '2.0',
        method: null,
        params: null,
        id: 1,
        result: null,
        error: {'code': -32600, 'message': 'Invalid Request'},
      );

      expect(message.error, isNotNull);
      expect(message.result, isNull);
    });
  });
}
