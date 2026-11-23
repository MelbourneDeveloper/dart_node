// Pure Dart callback tests - import only types and callbacks
// to avoid JS interop
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_mcp/src/types.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('ToolCallback', () {
    test('can be defined with correct signature', () {
      Future<CallToolResult> callback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async =>
          (content: <Object>[(type: 'text', text: 'result')], isError: false);

      // Verify callback can be assigned to ToolCallback type
      final typedCallback = callback;
      expect(typedCallback, isNotNull);
    });

    test('receives args correctly', () async {
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

      expect(result.content, hasLength(1));
      final textContent = result.content.first as TextContent;
      expect(textContent.text, equals('Echo: Hello'));
    });

    test('receives meta correctly', () async {
      String? receivedToken;

      Future<CallToolResult> callback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async {
        receivedToken = meta?.progressToken;
        return (content: <Object>[], isError: null);
      }

      await callback({}, (progressToken: 'token-xyz'));

      expect(receivedToken, equals('token-xyz'));
    });

    test('can return error result', () async {
      Future<CallToolResult> callback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async => (
        content: <Object>[(type: 'text', text: 'Something went wrong')],
        isError: true,
      );

      final result = await callback({}, null);

      expect(result.isError, isTrue);
    });

    test('can return multiple content items', () async {
      Future<CallToolResult> callback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async => (
        content: <Object>[
          (type: 'text', text: 'First'),
          (type: 'text', text: 'Second'),
          (type: 'image', data: 'base64==', mimeType: 'image/png'),
        ],
        isError: false,
      );

      final result = await callback({}, null);

      expect(result.content, hasLength(3));
    });

    test('handles complex args', () async {
      Future<CallToolResult> callback(
        Map<String, Object?> args,
        ToolCallMeta? meta,
      ) async {
        final nested = args['nested'] as Map<String, Object?>?;
        final list = args['list'] as List<Object?>?;
        return (
          content: <Object>[
            (
              type: 'text',
              text: 'Nested: ${nested?['key']}, List length: ${list?.length}',
            ),
          ],
          isError: false,
        );
      }

      final result = await callback({
        'nested': {'key': 'value'},
        'list': [1, 2, 3],
      }, null);

      final textContent = result.content.first as TextContent;
      expect(textContent.text, contains('Nested: value'));
      expect(textContent.text, contains('List length: 3'));
    });
  });

  group('ReadResourceCallback', () {
    test('can be defined with correct signature', () {
      Future<ReadResourceResult> callback(String uri) async =>
          (contents: <Object>[]);

      final typedCallback = callback;
      expect(typedCallback, isNotNull);
    });

    test('receives uri correctly', () async {
      String? receivedUri;

      Future<ReadResourceResult> callback(String uri) async {
        receivedUri = uri;
        return (
          contents: <Object>[
            (
              type: 'resource',
              uri: uri,
              mimeType: 'text/plain',
              text: 'Content',
            ),
          ],
        );
      }

      await callback('file:///test.txt');

      expect(receivedUri, equals('file:///test.txt'));
    });

    test('can return empty contents', () async {
      Future<ReadResourceResult> callback(String uri) async =>
          (contents: <Object>[]);

      final result = await callback('file:///empty');

      expect(result.contents, isEmpty);
    });

    test('can return multiple contents', () async {
      Future<ReadResourceResult> callback(String uri) async => (
        contents: <Object>[
          (type: 'text', text: 'Part 1'),
          (type: 'text', text: 'Part 2'),
        ],
      );

      final result = await callback('file:///multi');

      expect(result.contents, hasLength(2));
    });
  });

  group('ReadResourceTemplateCallback', () {
    test('can be defined with correct signature', () {
      Future<ReadResourceResult> callback(
        String uri,
        Map<String, String> variables,
      ) async => (contents: <Object>[]);

      final typedCallback = callback;
      expect(typedCallback, isNotNull);
    });

    test('receives uri and variables correctly', () async {
      String? receivedUri;
      Map<String, String>? receivedVariables;

      Future<ReadResourceResult> callback(
        String uri,
        Map<String, String> variables,
      ) async {
        receivedUri = uri;
        receivedVariables = variables;
        return (
          contents: <Object>[
            (
              type: 'resource',
              uri: uri,
              mimeType: null,
              text: 'Content for ${variables['id']}',
            ),
          ],
        );
      }

      await callback('db:///users/123', {'id': '123', 'table': 'users'});

      expect(receivedUri, equals('db:///users/123'));
      expect(receivedVariables, equals({'id': '123', 'table': 'users'}));
    });

    test('handles empty variables', () async {
      Future<ReadResourceResult> callback(
        String uri,
        Map<String, String> variables,
      ) async => (
        contents: <Object>[
          (type: 'text', text: 'Vars count: ${variables.length}'),
        ],
      );

      final result = await callback('simple:///path', {});

      final textContent = result.contents.first as TextContent;
      expect(textContent.text, equals('Vars count: 0'));
    });
  });

  group('PromptCallback', () {
    test('can be defined with correct signature', () {
      Future<GetPromptResult> callback(Map<String, String> args) async =>
          (description: null, messages: <PromptMessage>[]);

      final typedCallback = callback;
      expect(typedCallback, isNotNull);
    });

    test('receives args correctly', () async {
      Map<String, String>? receivedArgs;

      Future<GetPromptResult> callback(Map<String, String> args) async {
        receivedArgs = args;
        return (
          description: 'Greeting for ${args['name']}',
          messages: <PromptMessage>[
            (
              role: 'user',
              content: (type: 'text', text: 'Hello ${args['name']}'),
            ),
          ],
        );
      }

      await callback({'name': 'Alice', 'style': 'formal'});

      expect(receivedArgs, equals({'name': 'Alice', 'style': 'formal'}));
    });

    test('can return description', () async {
      Future<GetPromptResult> callback(Map<String, String> args) async => (
        description: 'This is a greeting prompt',
        messages: <PromptMessage>[
          (role: 'assistant', content: (type: 'text', text: 'Hello!')),
        ],
      );

      final result = await callback({});

      expect(result.description, equals('This is a greeting prompt'));
    });

    test('can return multiple messages', () async {
      Future<GetPromptResult> callback(Map<String, String> args) async => (
        description: null,
        messages: <PromptMessage>[
          (role: 'user', content: (type: 'text', text: 'Start')),
          (role: 'assistant', content: (type: 'text', text: 'Middle')),
          (role: 'user', content: (type: 'text', text: 'End')),
        ],
      );

      final result = await callback({});

      expect(result.messages, hasLength(3));
      expect(result.messages[0].role, equals('user'));
      expect(result.messages[1].role, equals('assistant'));
      expect(result.messages[2].role, equals('user'));
    });

    test('handles empty args', () async {
      Future<GetPromptResult> callback(Map<String, String> args) async => (
        description: 'No args provided',
        messages: <PromptMessage>[
          (
            role: 'assistant',
            content: (type: 'text', text: 'Default response'),
          ),
        ],
      );

      final result = await callback({});

      expect(result.description, equals('No args provided'));
    });
  });
}
