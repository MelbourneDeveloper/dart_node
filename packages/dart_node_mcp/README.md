
MCP (Model Context Protocol) server bindings for Dart on Node.js. Build AI tool servers that can be used by Claude, GPT, and other AI assistants.

## Installation

```yaml
dependencies:
  dart_node_mcp: ^0.13.0-beta
  nadz: ^0.0.7-beta
```

Also install the npm package:

```bash
npm install @modelcontextprotocol/sdk
```

## Quick Start

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
    (
      title: null,
      description: 'Echo input back',
      inputSchema: null,
      outputSchema: null,
      annotations: null,
    ),
    (args, meta) async => (
      content: <Map<String, Object?>>[
        {'type': 'text', 'text': args['message'] as String},
      ],
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

## Core Concepts

### Server Creation

Create an MCP server with a name and version:

```dart
final serverResult = McpServer.create((name: 'my-server', version: '1.0.0'));
```

### Registering Tools

Tools are functions that AI assistants can call. Register them with a name, description, and handler:

```dart
server.registerTool(
  'greet',
  (
    title: null,
    description: 'Greet a user by name',
    inputSchema: {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': 'Name to greet'},
      },
      'required': ['name'],
    },
    outputSchema: null,
    annotations: null,
  ),
  (args, meta) async {
    final name = args['name'] as String;
    return (
      content: <Map<String, Object?>>[
        {'type': 'text', 'text': 'Hello, $name!'},
      ],
      isError: false,
    );
  },
);
```

### Transport

Connect to clients using stdio transport (standard for MCP):

```dart
final transport = switch (createStdioServerTransport()) {
  Success(:final value) => value,
  Error(:final error) => throw Exception(error),
};

await server.connect(transport);
```

## Compile and Run

```bash
# Compile Dart to JavaScript
dart compile js -o server.js lib/main.dart

# Run with Node.js
node server.js
```

## Use with Claude Code

Add your MCP server to Claude Code:

```bash
claude mcp add --transport stdio my-server -- node /path/to/server.js
```

## Built with dart_node_mcp: Too Many Cooks

[Too Many Cooks](https://tmc-mcp.dev) is an MCP server originally built with dart_node_mcp that provides multi-agent coordination for AI assistants editing the same codebase. It has since moved to its own home at [tmc-mcp.dev](https://tmc-mcp.dev) and is no longer part of this repository.

## Source Code

The source code is available on [GitHub](https://github.com/MelbourneDeveloper/dart_node/tree/main/packages/dart_node_mcp).
