---
layout: layouts/docs.njk
title: Dart 到 JavaScript 编译
description: 了解 dart2js 如何将 Dart 代码编译为 JavaScript，用于 Node.js 和浏览器环境。
lang: zh
permalink: /zh/docs/dart-to-js/
eleventyNavigation:
  key: Dart 到 JS
  order: 3
---

Dart 可以使用 `dart compile js`（也称为 dart2js）编译为 JavaScript。本指南介绍其工作原理以及如何与 dart_node 一起使用。

## 工作原理

Dart 编译器执行以下转换：

1. **类型检查** - 验证代码的类型安全性
2. **Tree shaking** - 移除未使用的代码
3. **代码压缩** - 减小输出大小（生产模式）
4. **优化** - 函数内联、常量折叠等

结果是可在任何 JS 环境运行的高效 JavaScript。

## 基本用法

```bash
# Compile a Dart file to JavaScript
dart compile js lib/main.dart -o build/main.js

# With optimizations for production
dart compile js lib/main.dart -o build/main.js -O2
```

## 优化级别

| 级别 | 说明 | 使用场景 |
|-------|-------------|----------|
| `-O0` | 无优化 | 调试 |
| `-O1` | 基本优化 | 开发 |
| `-O2` | 完全优化（默认） | 生产 |
| `-O3` | 激进优化 | 最高性能 |
| `-O4` | 最激进 | 对大小/速度要求严格时 |

## Node.js 兼容性

标准 dart2js 输出是为浏览器设计的。对于 Node.js，需要添加 preamble。`node_preamble` 包可以处理这个问题：

```dart
// In your build script
import 'package:node_preamble/preamble.dart' as preamble;

void main() {
  final dartOutput = File('build/app.dart.js').readAsStringSync();
  final nodeCompatible = '${preamble.getPreamble()}\n$dartOutput';
  File('build/app.js').writeAsStringSync(nodeCompatible);
}
```

或使用我们的构建工具（推荐）：

```bash
dart run tools/build/build.dart my_app
```

## 输出结构

编译后的 Dart 应用程序产生：

```
build/
├── main.js           # Main JavaScript output
├── main.js.deps      # Dependency information
└── main.js.map       # Source maps (for debugging)
```

## Source Maps

Source maps 可以在 JavaScript 环境中调试 Dart 代码：

```bash
# Generate with source maps (default)
dart compile js lib/main.dart -o build/main.js

# Disable source maps
dart compile js lib/main.dart -o build/main.js --no-source-maps
```

在 Node.js 中启用 source map 支持：

```bash
node --enable-source-maps build/main.js
```

## 延迟加载

将应用拆分为多个块以加快初始加载：

```dart
import 'heavy_feature.dart' deferred as heavy;

Future<void> loadFeature() async {
  await heavy.loadLibrary();
  heavy.runFeature();
}
```

这会创建按需加载的单独 `.part.js` 文件。

## 与 JavaScript 交互

Dart 可以调用 JavaScript，反之亦然。详情参见 [JS 互操作指南](/zh/docs/js-interop/)。

## 常见问题

### "Cannot find dart:html"

在 Node.js 中使用仅浏览器的库时会发生这种情况。解决方案：使用 `dart:js_interop` 代替 `dart:html`。

### 输出文件过大

对于小型应用，输出可能较大，因为 Dart 包含其运行时。对于生产环境：

```bash
dart compile js lib/main.dart -o build/main.js -O4
```

### Async/Await 问题

Dart 的 async/await 编译为 JavaScript promises。确保您的 Node.js 版本支持它们（Node 8+）。

## 构建脚本示例

以下是 dart_node 项目的完整构建脚本：

```dart
// tools/build.dart
import 'dart:io';
import 'package:node_preamble/preamble.dart' as preamble;

Future<void> main(List<String> args) async {
  final target = args.isNotEmpty ? args[0] : 'server';
  final inputFile = 'lib/$target.dart';
  final outputFile = 'build/$target.js';

  print('Compiling $inputFile...');

  // Run dart compile js
  final result = await Process.run('dart', [
    'compile', 'js',
    inputFile,
    '-o', '$outputFile.tmp',
    '-O2',
  ]);

  if (result.exitCode != 0) {
    print('Compilation failed:');
    print(result.stderr);
    exit(1);
  }

  // Add Node.js preamble
  final dartOutput = File('$outputFile.tmp').readAsStringSync();
  final nodeOutput = '${preamble.getPreamble()}\n$dartOutput';
  File(outputFile).writeAsStringSync(nodeOutput);

  // Cleanup
  File('$outputFile.tmp').deleteSync();

  print('Output: $outputFile');
  print('Run with: node $outputFile');
}
```

## 性能建议

1. **生产环境使用 `-O2` 或更高** - 显著改善大小和速度

2. **启用 tree shaking** - 确保没有导入未使用的代码

3. **避免 `dynamic`** - 编译器无法优化 dynamic 调用

4. **优先使用 `const`** - 常量值在编译时计算

5. **分析输出** - 检查 `.js.info` 文件了解大小分布：

```bash
dart compile js lib/main.dart -o build/main.js --dump-info
```

## 下一步

- [JS 互操作](/zh/docs/js-interop/) - 从 Dart 调用 JavaScript
- [dart_node_core](/zh/docs/core/) - Node.js 核心工具
- [dart_node_express](/zh/docs/express/) - 构建 Express 服务器
