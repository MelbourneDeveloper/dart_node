---
layout: layouts/docs.njk
title: Getting Started
description: Get up and running with dart_node in minutes. Build Express servers, React apps, and React Native mobile apps - all in Dart.
eleventyNavigation:
  key: Getting Started
  order: 1
---

Welcome to dart_node! This guide will help you build your first application using Dart for the JavaScript ecosystem.

## Prerequisites

Before you begin, make sure you have:

- **Dart SDK** (3.10 or higher) - [Install Dart](https://dart.dev/get-dart)
- **Node.js** (18 or higher) - [Install Node.js](https://nodejs.org/)
- A code editor (VS Code with Dart extension recommended)

## Quick Start: Express Server

Let's build a simple REST API server in Dart.

### 1. Create a new project

```bash
mkdir my_dart_server
cd my_dart_server
dart create -t package .
```

### 2. Add dependencies

Edit your `pubspec.yaml`:

```yaml
name: my_dart_server
environment:
  sdk: ^3.10.0

dependencies:
  dart_node_core: ^0.11.0-beta
  dart_node_express: ^0.11.0-beta
```

Then run:

```bash
dart pub get
```

### 3. Write your server

Create `lib/server.dart`:

```dart
import 'dart:js_interop';
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = express();

  // Simple GET endpoint
  app.get('/', handler((req, res) {
    res.jsonMap({
      'message': 'Hello from Dart!',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }));

  // POST endpoint - Express's JSON middleware must be used from JS
  // The body is available via req.body after configuring express.json()

  app.post('/users', handler((req, res) {
    final body = req.body;
    res.status(201);
    res.jsonMap({
      'created': true,
      'user': body,
    });
  }));

  // Start the server
  app.listen(3000, () {
    print('Server running at http://localhost:3000');
  }.toJS);
}
```

### 4. Compile and run

```bash
# Compile Dart to JavaScript
dart compile js lib/server.dart -o build/server.js

# Run with Node.js
node build/server.js
```

Visit `http://localhost:3000` to see your server in action!

## Project Structure

A typical dart_node project looks like this:

```
my_project/
├── lib/
│   ├── server.dart       # Entry point
│   ├── routes/           # Route handlers
│   ├── models/           # Data models
│   └── services/         # Business logic
├── build/                # Compiled JS output
├── pubspec.yaml          # Dart dependencies
├── package.json          # Node dependencies (for npm packages)
└── README.md
```

## Using npm Packages

Some dart_node packages wrap npm modules (like Express). You'll need to install these:

```bash
npm init -y
npm install express
```

The Dart code uses JS interop to call these npm packages at runtime.

## Next Steps

Now that you have a basic server running, explore:

- [Why Dart?](/docs/why-dart/) - Understand the benefits over TypeScript
- [Dart-to-JS Compilation](/docs/dart-to-js/) - How dart2js works
- [JS Interop](/docs/js-interop/) - Calling JavaScript from Dart
- [dart_node_express](/docs/express/) - Full Express.js API reference

## Example Projects

Check out the [examples directory](https://github.com/melbournedeveloper/dart_node/tree/main/examples) for complete working applications:

- **backend/** - Express server with REST API
- **frontend/** - React web application
- **mobile/** - React Native + Expo mobile app
