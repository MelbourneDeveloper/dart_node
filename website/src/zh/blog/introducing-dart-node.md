---
layout: layouts/blog.njk
title: "dart_node 介绍：JavaScript 生态系统中的全栈 Dart"
description: "我们很高兴地宣布 dart_node，一个完全使用 Dart 构建 React、React Native 和 Express 应用程序的框架。"
date: 2024-01-15
author: "dart_node 团队"
lang: zh
permalink: /zh/blog/introducing-dart-node/
category: announcements
tags:
  - announcement
  - dart
  - react
  - express
---

今天，我们很高兴地介绍 **dart_node**，一个让你能够完全使用 Dart 构建 React、React Native 和 Express 应用程序的框架。

## 为什么选择 dart_node？

如果你是 **React 开发者**，你可能曾希望 TypeScript 的类型能在运行时存在。你可能与复杂的 webpack 配置斗争过。你可能疑惑过为什么仅仅启动一个项目就需要三个不同的配置文件。

如果你是 **Flutter 开发者**，你可能曾希望能在 Web 生态系统中使用你的 Dart 技能。你可能想要访问 React 庞大的组件库。你可能想要在 Flutter 应用和 React Native 版本之间共享代码。

dart_node 正是为你们两者而生。

## Dart 的独特之处

Dart 和 TypeScript 都为动态语言添加了类型安全。但它们做出了不同的设计选择：

**TypeScript 选择了最大化 JavaScript 兼容性。** 这是明智的——这意味着可以立即访问 npm 生态系统，并能在现有代码库中逐步采用。但这也有代价：类型在编译时被擦除。

**Dart 选择了最大化类型安全。** 类型在运行时存在。空安全是健全的。泛型不会被擦除。当你序列化一个对象时，你可以验证它的结构。当你反序列化时，你确切地知道你得到了什么。

这里有一个具体的例子：

```typescript
// TypeScript
interface User {
  name: string;
  age: number;
}

const user: User = JSON.parse(apiResponse);
// user 真的是 User 吗？我们只能希望如此！
console.log(user.name.toUpperCase());
// 如果 name 是 undefined，运行时会崩溃
```

```dart
// Dart
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json['name'] as String,  // 已验证！
    age: json['age'] as int,       // 已验证！
  );
}

final user = User.fromJson(jsonDecode(apiResponse));
// 如果执行到这里，user.name 一定是 String
print(user.name.toUpperCase());  // 安全！
```

这并不是说 TypeScript 不好——而是针对不同需求的不同权衡。

## dart_node 技术栈

我们构建了五个包，为你提供全栈能力：

### dart_node_core

基础层。提供 JavaScript 互操作工具、Node.js 绑定，以及将所有组件整合在一起的胶水代码。

### dart_node_express

类型安全的 Express.js 绑定。使用你熟悉的 Express 模式构建 REST API，同时享有 Dart 的类型安全。

```dart
import 'dart:js_interop';
import 'package:dart_node_express/dart_node_express.dart';

final app = express();

app.get('/users/:id', handler((req, res) {
  final id = req.params['id'];
  res.jsonMap({'user': {'id': id}});
}));

app.listen(3000, () {
  print('Server running on port 3000');
}.toJS);
```

### dart_node_react

带有 hooks、组件和类 JSX 语法的 React 绑定。你喜欢的 React 的一切，都在 Dart 中实现。

```dart
ReactElement counter() {
  final count = useState(0);

  return button(
    onClick: (_) => count.setWithUpdater((c) => c + 1),
    children: [text('Count: ${count.value}')],
  );
}
```

### dart_node_react_native

用于移动开发的 React Native 绑定。配合 Expo 使用，获得完整的移动开发体验。

```dart
ReactElement app() {
  return safeAreaView(children: [
    view(style: {'padding': 20}, children: [
      rnText(children: [text('Hello from Dart!')]),
    ]),
  ]);
}
```

### dart_node_ws

用于实时通信的 WebSocket 绑定。构建聊天应用、仪表盘等。

```dart
final server = createWebSocketServer(port: 8080);

server.onConnection((client, url) {
  client.onMessage((message) {
    client.send('Echo: ${message.text}');
  });
});
```

## 快速开始

入门非常简单：

```bash
mkdir my_app && cd my_app
dart create -t package .
dart pub add dart_node_core dart_node_express
```

编写你的服务器：

```dart
import 'dart:js_interop';
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = express();

  app.get('/', handler((req, res) {
    res.jsonMap({'message': 'Hello from Dart!'});
  }));

  app.listen(3000, () {
    print('Server running on port 3000');
  }.toJS);
}
```

编译并运行：

```bash
dart compile js lib/server.dart -o build/server.js
node build/server.js
```

就这样。不需要 webpack。不需要 babel。不需要复杂的配置。

## 适用人群

**React 开发者**：想要更好的类型安全，同时不失去熟悉的 React 模式。

**Flutter 开发者**：想要在 JavaScript 生态系统中使用 Dart 技能。

**全栈开发者**：想要在前端、后端和移动端之间共享代码。

**所有人**：厌倦了用三种不同的语言维护三个不同的代码库。

## 下一步计划

这只是开始。我们正在努力开发：

- 更多 React hooks 和组件绑定
- React Native 导航库
- 状态管理解决方案
- 构建工具改进
- 更多文档和示例

## 试一试

查看[入门指南](/zh/docs/getting-started/)来构建你的第一个 dart_node 应用程序。浏览 [API 文档](/zh/api/)查看可用功能。如果有问题，请在 GitHub 上提交 issue。

我们迫不及待想看到你的作品。

---

*dart_node 是开源的，采用 MIT 许可证。欢迎贡献！*
