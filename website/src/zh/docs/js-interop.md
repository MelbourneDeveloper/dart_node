---
layout: layouts/docs.njk
title: JavaScript 互操作
description: 了解如何使用 dart:js_interop 从 Dart 调用 JavaScript 以及从 JavaScript 调用 Dart。
lang: zh
permalink: /zh/docs/js-interop/
eleventyNavigation:
  key: JS 互操作
  order: 4
---

Dart 3.3+ 提供 `dart:js_interop` 用于与 JavaScript 的无缝交互。这是 dart_node 封装 Express 和 React 等 npm 包的方式。

## 基础

### 导入 dart:js_interop

```dart
import 'dart:js_interop';
```

这提供了：
- JavaScript 对象的 extension types
- Dart 和 JS 之间的转换工具
- 用于 JS 绑定的 `external` 关键字

## 调用 JavaScript 函数

### 全局函数

```dart
import 'dart:js_interop';

// Declare the external function
@JS('console.log')
external void consoleLog(JSAny? message);

// Use it
void main() {
  consoleLog('Hello from Dart!'.toJS);
}
```

### 导入 npm 模块

```dart
import 'dart:js_interop';

// Require a Node.js module
@JS('require')
external JSObject require(String module);

void main() {
  final express = require('express');
  // Now you have the express module!
}
```

## Extension Types

Extension types 为 JavaScript 对象提供零成本包装。它们是 dart_node 类型化 API 的基础。

```dart
import 'dart:js_interop';

// Define an extension type for a JS object
extension type JSPerson._(JSObject _) implements JSObject {
  // Constructor
  external factory JSPerson({String name, int age});

  // Properties
  external String get name;
  external set name(String value);
  external int get age;

  // Methods
  external void greet();
}

void main() {
  final person = JSPerson(name: 'Alice', age: 30);
  print(person.name); // Access JS property
  person.greet();     // Call JS method
}
```

## 类型转换

### Dart 到 JavaScript

```dart
// Primitives
final jsString = 'hello'.toJS;           // JSString
final jsNumber = 42.toJS;                // JSNumber
final jsBool = true.toJS;                // JSBoolean

// Lists
final jsList = [1, 2, 3].toJS;           // JSArray

// Maps (as plain JS objects)
final jsObject = {'key': 'value'}.jsify(); // JSObject
```

### JavaScript 到 Dart

```dart
// Primitives
final dartString = jsString.toDart;      // String
final dartNumber = jsNumber.toDartInt;   // int
final dartBool = jsBool.toDart;          // bool

// Arrays
final dartList = jsList.toDart;          // List

// Objects (as Map)
final dartMap = jsObject.dartify();      // Map<String, dynamic>
```

## 处理回调

JavaScript 经常使用回调。以下是处理方式：

```dart
extension type EventEmitter._(JSObject _) implements JSObject {
  external void on(String event, JSFunction callback);
  external void emit(String event, JSAny? data);
}

void main() {
  final emitter = getEventEmitter();

  // Convert a Dart function to JS
  emitter.on('data', ((JSAny? data) {
    print('Received: ${data?.dartify()}');
  }).toJS);
}
```

## Promises 和 Futures

JavaScript Promises 转换为 Dart Futures：

```dart
extension type FetchAPI._(JSObject _) implements JSObject {
  external JSPromise<Response> fetch(String url);
}

Future<void> main() async {
  final api = getFetchAPI();

  // JSPromise converts to Future automatically
  final response = await api.fetch('https://api.example.com/data').toDart;
  print(response.status);
}
```

## dart_node 如何使用互操作

以下是 dart_node 封装 Express 的简化示例：

```dart
// Low-level JS binding
@JS('require')
external JSObject _require(String module);

// Extension type for Express app
extension type ExpressApp._(JSObject _) implements JSObject {
  external void get(String path, JSFunction handler);
  external void post(String path, JSFunction handler);
  external void listen(int port, JSFunction? callback);
}

// High-level Dart API
ExpressApp createExpressApp() {
  final express = _require('express');
  return (express as JSFunction).callAsFunction() as ExpressApp;
}

// Typed request handler
typedef RequestHandler = void Function(Request req, Response res);

// Convert Dart handler to JS
JSFunction wrapHandler(RequestHandler handler) {
  return ((JSObject req, JSObject res) {
    handler(Request._(req), Response._(res));
  }).toJS;
}

// Usage
void main() {
  final app = createExpressApp();

  app.get('/'.toJS, wrapHandler((req, res) {
    res.send('Hello!');
  }));

  app.listen(3000, null);
}
```

## 最佳实践

### 1. 在公共 API 中隐藏 JSObject

```dart
// Bad: Exposes raw JS types
class MyService {
  JSObject getData() => fetchData();
}

// Good: Returns Dart types
class MyService {
  Map<String, dynamic> getData() => fetchData().dartify();
}
```

### 2. 使用 Extension Types 保证类型安全

```dart
// Bad: Passing around raw JSObject
void processUser(JSObject user) {
  // What properties does user have? Who knows!
}

// Good: Typed extension type
void processUser(JSUser user) {
  print(user.name); // Compiler knows this exists
}
```

### 3. 谨慎处理 Null

JavaScript 的 `null` 和 `undefined` 都是有效的。使用 `JSAny?`：

```dart
extension type Config._(JSObject _) implements JSObject {
  external JSAny? get optionalValue;
}

void main() {
  final config = getConfig();

  // Check for null/undefined
  final value = config.optionalValue;
  if (value != null) {
    print(value.dartify());
  }
}
```

### 4. 在边界处验证

当 JavaScript 数据进入 Dart 代码时进行验证：

```dart
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  factory User.fromJS(JSObject obj) {
    final name = (obj['name'] as JSString?)?.toDart;
    final age = (obj['age'] as JSNumber?)?.toDartInt;

    if (name == null || age == null) {
      throw FormatException('Invalid user object');
    }

    return User(name: name, age: age);
  }
}
```

## 常用模式

### 封装构造函数

```dart
@JS('Date')
extension type JSDate._(JSObject _) implements JSObject {
  external factory JSDate();
  external factory JSDate.fromMilliseconds(int ms);
  external int getTime();
  external String toISOString();
}
```

### 封装静态方法

```dart
@JS('JSON')
extension type JSJSON._(JSObject _) implements JSObject {
  external static String stringify(JSAny? value);
  external static JSAny? parse(String text);
}
```

### 访问全局对象

```dart
@JS('window')
external JSObject get window;

@JS('document')
external JSObject get document;

@JS('globalThis')
external JSObject get globalThis;
```

## 调试技巧

1. **检查浏览器控制台** - JS 错误会显示在那里
2. **使用 source maps** - 直接调试 Dart 代码
3. **打印 JS 对象** - `consoleLog(jsObject)` 显示原始结构
4. **类型断言** - 谨慎使用 `as`；它可能隐藏错误

## 延伸阅读

- [官方 JS 互操作文档](https://dart.dev/interop/js-interop)
- [Extension Types](https://dart.dev/language/extension-types)
- [dart_node_core 源码](/zh/api/dart_node_core/) - 查看实际互操作示例
