
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
  consoleLog('Hello, world!');
  consoleError('Something went wrong');
  consoleWarn('This is a warning');
}
```

### Requiring Node.js Modules

```dart
import 'package:dart_node_core/dart_node_core.dart';

void main() {
  // Load a Node.js built-in module
  final fs = require('fs');

  // Load an npm package
  final express = require('express');
}
```

### Accessing Global Objects

```dart
import 'package:dart_node_core/dart_node_core.dart';

void main() {
  // Access global JavaScript objects
  final global = getGlobal('process');
  final env = global['env'];
}
```

## Interop Helpers

### Converting Between Dart and JavaScript

```dart
import 'package:dart_node_core/dart_node_core.dart';

void main() {
  // Dart to JS
  final jsString = 'hello'.toJS;
  final jsNumber = 42.toJS;
  final jsList = [1, 2, 3].toJS;

  // JS to Dart
  final dartString = jsString.toDart;
  final dartList = jsList.toDart;
}
```

## API Reference

See the [full API documentation](/api/dart_node_core/) for all available functions and types.

## Source Code

The source code is available on [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_core).
