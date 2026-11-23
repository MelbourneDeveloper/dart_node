---
layout: layouts/docs.njk
title: dart_node_mcp
description: MCP (Model Context Protocol) server bindings for Dart on Node.js. Build AI tool servers in Dart.
eleventyNavigation:
  key: dart_node_mcp
  parent: Packages
  order: 7
---

MCP (Model Context Protocol) server bindings for Dart on Node.js. Build AI tool servers that can be used by Claude, GPT, and other AI assistants.

## Installation

```yaml
dependencies:
  dart_node_mcp: ^0.2.0
  nadz: ^0.9.0
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
    description: 'Greet a user by name',
    inputSchema: {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': 'Name to greet'},
      },
      'required': ['name'],
    },
  ),
  (args, meta) async {
    final name = args['name'] as String;
    return (
      content: [(type: 'text', text: 'Hello, $name!')],
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

## Example: Too Many Cooks

The [Too Many Cooks](/docs/too-many-cooks/) MCP server is built with dart_node_mcp. It provides multi-agent coordination for AI assistants editing the same codebase.

## Source Code

The source code is available on [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_mcp).
