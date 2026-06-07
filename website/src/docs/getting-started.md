---
layout: layouts/docs.njk
title: Getting Started
description: Get up and running with dart_node in minutes. Build Express servers, React apps, and React Native mobile apps - all in Dart.
keywords: dart_node tutorial, Dart Express server, Dart React app, full-stack Dart, getting started Dart JavaScript
eleventyNavigation:
  key: Getting Started
  order: 1
faq:
  - question: What are the prerequisites for dart_node?
    answer: You need Dart SDK 3.10 or higher and Node.js 18 or higher. A code editor like VS Code with the Dart extension is recommended.
  - question: How do I compile Dart to JavaScript?
    answer: Use the command 'dart compile js lib/server.dart -o build/server.js' to compile your Dart code to JavaScript, then run it with 'node build/server.js'.
  - question: Can I use npm packages with dart_node?
    answer: Yes! dart_node uses JS interop to call npm packages at runtime. Install npm packages normally with npm install, then use them from Dart via the dart_node bindings.
  - question: How do I create an Express server with Dart?
    answer: Add dart_node_express to your pubspec.yaml, import it, create an app with express(), define routes with app.get() or app.post(), and start with app.listen().
---

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What are the prerequisites for dart_node?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "You need Dart SDK 3.10 or higher and Node.js 18 or higher. A code editor like VS Code with the Dart extension is recommended."
      }
    },
    {
      "@type": "Question",
      "name": "How do I compile Dart to JavaScript?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Use the command 'dart compile js lib/server.dart -o build/server.js' to compile your Dart code to JavaScript, then run it with 'node build/server.js'."
      }
    },
    {
      "@type": "Question",
      "name": "Can I use npm packages with dart_node?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes! dart_node uses JS interop to call npm packages at runtime. Install npm packages normally with npm install, then use them from Dart via the dart_node bindings."
      }
    },
    {
      "@type": "Question",
      "name": "How do I create an Express server with Dart?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Add dart_node_express to your pubspec.yaml, import it, create an app with express(), define routes with app.get() or app.post(), and start with app.listen()."
      }
    }
  ]
}
</script>

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "How to Create a Dart Express Server",
  "description": "Step-by-step guide to building an Express.js server using Dart and dart_node",
  "totalTime": "PT10M",
  "tool": [
    {
      "@type": "HowToTool",
      "name": "Dart SDK 3.10+"
    },
    {
      "@type": "HowToTool",
      "name": "Node.js 18+"
    }
  ],
  "step": [
    {
      "@type": "HowToStep",
      "name": "Create a new project",
      "text": "Run 'mkdir my_dart_server && cd my_dart_server && dart create -t package .'"
    },
    {
      "@type": "HowToStep",
      "name": "Add dependencies",
      "text": "Add dart_node_core and dart_node_express to pubspec.yaml and run 'dart pub get'"
    },
    {
      "@type": "HowToStep",
      "name": "Write your server",
      "text": "Create lib/server.dart with Express routes using app.get() and app.post()"
    },
    {
      "@type": "HowToStep",
      "name": "Compile and run",
      "text": "Run 'dart compile js lib/server.dart -o build/server.js' then 'node build/server.js'"
    }
  ]
}
</script>

Welcome to dart_node! This guide will help you build your first application using Dart for the JavaScript ecosystem.

<div class="package-links" style="margin-bottom: var(--space-8);">
  <a href="https://pub.dev/publishers/dartnode.dev/packages" target="_blank" rel="noopener noreferrer" class="btn btn-primary">Browse packages on pub.dev</a>
  <a href="https://github.com/MelbourneDeveloper/dart_node" target="_blank" rel="noopener noreferrer" class="btn btn-secondary">Star on GitHub</a>
</div>

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

## Support the Project

If dart_node is useful to you, please consider:

- [Star the repository on GitHub](https://github.com/MelbourneDeveloper/dart_node) - It helps others discover the project
- [Like the packages on pub.dev](https://pub.dev/publishers/dartnode.dev/packages) - Boost visibility in the Dart ecosystem
- [Share on social media](https://twitter.com/intent/tweet?text=Check%20out%20dart_node%20-%20Full-Stack%20Dart%20for%20React,%20React%20Native,%20and%20Express!%20https://dartnode.dev) - Spread the word
