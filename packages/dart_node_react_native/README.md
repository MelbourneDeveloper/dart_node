# dart_node_react_native

React Native bindings for Dart. Build mobile apps with Expo entirely in Dart.

## Getting Started

```dart
import 'package:dart_node_react_native/dart_node_react_native.dart';

void main() {
  final app = View(
    props: {'style': {'flex': 1, 'justifyContent': 'center'}},
    children: [
      Text(children: ['Hello from Dart!']),
      Button(
        props: {'title': 'Press me', 'onPress': () => print('Pressed!')},
      ),
    ],
  );

  registerComponent('App', () => app);
}
```

## Run

Use VSCode launch config `Mobile: Build & Run (Expo)` or:

```bash
dart compile js -o App.js lib/main.dart
npx expo start
```

## Part of dart_node

[GitHub](https://github.com/MelbourneDeveloper/dart_node)
