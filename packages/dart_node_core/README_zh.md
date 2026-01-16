
`dart_node_core` 是所有其他 dart_node 包的基础层。它提供底层 JavaScript 互操作工具、Node.js 绑定和控制台辅助功能。

## 安装

```yaml
dependencies:
  dart_node_core: ^0.11.0-beta
```

## 核心工具

### 控制台日志

```dart
import 'package:dart_node_core/dart_node_core.dart';

void main() {
  consoleLog('Hello, world!');           // 标准输出
  consoleError('Something went wrong');  // 标准错误输出
}
```

### 加载 Node.js 模块

```dart
import 'package:dart_node_core/dart_node_core.dart';

void main() {
  // 加载 Node.js 内置模块
  final fs = requireModule('fs');

  // 加载 npm 包
  final express = requireModule('express');
}
```

### 访问全局对象

```dart
import 'package:dart_node_core/dart_node_core.dart';

void main() {
  // 访问全局 JavaScript 对象
  final process = getGlobal('process');
}
```

## 互操作辅助工具

### Dart 和 JavaScript 之间的转换

使用 `dart:js_interop` 进行类型安全转换：

```dart
import 'dart:js_interop';

void main() {
  // Dart 转 JS
  final jsString = 'hello'.toJS;
  final jsNumber = 42.toJS;
  final jsList = [1, 2, 3].jsify();

  // JS 转 Dart
  final dartString = jsString.toDart;
}
```

## 函数式编程扩展

函数式编程工具：

```dart
import 'package:dart_node_core/dart_node_core.dart';

String? getName() => 'World';

void main() {
  // 对可空值进行模式匹配
  String? name = getName();
  final result = name.match(
    some: (n) => 'Hello, $n',
    none: () => 'No name provided',
  );

  // 应用转换
  final length = 'hello'.let((s) => s.length);
}
```

## 源代码

源代码可在 [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_core) 上获取。
