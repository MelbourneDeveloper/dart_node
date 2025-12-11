# dart_node_core

Core JS interop utilities for Dart-to-JavaScript compilation.

## Getting Started

```dart
import 'package:dart_node_core/dart_node_core.dart';

void main() {
  // Require a Node.js module
  final fs = requireModule('fs');

  // Convert Dart values to JS
  final jsString = 'hello'.toJS;

  // Work with JS objects
  final result = fs.callMethod('readFileSync'.toJS, ['./file.txt'.toJS]);
}
```

## Part of dart_node

[GitHub](https://github.com/MelbourneDeveloper/dart_node)
