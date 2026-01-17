
适用于 Node.js 上 Dart 的 MCP（模型上下文协议）服务器绑定。构建可供 Claude、GPT 和其他 AI 助手使用的 AI 工具服务器。

## 安装

```yaml
dependencies:
  dart_node_mcp: ^0.11.0-beta
  nadz: ^0.9.0
```

通过 npm 安装：

```bash
npm install @modelcontextprotocol/sdk
```

## 快速开始

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

## 核心概念

### 创建服务器

使用名称和版本创建 MCP 服务器：

```dart
final serverResult = McpServer.create((name: 'my-server', version: '1.0.0'));
```

### 注册工具

工具是 AI 助手可以调用的函数。使用名称、描述和处理程序注册它们：

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

### 传输

使用标准输入输出传输连接到客户端（MCP 标准方式）：

```dart
final transport = switch (createStdioServerTransport()) {
  Success(:final value) => value,
  Error(:final error) => throw Exception(error),
};

await server.connect(transport);
```

## 编译和运行

```bash
# 将 Dart 编译为 JavaScript
dart compile js -o server.js lib/main.dart

# 使用 Node.js 运行
node server.js
```

## 与 Claude Code 一起使用

将您的 MCP 服务器添加到 Claude Code：

```bash
claude mcp add --transport stdio my-server -- node /path/to/server.js
```

## 示例：Too Many Cooks

[Too Many Cooks](/zh/docs/too-many-cooks/) MCP 服务器是使用 dart_node_mcp 构建的。它为编辑同一代码库的 AI 助手提供多智能体协调功能。

## 源代码

源代码可在 [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_mcp) 上获取。
