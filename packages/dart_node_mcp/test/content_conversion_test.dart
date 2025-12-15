// Content conversion and edge case tests
// Tests content types, error handling, and conversion utilities
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('Content types', () {
    test('TextContent with all fields', () {
      const content = (type: 'text', text: 'Sample text content');

      expect(content.type, equals('text'));
      expect(content.text, equals('Sample text content'));
    });

    test('TextContent with special characters', () {
      const content = (type: 'text', text: 'Text with\nnewlines\tand\ttabs');

      expect(content.text, contains('\n'));
      expect(content.text, contains('\t'));
    });

    test('TextContent with unicode', () {
      const content = (type: 'text', text: 'Unicode: 你好 🚀 مرحبا');

      expect(content.text, contains('你好'));
      expect(content.text, contains('🚀'));
    });

    test('ImageContent with base64 data', () {
      const content = (
        type: 'image',
        // cspell:disable
        data:
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklE'
            'QVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
        // cspell:enable
        mimeType: 'image/png',
      );

      expect(content.type, equals('image'));
      expect(content.mimeType, equals('image/png'));
      expect(content.data.length, greaterThan(0));
    });

    test('ImageContent with different mime types', () {
      final imageTypes = [
        'image/png',
        'image/jpeg',
        'image/gif',
        'image/webp',
        'image/svg+xml',
      ];

      for (final mimeType in imageTypes) {
        final content = (type: 'image', data: 'base64data', mimeType: mimeType);
        expect(content.mimeType, equals(mimeType));
      }
    });

    test('ResourceContent with all fields', () {
      const content = (
        type: 'resource',
        uri: 'file:///path/to/resource.json',
        mimeType: 'application/json',
        text: '{"key": "value"}',
      );

      expect(content.type, equals('resource'));
      expect(content.uri, equals('file:///path/to/resource.json'));
      expect(content.mimeType, equals('application/json'));
      expect(content.text, equals('{"key": "value"}'));
    });

    test('ResourceContent with minimal fields', () {
      const content = (
        type: 'resource',
        uri: 'https://example.com/data',
        mimeType: null,
        text: null,
      );

      expect(content.uri, equals('https://example.com/data'));
      expect(content.mimeType, isNull);
      expect(content.text, isNull);
    });

    test('ResourceContent with various URI schemes', () {
      final uriSchemes = [
        'file:///local/file.txt',
        'https://example.com/resource',
        'http://api.example.com/data',
        'ftp://files.example.com/doc.pdf',
        'db:///database/table/row',
        'custom://scheme/path',
      ];

      for (final uri in uriSchemes) {
        final content = (
          type: 'resource',
          uri: uri,
          mimeType: null,
          text: null,
        );
        expect(content.uri, equals(uri));
      }
    });
  });

  group('CallToolResult variations', () {
    test('success result with single text content', () {
      final result = (
        content: <Object>[
          {'type': 'text', 'text': 'Success'},
        ],
        isError: false,
      );

      expect(result.content, hasLength(1));
      expect(result.isError, isFalse);
    });

    test('success result with multiple content items', () {
      final result = (
        content: <Object>[
          {'type': 'text', 'text': 'First'},
          {'type': 'text', 'text': 'Second'},
          {'type': 'text', 'text': 'Third'},
        ],
        isError: false,
      );

      expect(result.content, hasLength(3));
    });

    test('success result with mixed content types', () {
      final result = (
        content: <Object>[
          {'type': 'text', 'text': 'Description'},
          {'type': 'image', 'data': 'base64', 'mimeType': 'image/png'},
          {
            'type': 'resource',
            'uri': 'file:///data.json',
            'mimeType': null,
            'text': null,
          },
        ],
        isError: false,
      );

      expect(result.content, hasLength(3));
    });

    test('error result with error message', () {
      final result = (
        content: <Object>[
          {'type': 'text', 'text': 'Error: File not found'},
        ],
        isError: true,
      );

      expect(result.isError, isTrue);
    });

    test('result with null isError field', () {
      final result = (
        content: <Object>[
          {'type': 'text', 'text': 'No error specified'},
        ],
        isError: null,
      );

      expect(result.isError, isNull);
    });

    test('result with empty content list', () {
      const result = (content: <Object>[], isError: false);

      expect(result.content, isEmpty);
    });
  });

  group('ReadResourceResult variations', () {
    test('single resource content', () {
      final result = (
        contents: <Object>[
          {
            'type': 'resource',
            'uri': 'file:///data',
            'text': 'content',
            'mimeType': null,
          },
        ],
      );

      expect(result.contents, hasLength(1));
    });

    test('multiple resource contents', () {
      final result = (
        contents: <Object>[
          {'type': 'text', 'text': 'Header'},
          {
            'type': 'resource',
            'uri': 'file:///data1',
            'text': 'data1',
            'mimeType': null,
          },
          {
            'type': 'resource',
            'uri': 'file:///data2',
            'text': 'data2',
            'mimeType': null,
          },
        ],
      );

      expect(result.contents, hasLength(3));
    });

    test('empty contents list', () {
      const result = (contents: <Object>[]);

      expect(result.contents, isEmpty);
    });
  });

  group('GetPromptResult variations', () {
    test('with description', () {
      final result = (
        description: 'A helpful prompt',
        messages: <PromptMessage>[
          (role: 'user', content: {'type': 'text', 'text': 'Hello'}),
        ],
      );

      expect(result.description, equals('A helpful prompt'));
      expect(result.messages, hasLength(1));
    });

    test('without description', () {
      final result = (
        description: null,
        messages: <PromptMessage>[
          (role: 'user', content: {'type': 'text', 'text': 'Hello'}),
        ],
      );

      expect(result.description, isNull);
    });

    test('with multiple messages', () {
      final result = (
        description: 'Conversation',
        messages: <PromptMessage>[
          (role: 'user', content: {'type': 'text', 'text': 'Question'}),
          (role: 'assistant', content: {'type': 'text', 'text': 'Answer'}),
          (role: 'user', content: {'type': 'text', 'text': 'Follow-up'}),
        ],
      );

      expect(result.messages, hasLength(3));
    });

    test('with different role types', () {
      final roles = ['user', 'assistant', 'system'];

      for (final role in roles) {
        final message = (
          role: role,
          content: {'type': 'text', 'text': 'Message'},
        );
        expect(message.role, equals(role));
      }
    });
  });

  group('ToolCallMeta variations', () {
    test('with progress token', () {
      const meta = (progressToken: 'token-123');

      expect(meta.progressToken, equals('token-123'));
    });

    test('without progress token', () {
      const meta = (progressToken: null);

      expect(meta.progressToken, isNull);
    });

    test('with various token formats', () {
      final tokens = [
        'simple',
        'uuid-12345678-1234-1234-1234-123456789abc',
        'prefix:suffix',
        '12345',
      ];

      for (final token in tokens) {
        final meta = (progressToken: token);
        expect(meta.progressToken, equals(token));
      }
    });
  });

  group('ResourceUpdatedParams', () {
    test('with file URI', () {
      const params = (uri: 'file:///config.json');

      expect(params.uri, equals('file:///config.json'));
    });

    test('with HTTP URI', () {
      const params = (uri: 'https://example.com/data');

      expect(params.uri, equals('https://example.com/data'));
    });

    test('with custom scheme', () {
      const params = (uri: 'db:///users/123');

      expect(params.uri, equals('db:///users/123'));
    });
  });

  group('Edge cases and complex scenarios', () {
    test('nested content in prompt messages', () {
      final result = (
        description: 'Complex prompt',
        messages: <PromptMessage>[
          (
            role: 'user',
            content: {
              'type': 'text',
              'text':
                  'Complex\nmultiline\ntext\nwith\nspecial\nchars: @#\$%^&*()',
            },
          ),
        ],
      );

      final message = result.messages.first;
      final content = message.content as Map<String, Object?>;
      expect(content['text'], contains('\n'));
    });

    test('tool result with large content list', () {
      final largeContentList = List.generate(
        100,
        (i) => {'type': 'text', 'text': 'Item $i'},
      );

      final result = (content: largeContentList, isError: false);

      expect(result.content, hasLength(100));
    });

    test('resource with very long URI', () {
      const content = (
        type: 'resource',
        uri: 'file:///very/long/path/to/resource/file.txt',
        mimeType: null,
        text: null,
      );

      expect(content.uri.length, greaterThan(20));
    });

    test('content with empty strings', () {
      const content = (type: 'text', text: '');

      expect(content.text, isEmpty);
    });

    test('image content with large base64 string', () {
      final largeData = 'A' * 10000;
      final content = (type: 'image', data: largeData, mimeType: 'image/png');

      expect(content.data.length, equals(10000));
    });
  });

  group('Callback type signatures', () {
    test('ToolCallback with complex args and meta', () async {
      Future<CallToolResult> callback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async {
        final processedArgs = <String, Object?>{};
        for (final entry in args.entries) {
          processedArgs[entry.key] = entry.value;
        }

        return (
          content: <Object>[
            {
              'type': 'text',
              'text':
                  'Processed ${processedArgs.length} args, '
                  'token: ${meta?.progressToken ?? "none"}',
            },
          ],
          isError: false,
        );
      }

      final result = await callback(
        {'a': 1, 'b': 'two', 'c': true},
        (progressToken: 'test-token'),
      );

      final content = result.content.first as Map<String, Object?>;
      expect(content['text'], contains('Processed 3 args'));
      expect(content['text'], contains('test-token'));
    });

    test('ReadResourceCallback with error handling', () async {
      Future<ReadResourceResult> callback(String uri) async {
        if (uri.isEmpty) {
          return (
            contents: <Object>[
              {'type': 'text', 'text': 'Error: Empty URI'},
            ],
          );
        }

        return (
          contents: <Object>[
            {
              'type': 'resource',
              'uri': uri,
              'text': 'content',
              'mimeType': null,
            },
          ],
        );
      }

      final emptyResult = await callback('');
      expect(emptyResult.contents, hasLength(1));

      final validResult = await callback('file:///data');
      expect(validResult.contents, hasLength(1));
    });

    test('ReadResourceTemplateCallback with variables', () async {
      Future<ReadResourceResult> callback(
        String uri,
        Map<String, String> variables,
      ) async {
        final varCount = variables.length;

        return (
          contents: <Object>[
            {'type': 'text', 'text': 'URI: $uri, Variables: $varCount'},
          ],
        );
      }

      final result = await callback('db:///users/123', {
        'userId': '123',
        'filter': 'active',
      });

      final content = result.contents.first as Map<String, Object?>;
      expect(content['text'], contains('Variables: 2'));
    });

    test('PromptCallback with args processing', () async {
      Future<GetPromptResult> callback(Map<String, String> args) async {
        final name = args['name'] ?? 'User';
        final tone = args['tone'] ?? 'neutral';

        return (
          description: 'Prompt for $name in $tone tone',
          messages: <PromptMessage>[
            (
              role: 'assistant',
              content: {'type': 'text', 'text': 'Response for $name'},
            ),
          ],
        );
      }

      final result = await callback({'name': 'Alice', 'tone': 'friendly'});

      expect(result.description, contains('Alice'));
      expect(result.description, contains('friendly'));
    });
  });

  group('Content as Map format', () {
    test('text content as Map', () {
      final content = <String, Object?>{'type': 'text', 'text': 'Hello world'};

      expect(content['type'], equals('text'));
      expect(content['text'], equals('Hello world'));
    });

    test('image content as Map', () {
      final content = <String, Object?>{
        'type': 'image',
        'data': 'base64data',
        'mimeType': 'image/png',
      };

      expect(content['type'], equals('image'));
      expect(content['data'], equals('base64data'));
      expect(content['mimeType'], equals('image/png'));
    });

    test('resource content as Map', () {
      final content = <String, Object?>{
        'type': 'resource',
        'uri': 'file:///data.json',
        'mimeType': 'application/json',
        'text': '{"key": "value"}',
      };

      expect(content['type'], equals('resource'));
      expect(content['uri'], equals('file:///data.json'));
    });

    test('CallToolResult with Map content items', () {
      final result = (
        content: <Object>[
          <String, Object?>{'type': 'text', 'text': 'First item'},
          <String, Object?>{'type': 'text', 'text': 'Second item'},
        ],
        isError: false,
      );

      expect(result.content, hasLength(2));
      final first = result.content[0] as Map<String, Object?>;
      expect(first['text'], equals('First item'));
    });
  });
}
