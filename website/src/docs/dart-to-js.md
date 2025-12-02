---
layout: layouts/docs.njk
title: Dart to JavaScript Compilation
description: Learn how dart2js compiles Dart code to JavaScript for Node.js and browser environments.
eleventyNavigation:
  key: Dart to JS
  order: 3
---

Dart can compile to JavaScript using `dart compile js` (also known as dart2js). This guide explains how it works and how to use it with dart_node.

## How It Works

The Dart compiler performs several transformations:

1. **Type checking** - Verifies your code is type-safe
2. **Tree shaking** - Removes unused code
3. **Minification** - Reduces output size (in production mode)
4. **Optimization** - Inlines functions, constant folding, etc.

The result is efficient JavaScript that runs anywhere JS runs.

## Basic Usage

```bash
# Compile a Dart file to JavaScript
dart compile js lib/main.dart -o build/main.js

# With optimizations for production
dart compile js lib/main.dart -o build/main.js -O2
```

## Optimization Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| `-O0` | No optimization | Debugging |
| `-O1` | Basic optimization | Development |
| `-O2` | Full optimization (default) | Production |
| `-O3` | Aggressive optimization | Maximum performance |
| `-O4` | Most aggressive | When size/speed is critical |

## Node.js Compatibility

Standard dart2js output is designed for browsers. For Node.js, you need to add a preamble. The `node_preamble` package handles this:

```dart
// In your build script
import 'package:node_preamble/preamble.dart' as preamble;

void main() {
  final dartOutput = File('build/app.dart.js').readAsStringSync();
  final nodeCompatible = '${preamble.getPreamble()}\n$dartOutput';
  File('build/app.js').writeAsStringSync(nodeCompatible);
}
```

Or use our build tool (recommended):

```bash
dart run tools/build/build.dart my_app
```

## Output Structure

A compiled Dart application produces:

```
build/
├── main.js           # Main JavaScript output
├── main.js.deps      # Dependency information
└── main.js.map       # Source maps (for debugging)
```

## Source Maps

Source maps let you debug Dart code in JavaScript environments:

```bash
# Generate with source maps (default)
dart compile js lib/main.dart -o build/main.js

# Disable source maps
dart compile js lib/main.dart -o build/main.js --no-source-maps
```

In Node.js, enable source map support:

```bash
node --enable-source-maps build/main.js
```

## Deferred Loading

Split your app into multiple chunks for faster initial load:

```dart
import 'heavy_feature.dart' deferred as heavy;

Future<void> loadFeature() async {
  await heavy.loadLibrary();
  heavy.runFeature();
}
```

This creates separate `.part.js` files loaded on demand.

## Interacting with JavaScript

Dart can call JavaScript and vice versa. See the [JS Interop guide](/docs/js-interop/) for details.

## Common Issues

### "Cannot find dart:html"

This happens when using browser-only libraries in Node.js. Solution: use `dart:js_interop` instead of `dart:html`.

### Large Output Size

The output can be large for small apps because Dart includes its runtime. For production:

```bash
dart compile js lib/main.dart -o build/main.js -O4
```

### Async/Await Issues

Dart's async/await compiles to JavaScript promises. Ensure your Node.js version supports them (Node 8+).

## Build Script Example

Here's a complete build script for a dart_node project:

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

## Performance Tips

1. **Use `-O2` or higher for production** - Significant size and speed improvements

2. **Enable tree shaking** - Ensure you're not importing unused code

3. **Avoid `dynamic`** - The compiler can't optimize dynamic calls

4. **Prefer `const`** - Constant values are evaluated at compile time

5. **Profile your output** - Check the `.js.info` file for size breakdown:

```bash
dart compile js lib/main.dart -o build/main.js --dump-info
```

## Next Steps

- [JS Interop](/docs/js-interop/) - Call JavaScript from Dart
- [dart_node_core](/docs/core/) - Core utilities for Node.js
- [dart_node_express](/docs/express/) - Build Express servers
