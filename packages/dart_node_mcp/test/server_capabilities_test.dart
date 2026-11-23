// Server capabilities and configuration tests
// Tests all capability combinations and configuration options
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('ToolsCapability variations', () {
    test('with listChanged true', () {
      const capability = (listChanged: true);

      expect(capability.listChanged, isTrue);
    });

    test('with listChanged false', () {
      const capability = (listChanged: false);

      expect(capability.listChanged, isFalse);
    });

    test('with listChanged null', () {
      const capability = (listChanged: null);

      expect(capability.listChanged, isNull);
    });
  });

  group('ResourcesCapability variations', () {
    test('with both subscribe and listChanged true', () {
      const capability = (subscribe: true, listChanged: true);

      expect(capability.subscribe, isTrue);
      expect(capability.listChanged, isTrue);
    });

    test('with both subscribe and listChanged false', () {
      const capability = (subscribe: false, listChanged: false);

      expect(capability.subscribe, isFalse);
      expect(capability.listChanged, isFalse);
    });

    test('with subscribe true, listChanged false', () {
      const capability = (subscribe: true, listChanged: false);

      expect(capability.subscribe, isTrue);
      expect(capability.listChanged, isFalse);
    });

    test('with subscribe false, listChanged true', () {
      const capability = (subscribe: false, listChanged: true);

      expect(capability.subscribe, isFalse);
      expect(capability.listChanged, isTrue);
    });

    test('with both null', () {
      const capability = (subscribe: null, listChanged: null);

      expect(capability.subscribe, isNull);
      expect(capability.listChanged, isNull);
    });

    test('with only subscribe set', () {
      const capability = (subscribe: true, listChanged: null);

      expect(capability.subscribe, isTrue);
      expect(capability.listChanged, isNull);
    });

    test('with only listChanged set', () {
      const capability = (subscribe: null, listChanged: true);

      expect(capability.subscribe, isNull);
      expect(capability.listChanged, isTrue);
    });
  });

  group('PromptsCapability variations', () {
    test('with listChanged true', () {
      const capability = (listChanged: true);

      expect(capability.listChanged, isTrue);
    });

    test('with listChanged false', () {
      const capability = (listChanged: false);

      expect(capability.listChanged, isFalse);
    });

    test('with listChanged null', () {
      const capability = (listChanged: null);

      expect(capability.listChanged, isNull);
    });
  });

  group('LoggingCapability variations', () {
    test('with enabled true', () {
      const capability = (enabled: true);

      expect(capability.enabled, isTrue);
    });

    test('with enabled false', () {
      const capability = (enabled: false);

      expect(capability.enabled, isFalse);
    });

    test('with enabled null', () {
      const capability = (enabled: null);

      expect(capability.enabled, isNull);
    });
  });

  group('ServerCapabilities comprehensive combinations', () {
    test('all capabilities enabled', () {
      const capabilities = (
        tools: (listChanged: true),
        resources: (subscribe: true, listChanged: true),
        prompts: (listChanged: true),
        logging: (enabled: true),
      );

      expect(capabilities.tools.listChanged, isTrue);
      expect(capabilities.resources.subscribe, isTrue);
      expect(capabilities.resources.listChanged, isTrue);
      expect(capabilities.prompts.listChanged, isTrue);
      expect(capabilities.logging.enabled, isTrue);
    });

    test('all capabilities disabled', () {
      const capabilities = (
        tools: (listChanged: false),
        resources: (subscribe: false, listChanged: false),
        prompts: (listChanged: false),
        logging: (enabled: false),
      );

      expect(capabilities.tools.listChanged, isFalse);
      expect(capabilities.resources.subscribe, isFalse);
      expect(capabilities.resources.listChanged, isFalse);
      expect(capabilities.prompts.listChanged, isFalse);
      expect(capabilities.logging.enabled, isFalse);
    });

    test('all capabilities null', () {
      const capabilities = (
        tools: null,
        resources: null,
        prompts: null,
        logging: null,
      );

      expect(capabilities.tools, isNull);
      expect(capabilities.resources, isNull);
      expect(capabilities.prompts, isNull);
      expect(capabilities.logging, isNull);
    });

    test('mixed capability values', () {
      const capabilities = (
        tools: (listChanged: true),
        resources: (subscribe: false, listChanged: true),
        prompts: (listChanged: null),
        logging: null,
      );

      expect(capabilities.tools.listChanged, isTrue);
      expect(capabilities.resources.subscribe, isFalse);
      expect(capabilities.resources.listChanged, isTrue);
      expect(capabilities.prompts.listChanged, isNull);
      expect(capabilities.logging, isNull);
    });

    test('only tools capability', () {
      const capabilities = (
        tools: (listChanged: true),
        resources: null,
        prompts: null,
        logging: null,
      );

      expect(capabilities.tools, isNotNull);
      expect(capabilities.resources, isNull);
    });

    test('only resources capability', () {
      const capabilities = (
        tools: null,
        resources: (subscribe: true, listChanged: true),
        prompts: null,
        logging: null,
      );

      expect(capabilities.tools, isNull);
      expect(capabilities.resources, isNotNull);
    });

    test('only prompts capability', () {
      const capabilities = (
        tools: null,
        resources: null,
        prompts: (listChanged: true),
        logging: null,
      );

      expect(capabilities.prompts, isNotNull);
      expect(capabilities.logging, isNull);
    });

    test('only logging capability', () {
      const capabilities = (
        tools: null,
        resources: null,
        prompts: null,
        logging: (enabled: true),
      );

      expect(capabilities.logging, isNotNull);
      expect(capabilities.tools, isNull);
    });

    test('tools and resources only', () {
      const capabilities = (
        tools: (listChanged: true),
        resources: (subscribe: true, listChanged: true),
        prompts: null,
        logging: null,
      );

      expect(capabilities.tools, isNotNull);
      expect(capabilities.resources, isNotNull);
      expect(capabilities.prompts, isNull);
      expect(capabilities.logging, isNull);
    });

    test('prompts and logging only', () {
      const capabilities = (
        tools: null,
        resources: null,
        prompts: (listChanged: true),
        logging: (enabled: true),
      );

      expect(capabilities.tools, isNull);
      expect(capabilities.resources, isNull);
      expect(capabilities.prompts, isNotNull);
      expect(capabilities.logging, isNotNull);
    });
  });

  group('ServerOptions with various capability combinations', () {
    test('full options with all capabilities', () {
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: (subscribe: true, listChanged: true),
          prompts: (listChanged: true),
          logging: (enabled: true),
        ),
        instructions: 'Full server configuration',
      );

      const impl = (name: 'full-server', version: '1.0.0');
      final result = McpServer.create(impl, options: options);

      expect(result, isA<Result<McpServer, String>>());
    });

    test('capabilities without instructions', () {
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: null,
          prompts: null,
          logging: null,
        ),
        instructions: null,
      );

      const impl = (name: 'caps-only', version: '1.0.0');
      final result = McpServer.create(impl, options: options);

      expect(result, isA<Result<McpServer, String>>());
    });

    test('instructions without capabilities', () {
      const options = (capabilities: null, instructions: 'Instructions only');

      const impl = (name: 'instructions-only', version: '1.0.0');
      final result = McpServer.create(impl, options: options);

      expect(result, isA<Result<McpServer, String>>());
    });

    test('both null (minimal options)', () {
      const options = (capabilities: null, instructions: null);

      const impl = (name: 'minimal', version: '1.0.0');
      final result = McpServer.create(impl, options: options);

      expect(result, isA<Result<McpServer, String>>());
    });
  });

  group('Server creation with all capability permutations', () {
    test('resources with only subscribe', () {
      const options = (
        capabilities: (
          tools: null,
          resources: (subscribe: true, listChanged: null),
          prompts: null,
          logging: null,
        ),
        instructions: null,
      );

      const impl = (name: 'test', version: '1.0.0');
      final result = createServer(impl, options: options);

      expect(result, isA<Result<Server, String>>());
    });

    test('resources with only listChanged', () {
      const options = (
        capabilities: (
          tools: null,
          resources: (subscribe: null, listChanged: true),
          prompts: null,
          logging: null,
        ),
        instructions: null,
      );

      const impl = (name: 'test', version: '1.0.0');
      final result = createServer(impl, options: options);

      expect(result, isA<Result<Server, String>>());
    });

    test('resources with subscribe=false, listChanged=true', () {
      const options = (
        capabilities: (
          tools: null,
          resources: (subscribe: false, listChanged: true),
          prompts: null,
          logging: null,
        ),
        instructions: null,
      );

      const impl = (name: 'test', version: '1.0.0');
      final result = createServer(impl, options: options);

      expect(result, isA<Result<Server, String>>());
    });

    test('resources with subscribe=true, listChanged=false', () {
      const options = (
        capabilities: (
          tools: null,
          resources: (subscribe: true, listChanged: false),
          prompts: null,
          logging: null,
        ),
        instructions: null,
      );

      const impl = (name: 'test', version: '1.0.0');
      final result = createServer(impl, options: options);

      expect(result, isA<Result<Server, String>>());
    });
  });

  group('Implementation type variations', () {
    test('simple name and version', () {
      const impl = (name: 'server', version: '1.0.0');

      expect(impl.name, equals('server'));
      expect(impl.version, equals('1.0.0'));
    });

    test('scoped package name', () {
      const impl = (name: '@org/package', version: '2.3.4');

      expect(impl.name, equals('@org/package'));
      expect(impl.version, equals('2.3.4'));
    });

    test('version with prerelease', () {
      const impl = (name: 'beta-server', version: '1.0.0-beta.1');

      expect(impl.version, equals('1.0.0-beta.1'));
    });

    test('version with build metadata', () {
      const impl = (name: 'server', version: '1.0.0+20231215');

      expect(impl.version, equals('1.0.0+20231215'));
    });

    test('version with both prerelease and build', () {
      const impl = (name: 'server', version: '1.0.0-alpha.1+build.123');

      expect(impl.version, equals('1.0.0-alpha.1+build.123'));
    });

    test('minimal version', () {
      const impl = (name: 'v', version: '0.0.1');

      expect(impl.name, equals('v'));
      expect(impl.version, equals('0.0.1'));
    });

    test('major version only style', () {
      const impl = (name: 'server', version: '1');

      expect(impl.version, equals('1'));
    });
  });

  group('Capability integration tests', () {
    test('McpServer with tools capability enabled', () {
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: null,
          prompts: null,
          logging: null,
        ),
        instructions: 'Server with tools support',
      );

      const impl = (name: 'tool-server', version: '1.0.0');
      final result = McpServer.create(impl, options: options);

      switch (result) {
        case Success(:final value):
          expect(value, isA<McpServer>());
        case Error(:final error):
          expect(error, contains('Failed to create MCP server'));
      }
    });

    test('McpServer with resources capability enabled', () {
      const options = (
        capabilities: (
          tools: null,
          resources: (subscribe: true, listChanged: true),
          prompts: null,
          logging: null,
        ),
        instructions: 'Server with resources support',
      );

      const impl = (name: 'resource-server', version: '1.0.0');
      final result = McpServer.create(impl, options: options);

      expect(result, isA<Result<McpServer, String>>());
    });

    test('McpServer with prompts capability enabled', () {
      const options = (
        capabilities: (
          tools: null,
          resources: null,
          prompts: (listChanged: true),
          logging: null,
        ),
        instructions: 'Server with prompts support',
      );

      const impl = (name: 'prompt-server', version: '1.0.0');
      final result = McpServer.create(impl, options: options);

      expect(result, isA<Result<McpServer, String>>());
    });

    test('McpServer with logging capability enabled', () {
      const options = (
        capabilities: (
          tools: null,
          resources: null,
          prompts: null,
          logging: (enabled: true),
        ),
        instructions: 'Server with logging support',
      );

      const impl = (name: 'logging-server', version: '1.0.0');
      final result = McpServer.create(impl, options: options);

      expect(result, isA<Result<McpServer, String>>());
    });

    test('Server (low-level) with all capabilities', () {
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: (subscribe: true, listChanged: true),
          prompts: (listChanged: true),
          logging: (enabled: true),
        ),
        instructions: 'Low-level server with all capabilities',
      );

      const impl = (name: 'low-level', version: '1.0.0');
      final result = createServer(impl, options: options);

      expect(result, isA<Result<Server, String>>());
    });
  });

  group('Capability field access patterns', () {
    test('accessing tools capability fields', () {
      const capabilities = (
        tools: (listChanged: true),
        resources: null,
        prompts: null,
        logging: null,
      );

      final tools = capabilities.tools;
      expect(tools, isNotNull);
      expect(tools.listChanged, isTrue);
    });

    test('accessing resources capability fields', () {
      const capabilities = (
        tools: null,
        resources: (subscribe: true, listChanged: false),
        prompts: null,
        logging: null,
      );

      final resources = capabilities.resources;
      expect(resources, isNotNull);
      expect(resources.subscribe, isTrue);
      expect(resources.listChanged, isFalse);
    });

    test('accessing prompts capability fields', () {
      const capabilities = (
        tools: null,
        resources: null,
        prompts: (listChanged: false),
        logging: null,
      );

      final prompts = capabilities.prompts;
      expect(prompts, isNotNull);
      expect(prompts.listChanged, isFalse);
    });

    test('accessing logging capability fields', () {
      const capabilities = (
        tools: null,
        resources: null,
        prompts: null,
        logging: (enabled: false),
      );

      final logging = capabilities.logging;
      expect(logging, isNotNull);
      expect(logging.enabled, isFalse);
    });

    test('accessing null capability fields', () {
      const capabilities = (
        tools: null,
        resources: null,
        prompts: null,
        logging: null,
      );

      expect(capabilities.tools, isNull);
      expect(capabilities.resources, isNull);
      expect(capabilities.prompts, isNull);
      expect(capabilities.logging, isNull);
    });
  });

  group('ServerOptions field access patterns', () {
    test('accessing capabilities field', () {
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: null,
          prompts: null,
          logging: null,
        ),
        instructions: null,
      );

      expect(options.capabilities, isNotNull);
      expect(options.capabilities.tools.listChanged, isTrue);
    });

    test('accessing instructions field', () {
      const options = (capabilities: null, instructions: 'Test instructions');

      expect(options.instructions, equals('Test instructions'));
      expect(options.capabilities, isNull);
    });

    test('accessing both fields', () {
      const options = (
        capabilities: (
          tools: (listChanged: true),
          resources: null,
          prompts: null,
          logging: null,
        ),
        instructions: 'With both fields',
      );

      expect(options.capabilities, isNotNull);
      expect(options.instructions, isNotNull);
    });

    test('accessing null fields', () {
      const options = (capabilities: null, instructions: null);

      expect(options.capabilities, isNull);
      expect(options.instructions, isNull);
    });
  });
}
