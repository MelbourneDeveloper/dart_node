
`dart_node_core` is the foundation layer that all other dart_node packages build upon. It provides low-level JavaScript interop utilities, Node.js bindings, and console helpers.

## Installation

```yaml
dependencies:
  dart_node_core: ^0.11.0-beta
```

## Core Utilities

### Console Logging

```dart
import 'package:dart_node_core/dart_node_core.dart';

void main() {
  consoleLog('Hello, world!');           // stdout
  consoleError('Something went wrong');  // stderr
}
```

### Requiring Node.js Modules

```dart
import 'package:dart_node_core/dart_node_core.dart';

void main() {
  // Load a Node.js built-in module
  final fs = requireModule('fs');

  // Load an npm package
  final express = requireModule('express');
}
```

### Accessing Global Objects

```dart
import 'package:dart_node_core/dart_node_core.dart';

void main() {
  // Access global JavaScript objects
  final process = getGlobal('process');
}
```

## Interop Helpers

### Converting Between Dart and JavaScript

Uses `dart:js_interop` for type-safe conversions:

```dart
import 'dart:js_interop';

void main() {
  // Dart to JS
  final jsString = 'hello'.toJS;
  final jsNumber = 42.toJS;
  final jsList = [1, 2, 3].jsify();

  // JS to Dart
  final dartString = jsString.toDart;
}
```

## FP Extensions

Functional programming utilities:

```dart
import 'package:dart_node_core/dart_node_core.dart';

String? getName() => 'World';

void main() {
  // Pattern match on nullable values
  String? name = getName();
  final result = name.match(
    some: (n) => 'Hello, $n',
    none: () => 'No name provided',
  );

  // Apply transformations
  final length = 'hello'.let((s) => s.length);
}
```

## Source Code

The source code is available on [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_core).
