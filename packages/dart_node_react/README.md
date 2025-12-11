# dart_node_react

React bindings for Dart. Build React web apps entirely in Dart.

## Getting Started

```dart
import 'package:dart_node_react/dart_node_react.dart';

void main() {
  final app = div(
    props: {'className': 'app'},
    children: [
      h1(children: ['Hello from Dart!']),
      button(
        props: {'onClick': () => print('Clicked!')},
        children: ['Click me'],
      ),
    ],
  );

  render(app, querySelector('#root'));
}
```

## Run

```bash
dart compile js -o app.js lib/main.dart
# Serve with your preferred static server
```

## Part of dart_node

[GitHub](https://github.com/MelbourneDeveloper/dart_node)
