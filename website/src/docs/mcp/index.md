---
layout: layouts/docs.njk
title: dart_node_mcp
description: Model Context Protocol (MCP) bindings for building AI tool servers.
eleventyNavigation:
  key: dart_node_mcp
  parent: Packages
  order: 7
---

`dart_node_mcp` provides type-safe Dart bindings for the Model Context Protocol (MCP) SDK, enabling you to build MCP servers in Dart that run on Node.js.

## What is MCP?

The Model Context Protocol (MCP) is an open standard for connecting AI assistants to external data sources and tools. MCP servers expose:

- **Tools**: Functions that AI can call to perform actions
- **Resources**: Data sources that AI can read
- **Prompts**: Pre-defined prompt templates

## Installation

```yaml
dependencies:
  dart_node_mcp: ^0.2.0-beta
```

Also install the MCP SDK via npm:

```bash
npm install @modelcontextprotocol/sdk
```

## Quick Start

```dart
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';

Future<void> main() async {
  // Create server
  final serverResult = McpServer.create(
    (name: 'my-server', version: '1.0.0'),
  );

  final server = switch (serverResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  // Register a tool
  server.registerTool(
    'echo',
    (
      description: 'Echo the input message back',
      inputSchema: {
        'type': 'object',
        'properties': {
          'message': {'type': 'string', 'description': 'Message to echo'},
        },
        'required': ['message'],
      },
    ),
    (args, extra) async => (
      content: [
        (type: 'text', text: 'Echo: ${args['message']}'),
      ],
      isError: false,
    ),
  );

  // Create stdio transport and connect
  final transportResult = createStdioServerTransport();
  final transport = switch (transportResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  await server.connect(transport);
}
```

## Registering Tools

Tools are functions that AI assistants can invoke:

```dart
server.registerTool(
  'calculate',
  (
    description: 'Perform basic arithmetic',
    inputSchema: {
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
  ),
  (args, extra) async {
    final op = args['operation'] as String;
    final a = (args['a'] as num).toDouble();
    final b = (args['b'] as num).toDouble();

    final result = switch (op) {
      'add' => a + b,
      'subtract' => a - b,
      'multiply' => a * b,
      'divide' => b != 0 ? a / b : double.nan,
      _ => double.nan,
    };

    return (
      content: [(type: 'text', text: 'Result: $result')],
      isError: result.isNaN,
    );
  },
);
```

## Registering Resources

Resources provide data that AI can read:

```dart
server.registerResource(
  'config://app',
  (
    name: 'Application Config',
    description: 'Current application configuration',
    mimeType: 'application/json',
  ),
  (uri, extra) async => (
    contents: [
      (
        uri: uri,
        mimeType: 'application/json',
        text: '{"version": "1.0.0", "debug": false}',
      ),
    ],
  ),
);
```

## Registering Prompts

Prompts are reusable templates:

```dart
server.registerPrompt(
  'summarize',
  (
    description: 'Summarize the given text',
    arguments: [
      (name: 'text', description: 'Text to summarize', required: true),
      (name: 'style', description: 'Summary style', required: false),
    ],
  ),
  (args, extra) async => (
    messages: [
      (
        role: 'user',
        content: (
          type: 'text',
          text: 'Summarize this: ${args['text']}',
        ),
      ),
    ],
  ),
);
```

## Transport Options

### Stdio Transport

For command-line MCP servers:

```dart
final transportResult = createStdioServerTransport();
```

### Custom Streams

For testing or custom integrations:

```dart
final transportResult = createStdioServerTransportWithStreams(
  inputStream,
  outputStream,
);
```

## Error Handling

Return errors from tool handlers:

```dart
server.registerTool(
  'divide',
  (description: 'Divide two numbers', inputSchema: schema),
  (args, extra) async {
    final b = args['b'] as num;
    if (b == 0) {
      return (
        content: [(type: 'text', text: 'Error: Division by zero')],
        isError: true,
      );
    }
    final result = (args['a'] as num) / b;
    return (
      content: [(type: 'text', text: 'Result: $result')],
      isError: false,
    );
  },
);
```

## Complete Example: File System Server

```dart
import 'dart:io';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';

Future<void> main() async {
  final serverResult = McpServer.create(
    (name: 'filesystem-server', version: '1.0.0'),
  );

  final server = switch (serverResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  // Tool: List directory
  server.registerTool(
    'list_directory',
    (
      description: 'List files in a directory',
      inputSchema: {
        'type': 'object',
        'properties': {
          'path': {'type': 'string', 'description': 'Directory path'},
        },
        'required': ['path'],
      },
    ),
    (args, extra) async {
      final path = args['path'] as String;
      final dir = Directory(path);

      if (!await dir.exists()) {
        return (
          content: [(type: 'text', text: 'Directory not found: $path')],
          isError: true,
        );
      }

      final entries = await dir.list().map((e) => e.path).toList();
      return (
        content: [(type: 'text', text: entries.join('\n'))],
        isError: false,
      );
    },
  );

  // Tool: Read file
  server.registerTool(
    'read_file',
    (
      description: 'Read contents of a file',
      inputSchema: {
        'type': 'object',
        'properties': {
          'path': {'type': 'string', 'description': 'File path'},
        },
        'required': ['path'],
      },
    ),
    (args, extra) async {
      final path = args['path'] as String;
      final file = File(path);

      if (!await file.exists()) {
        return (
          content: [(type: 'text', text: 'File not found: $path')],
          isError: true,
        );
      }

      final content = await file.readAsString();
      return (
        content: [(type: 'text', text: content)],
        isError: false,
      );
    },
  );

  final transportResult = createStdioServerTransport();
  final transport = switch (transportResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  await server.connect(transport);
}
```

## Running Your Server

Compile and run with Node.js:

```bash
dart compile js -o server.js lib/main.dart
node server.js
```

## API Reference

See the [full API documentation](/api/dart_node_mcp/) for all available functions and types.
