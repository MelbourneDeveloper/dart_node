---
layout: layouts/blog.njk
title: "Introducing dart_node: Full-Stack Dart for the JavaScript Ecosystem"
description: "We're excited to announce dart_node, a framework for building React, React Native, and Express applications entirely in Dart."
date: 2024-01-15
author: "dart_node team"
category: announcements
tags:
  - announcement
  - dart
  - react
  - express
---

Today we're excited to introduce **dart_node**, a framework that lets you build React, React Native, and Express applications entirely in Dart.

## Why dart_node?

If you're a **React developer**, you've probably wished TypeScript's types existed at runtime. You've probably fought with complex webpack configs. You've probably wondered why you need three different config files just to get a project started.

If you're a **Flutter developer**, you've probably wished you could use your Dart skills in the web ecosystem. You've probably wanted access to React's massive component library. You've probably wanted to share code between your Flutter app and a React Native version.

dart_node is for both of you.

## What Makes Dart Different

Dart and TypeScript both add type safety to dynamic languages. But they made different design choices:

**TypeScript chose maximum JavaScript compatibility.** This was brilliant - it meant instant access to the npm ecosystem and gradual adoption in existing codebases. But it came with a cost: types are erased at compile time.

**Dart chose maximum type safety.** Types exist at runtime. Null safety is sound. Generics aren't erased. When you serialize an object, you can validate its structure. When you deserialize it, you know what you're getting.

Here's a concrete example:

```typescript
// TypeScript
interface User {
  name: string;
  age: number;
}

const user: User = JSON.parse(apiResponse);
// Is user actually a User? We hope so!
console.log(user.name.toUpperCase());
// Runtime crash if name is undefined
```

```dart
// Dart
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json['name'] as String,  // Validated!
    age: json['age'] as int,       // Validated!
  );
}

final user = User.fromJson(jsonDecode(apiResponse));
// If we get here, user.name is definitely a String
print(user.name.toUpperCase());  // Safe!
```

This isn't about TypeScript being bad - it's about different trade-offs for different needs.

## The dart_node Stack

We've built five packages that give you full-stack capabilities:

### dart_node_core

The foundation layer. Provides JavaScript interop utilities, Node.js bindings, and the glue that makes everything work together.

### dart_node_express

Type-safe Express.js bindings. Build REST APIs with the same patterns you know from Express, but with Dart's type safety.

```dart
final app = createExpressApp();

app.get('/users/:id', (req, res) {
  final id = req.params['id'];
  res.json({'user': {'id': id}});
});

app.listen(3000);
```

### dart_node_react

React bindings with hooks, components, and JSX-like syntax. Everything you love about React, in Dart.

```dart
ReactElement counter() {
  final (count, setCount) = useState(0);

  return button(
    onClick: (_) => setCount((c) => c + 1),
    children: [text('Count: $count')],
  );
}
```

### dart_node_react_native

React Native bindings for mobile development. Use with Expo for a complete mobile development experience.

```dart
ReactElement app() {
  return safeAreaView(children: [
    view(style: {'padding': 20}, children: [
      rnText(children: [text('Hello from Dart!')]),
    ]),
  ]);
}
```

### dart_node_ws

WebSocket bindings for real-time communication. Build chat apps, dashboards, and more.

```dart
final server = createWebSocketServer(port: 8080);

server.on('connection', (client) {
  client.on('message', (data) {
    client.send('Echo: $data');
  });
});
```

## Getting Started

Getting started is straightforward:

```bash
mkdir my_app && cd my_app
dart create -t package .
dart pub add dart_node_core dart_node_express
```

Write your server:

```dart
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = createExpressApp();

  app.get('/', (req, res) {
    res.json({'message': 'Hello from Dart!'});
  });

  app.listen(3000, () {
    print('Server running on port 3000');
  });
}
```

Compile and run:

```bash
dart compile js lib/server.dart -o build/server.js
node build/server.js
```

That's it. No webpack. No babel. No complex configuration.

## Who Is This For?

**React developers** who want better type safety without losing the React patterns they know.

**Flutter developers** who want to use their Dart skills in the JavaScript ecosystem.

**Full-stack developers** who want to share code between frontend, backend, and mobile.

**Anyone** who's tired of maintaining three different codebases in three different languages.

## What's Next

This is just the beginning. We're working on:

- More React hooks and component bindings
- Navigation libraries for React Native
- State management solutions
- Build tooling improvements
- More documentation and examples

## Try It Out

Check out the [Getting Started guide](/docs/getting-started/) to build your first dart_node application. Browse the [API documentation](/api/) to see what's available. And if you have questions, open an issue on GitHub.

We can't wait to see what you build.

---

*dart_node is open source and MIT licensed. Contributions are welcome!*
