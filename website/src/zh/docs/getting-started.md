---
layout: layouts/docs.njk
title: 快速开始
description: 几分钟内开始使用 dart_node。构建 Express 服务器、React 应用和 React Native 移动应用 - 全部使用 Dart。
lang: zh
permalink: /zh/docs/getting-started/
eleventyNavigation:
  key: 快速开始
  order: 1
---

欢迎使用 dart_node！本指南将帮助您使用 Dart 构建第一个 JavaScript 生态系统应用程序。

## 前置条件

开始之前，请确保您已安装：

- **Dart SDK**（3.10 或更高版本）- [安装 Dart](https://dart.dev/get-dart)
- **Node.js**（18 或更高版本）- [安装 Node.js](https://nodejs.org/)
- 代码编辑器（推荐使用带 Dart 扩展的 VS Code）

## 快速开始：Express 服务器

让我们用 Dart 构建一个简单的 REST API 服务器。

### 1. 创建新项目

```bash
mkdir my_dart_server
cd my_dart_server
dart create -t package .
```

### 2. 添加依赖

编辑您的 `pubspec.yaml`：

```yaml
name: my_dart_server
environment:
  sdk: ^3.10.0

dependencies:
  dart_node_core: ^0.11.0-beta
  dart_node_express: ^0.11.0-beta
```

然后运行：

```bash
dart pub get
```

### 3. 编写您的服务器

创建 `lib/server.dart`：

```dart
import 'dart:js_interop';
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = express();

  // 简单的 GET 端点
  app.get('/', handler((req, res) {
    res.jsonMap({
      'message': '来自 Dart 的问候！',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }));

  // POST 端点 - Express 的 JSON 中间件必须从 JS 使用
  // 配置 express.json() 后，body 可通过 req.body 获取

  app.post('/users', handler((req, res) {
    final body = req.body;
    res.status(201);
    res.jsonMap({
      'created': true,
      'user': body,
    });
  }));

  // 启动服务器
  app.listen(3000, () {
    print('服务器运行在 http://localhost:3000');
  }.toJS);
}
```

### 4. 编译并运行

```bash
# 将 Dart 编译为 JavaScript
dart compile js lib/server.dart -o build/server.js

# 使用 Node.js 运行
node build/server.js
```

访问 `http://localhost:3000` 查看您的服务器运行效果！

## 项目结构

典型的 dart_node 项目结构如下：

```
my_project/
├── lib/
│   ├── server.dart       # 入口点
│   ├── routes/           # 路由处理器
│   ├── models/           # 数据模型
│   └── services/         # 业务逻辑
├── build/                # 编译后的 JS 输出
├── pubspec.yaml          # Dart 依赖
├── package.json          # Node 依赖（用于 npm 包）
└── README.md
```

## 使用 npm 包

某些 dart_node 包封装了 npm 模块（如 Express）。您需要安装这些：

```bash
npm init -y
npm install express
```

Dart 代码在运行时使用 JS 互操作来调用这些 npm 包。

## 后续步骤

现在您已经有了一个基本的服务器运行，继续探索：

- [为什么选择 Dart？](/zh/docs/why-dart/) - 了解相对于 TypeScript 的优势
- [Dart 到 JS 编译](/docs/dart-to-js/) - dart2js 的工作原理
- [JS 互操作](/docs/js-interop/) - 从 Dart 调用 JavaScript
- [dart_node_express](/docs/express/) - 完整的 Express.js API 参考

## 示例项目

查看 [示例目录](https://github.com/melbournedeveloper/dart_node/tree/main/examples) 获取完整的工作应用程序：

- **backend/** - 带 REST API 的 Express 服务器
- **frontend/** - React Web 应用程序
- **mobile/** - React Native + Expo 移动应用
