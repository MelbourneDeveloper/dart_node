# Dart JS Framework

## Vision
A framework that enables building JavaScript applications entirely in Dart using the standard Dart-to-JS transpiler.

Critical reading: https://dart.dev/interop/js-interop/js-types

## Target Platforms
- **Node.js** - Backend APIs (Express.js, etc.)
- **React** - Web frontends
- **React Native** - Mobile apps (iOS/Android)

All written in Dart. All transpiled to JavaScript. One language across the entire stack.

## Why Dart?
- Sound null-safe type system
- Familiar to Flutter developers
- Single language for mobile, web, and backend
- Compiles to efficient JavaScript

## Architecture

```
dart_js_framework/
├── packages/
│   ├── core/              # Core JS interop utilities
│   ├── node/              # Node.js bindings
│   ├── express/           # Express.js bindings
│   ├── react/             # React bindings
│   └── react_native/      # React Native bindings
├── examples/
│   ├── express_server/    # Sample Express API
│   ├── react_app/         # Sample React website
│   └── react_native_app/  # Sample mobile app
└── tools/
    └── build/             # Build tooling
```

## Core Concept

1. Write application code in Dart
2. Use framework bindings to call JS libraries (Express, React, etc.)
3. Transpile with `dart compile js`
4. Run on target platform (Node, Browser, React Native)

## Technical Foundation

### JS Interop
- `dart:js_interop` - Type-safe JS interop (Dart 3.3+)
- `dart:js_interop_unsafe` - Dynamic access to globalContext
- Extension types - Zero-cost wrappers for JS objects

### Node Compatibility
- `node_preamble` - Makes transpiled JS Node-compatible

### Build Process
1. Compile Dart to JS
2. Add platform-specific preamble (Node, Browser, RN)
3. Output runnable JavaScript

## Phase 1: Node/Express (Current)
- [x] Basic Express server working
- [ ] Full Express API bindings
- [ ] Middleware support
- [ ] Router support
- [ ] JSON body parsing
- [ ] Static file serving

## Phase 2: React Web
- [ ] React component bindings
- [ ] JSX-like syntax in Dart
- [ ] State management
- [ ] Hooks support
- [ ] Build tooling for web

## Phase 3: React Native
- [ ] React Native component bindings
- [ ] Native module access
- [ ] Navigation
- [ ] Build tooling for iOS/Android

## Example: Express Server (Phase 1)

```dart
import 'package:dart_express/express.dart';

void main() {
  final app = express();

  app.get('/', (req, res) {
    res.json({'message': 'Hello from Dart!'});
  });

  app.listen(3000);
}
```

## Example: React Component (Phase 2)

```dart
import 'package:dart_react/react.dart';

class App extends Component {
  @override
  Widget render() {
    return div(
      className: 'app',
      children: [
        h1('Hello from Dart!'),
        Button(onClick: handleClick, child: 'Click me'),
      ],
    );
  }
}
```

## Example: React Native (Phase 3)

```dart
import 'package:dart_react_native/react_native.dart';

class App extends Component {
  @override
  Widget render() {
    return View(
      children: [
        Text('Hello from Dart!'),
        TouchableOpacity(
          onPress: handlePress,
          child: Text('Tap me'),
        ),
      ],
    );
  }
}
```

## Goals
- Dart-first developer experience
- Type-safe bindings for all JS APIs
- Minimal runtime overhead
- Familiar patterns for Flutter developers
- Production-ready tooling
