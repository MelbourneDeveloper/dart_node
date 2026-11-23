# dart_node_mcp

MCP (Model Context Protocol) server bindings for Dart on Node.js.

## Getting Started

```dart
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';

Future<void> main() async {
  final serverResult = McpServer.create((name: 'my-server', version: '1.0.0'));

  final server = switch (serverResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  server.registerTool(
    'echo',
    (description: 'Echo input back', inputSchema: null),
    (args, meta) async => (
      content: [(type: 'text', text: args['message'] as String)],
      isError: false,
    ),
  );

  final transport = switch (createStdioServerTransport()) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  await server.connect(transport);
}
```

## Run

```bash
dart compile js -o server.js lib/main.dart
node server.js
```

## Part of [dart_node](https://github.com/MelbourneDeveloper/dart_node)
