// Pure Dart registered type tests - import only types to avoid JS interop
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_mcp/src/types.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('RegisteredTool', () {
    test('has correct structure', () {
      var removeCallCount = 0;
      ToolConfig? lastUpdateConfig;
      var enableCallCount = 0;
      var disableCallCount = 0;

      final tool = (
        name: 'test-tool',
        remove: () => removeCallCount++,
        update: (ToolConfig config) => lastUpdateConfig = config,
        enable: () => enableCallCount++,
        disable: () => disableCallCount++,
      );

      expect(tool.name, equals('test-tool'));

      // Test remove
      tool.remove();
      expect(removeCallCount, equals(1));

      // Test update
      const newConfig = (
        title: 'Updated',
        description: 'New description',
        inputSchema: null,
        outputSchema: null,
        annotations: null,
      );
      tool.update(newConfig);
      expect(lastUpdateConfig?.title, equals('Updated'));

      // Test enable
      tool.enable();
      expect(enableCallCount, equals(1));

      // Test disable
      tool.disable();
      expect(disableCallCount, equals(1));
    });

    test('remove can be called multiple times', () {
      var callCount = 0;
      final tool = (
        name: 'multi-remove',
        remove: () => callCount++,
        update: (ToolConfig _) {},
        enable: () {},
        disable: () {},
      );

      tool.remove();
      tool.remove();
      tool.remove();

      expect(callCount, equals(3));
    });

    test('update receives full config', () {
      ToolConfig? received;
      final tool = (
        name: 'config-test',
        remove: () {},
        update: (ToolConfig config) => received = config,
        enable: () {},
        disable: () {},
      );

      final fullConfig = (
        title: 'Full Config',
        description: 'Complete description',
        inputSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'arg': {'type': 'string'},
          },
        },
        outputSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'result': {'type': 'boolean'},
          },
        },
        annotations: (
          title: 'Annotated',
          readOnlyHint: true,
          destructiveHint: false,
          idempotentHint: true,
          openWorldHint: false,
        ),
      );

      tool.update(fullConfig);

      expect(received?.title, equals('Full Config'));
      expect(received?.description, equals('Complete description'));
      expect(received?.inputSchema, isNotNull);
      expect(received?.outputSchema, isNotNull);
      expect(received?.annotations?.readOnlyHint, isTrue);
    });
  });

  group('RegisteredResource', () {
    test('has correct structure', () {
      var removeCallCount = 0;
      ResourceMetadata? lastUpdateMetadata;

      final resource = (
        name: 'test-resource',
        uri: 'file:///test.txt',
        remove: () => removeCallCount++,
        update: (ResourceMetadata metadata) => lastUpdateMetadata = metadata,
      );

      expect(resource.name, equals('test-resource'));
      expect(resource.uri, equals('file:///test.txt'));

      // Test remove
      resource.remove();
      expect(removeCallCount, equals(1));

      // Test update
      const newMetadata = (
        description: 'Updated description',
        mimeType: 'application/json',
      );
      resource.update(newMetadata);
      expect(lastUpdateMetadata?.description, equals('Updated description'));
      expect(lastUpdateMetadata?.mimeType, equals('application/json'));
    });

    test('supports various URI schemes', () {
      final uris = [
        'file:///path/to/file.txt',
        'http://example.com/resource',
        'db:///users/123',
        'custom://scheme/path',
        's3://bucket/key',
      ];

      for (final uri in uris) {
        final resource = (
          name: 'resource-$uri',
          uri: uri,
          remove: () {},
          update: (ResourceMetadata _) {},
        );
        expect(resource.uri, equals(uri));
      }
    });

    test('update with minimal metadata', () {
      ResourceMetadata? received;
      final resource = (
        name: 'minimal',
        uri: 'test://uri',
        remove: () {},
        update: (ResourceMetadata metadata) => received = metadata,
      );

      const minimalMetadata = (description: null, mimeType: null);
      resource.update(minimalMetadata);

      expect(received?.description, isNull);
      expect(received?.mimeType, isNull);
    });
  });

  group('RegisteredResourceTemplate', () {
    test('has correct structure', () {
      var removeCallCount = 0;
      ResourceMetadata? lastUpdateMetadata;

      final template = (
        name: 'user-template',
        uriTemplate: 'db:///users/{userId}',
        remove: () => removeCallCount++,
        update: (ResourceMetadata metadata) => lastUpdateMetadata = metadata,
      );

      expect(template.name, equals('user-template'));
      expect(template.uriTemplate, equals('db:///users/{userId}'));

      // Test remove
      template.remove();
      expect(removeCallCount, equals(1));

      // Test update
      const newMetadata = (
        description: 'User resource',
        mimeType: 'application/json',
      );
      template.update(newMetadata);
      expect(lastUpdateMetadata?.description, equals('User resource'));
    });

    test('supports complex URI templates', () {
      final templates = [
        'file:///{path}',
        'db:///{table}/{id}',
        'api:///{version}/users/{userId}/posts/{postId}',
        's3:///{bucket}/{key*}',
        'http://example.com/api/{resource}{?query}',
      ];

      for (final uriTemplate in templates) {
        final template = (
          name: 'template',
          uriTemplate: uriTemplate,
          remove: () {},
          update: (ResourceMetadata _) {},
        );
        expect(template.uriTemplate, equals(uriTemplate));
      }
    });
  });

  group('RegisteredPrompt', () {
    test('has correct structure', () {
      var removeCallCount = 0;
      PromptConfig? lastUpdateConfig;

      final prompt = (
        name: 'greeting-prompt',
        remove: () => removeCallCount++,
        update: (PromptConfig config) => lastUpdateConfig = config,
      );

      expect(prompt.name, equals('greeting-prompt'));

      // Test remove
      prompt.remove();
      expect(removeCallCount, equals(1));

      // Test update
      final newConfig = (
        title: 'Greeting',
        description: 'Generates a greeting',
        argsSchema: <String, Object?>{
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
        },
      );
      prompt.update(newConfig);
      expect(lastUpdateConfig?.title, equals('Greeting'));
      expect(lastUpdateConfig?.description, equals('Generates a greeting'));
    });

    test('update with minimal config', () {
      PromptConfig? received;
      final prompt = (
        name: 'minimal-prompt',
        remove: () {},
        update: (PromptConfig config) => received = config,
      );

      const minimalConfig = (title: null, description: null, argsSchema: null);
      prompt.update(minimalConfig);

      expect(received?.title, isNull);
      expect(received?.description, isNull);
      expect(received?.argsSchema, isNull);
    });

    test('supports various prompt names', () {
      final names = [
        'simple',
        'with-dashes',
        'with_underscores',
        'CamelCase',
        'with.dots',
        'namespace:prompt',
      ];

      for (final name in names) {
        final prompt = (name: name, remove: () {}, update: (PromptConfig _) {});
        expect(prompt.name, equals(name));
      }
    });
  });

  group('Registered type assignment', () {
    test('RegisteredTool can be assigned to variable', () {
      final tool = (
        name: 'typed-tool',
        remove: () {},
        update: (ToolConfig _) {},
        enable: () {},
        disable: () {},
      );

      expect(tool.name, equals('typed-tool'));
    });

    test('RegisteredResource can be assigned to variable', () {
      final resource = (
        name: 'typed-resource',
        uri: 'test://uri',
        remove: () {},
        update: (ResourceMetadata _) {},
      );

      expect(resource.name, equals('typed-resource'));
    });

    test('RegisteredResourceTemplate can be assigned to variable', () {
      final template = (
        name: 'typed-template',
        uriTemplate: 'test:///{id}',
        remove: () {},
        update: (ResourceMetadata _) {},
      );

      expect(template.name, equals('typed-template'));
    });

    test('RegisteredPrompt can be assigned to variable', () {
      final prompt = (
        name: 'typed-prompt',
        remove: () {},
        update: (PromptConfig _) {},
      );

      expect(prompt.name, equals('typed-prompt'));
    });
  });
}
