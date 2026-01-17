---
layout: layouts/docs.njk
title: 为什么选择 Dart？
description: Dart 和 TypeScript 的对比。了解 Dart 的运行时类型安全和健全的空安全为何使其成为全栈开发的绝佳选择。
lang: zh
permalink: /zh/docs/why-dart/
eleventyNavigation:
  key: 为什么选择 Dart
  order: 2
---

如果您是 TypeScript 开发者，您已经了解类型的价值。Dart 通过 TypeScript 由于设计限制而无法提供的特性，将这种价值进一步提升。

如果您是 Flutter 开发者，您已经熟悉 Dart。现在您可以在整个 JavaScript 生态系统中使用它。

## TypeScript：出色的折中方案

TypeScript 是一项工程奇迹。它在不破坏与庞大 JS 生态系统兼容性的情况下，为 JavaScript 添加了静态类型。这是一个有意的选择 - 对于 TypeScript 的目标来说是正确的选择。

然而，这种选择伴随着在大型应用程序中变得明显的权衡。

## 类型擦除问题

TypeScript 类型仅在编译时存在。当您的代码运行时，它们就消失了。

```typescript
interface User {
  id: number;
  name: string;
  email: string;
}

// 这可以编译通过
const user: User = JSON.parse(apiResponse);

// 但在运行时，无法保证 `user` 匹配接口。
// 如果 API 返回 { id: "123", name: null }，TypeScript 无法帮助您。
console.log(user.name.toUpperCase()); // 如果 name 为 null 则运行时错误！
```

**Dart 在运行时保留类型：**

```dart
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,       // 如果类型错误立即失败
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

// 验证在边界处发生
final user = User.fromJson(jsonDecode(apiResponse));

// 如果我们到达这里，我们知道 user.name 是一个非空字符串
print(user.name.toUpperCase()); // 安全！
```

## 健全的空安全

TypeScript 有 `strictNullChecks`，这很好。但"严格"仍然允许逃生舱口。

```typescript
// TypeScript：! 运算符信任您（有时是错误的）
function processUser(user: User | null) {
  console.log(user!.name); // 您断言 user 不是 null
  // TypeScript 信任您。运行时可能不会。
}
```

**Dart 的空安全是健全的：**

```dart
// Dart：编译器确保这一点
void processUser(User? user) {
  print(user.name); // 编译错误！user 可能为 null

  // 您必须处理 null 情况
  if (user != null) {
    print(user.name); // 现在是安全的
  }

  // 或使用空感知运算符
  print(user?.name ?? '匿名');
}
```

Dart 中也存在 `!` 运算符，但在 null 值上使用它会立即抛出异常 - 您不能静默地继续未定义行为。

## 现实世界的影响

### 序列化

在 TypeScript 中，您通常需要 Zod 或 io-ts 等运行时验证库：

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  id: z.number(),
  name: z.string(),
  email: z.string().email(),
});

type User = z.infer<typeof UserSchema>;

// 您定义了两次结构：一次给 Zod，一次给 TypeScript
const user = UserSchema.parse(apiData);
```

在 Dart 中，类定义就是运行时验证：

```dart
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
  );
}

// 一个定义，同时用于类型和验证
final user = User.fromJson(apiData);
```

### 泛型

TypeScript 泛型被擦除：

```typescript
class Box<T> {
  constructor(public value: T) {}

  isString(): boolean {
    // 运行时无法检查 T 是否为 string！
    // typeof this.value === 'string' 检查的是值，而不是 T
    return typeof this.value === 'string';
  }
}
```

Dart 泛型在运行时存在：

```dart
class Box<T> {
  final T value;
  Box(this.value);

  bool isString() {
    // 我们可以检查实际的类型参数！
    return T == String;
  }

  // 更好：类型安全的操作
  R map<R>(R Function(T) fn) => fn(value);
}
```

## 一种语言，多个平台

使用 dart_node，您可以在任何地方编写 Dart：

| 平台 | TypeScript | Dart (dart_node) |
|------|-----------|------------------|
| 后端 | Node.js + TypeScript | dart_node_express |
| Web 前端 | React + TypeScript | dart_node_react |
| 移动端 | React Native + TypeScript | dart_node_react_native |
| 桌面端 | Electron + TypeScript | Flutter Desktop |

在所有平台之间共享模型、验证逻辑和业务规则 - 具有运行时类型安全。

## 更简单的构建流程

典型的 TypeScript 项目：

```
源码 → TypeScript 编译器 → Babel → Webpack/Rollup → 包
      (tsconfig.json)    (.babelrc) (webpack.config.js)
```

dart_node 项目：

```
源码 → dart compile js → 包
      (开箱即用)
```

没有配置迷宫。没有工具间的兼容性问题。一个命令。

## 对于 Flutter 开发者

如果您已经从 Flutter 了解 Dart，dart_node 为您打开了 JavaScript 生态系统：

- 使用庞大的 React 组件生态系统
- 访问 npm 包（数百万个）
- 部署到 Node.js 托管（比服务器端 Dart 更便宜）
- 使用熟悉的工具构建（相同的语言，相同的模式）

## 何时 TypeScript 更合适

在以下情况下，TypeScript 仍然是绝佳选择：

- 您正在处理现有的 JavaScript 代码库
- 您的团队深度投资于 TypeScript 生态系统
- 您需要与 JS 库的最大兼容性
- 您更喜欢 TypeScript 的结构类型而非 Dart 的名义类型

## 结论

Dart 和 TypeScript 都为动态语言添加了类型安全。TypeScript 选择了最大的 JavaScript 兼容性。Dart 选择了最大的类型安全。

对于运行时安全至关重要的新项目，Dart 提供了 TypeScript 无法提供的保证 - 不是因为 TypeScript 有缺陷，而是因为它是在不同的约束下设计的。

使用 dart_node，您可以两全其美：Dart 的类型安全加上 JavaScript 生态系统的访问。

---

准备好尝试了吗？[开始使用 dart_node](/zh/docs/getting-started/)
