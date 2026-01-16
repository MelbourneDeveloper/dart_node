---
layout: layouts/docs.njk
title: dart_node_express
description: Type-safe Express.js bindings for building HTTP servers and REST APIs in Dart.
eleventyNavigation:
  key: dart_node_express
  parent: Packages
  order: 2
---

`dart_node_express` provides type-safe bindings for Express.js, letting you build HTTP servers and REST APIs entirely in Dart.

## Installation

```yaml
dependencies:
  dart_node_express: ^0.11.0-beta
```

Also install Express via npm:

```bash
npm install express
```

## Quick Start

```dart
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = createExpressApp();

  app.get('/', (req, res) {
    res.send('Hello, Dart!');
  });

  app.listen(3000, () {
    print('Server running on port 3000');
  });
}
```

## Routing

### Basic Routes

```dart
app.get('/users', (req, res) {
  res.json({'users': []});
});

app.post('/users', (req, res) {
  final body = req.body;
  res.status(201).json({'created': true});
});

app.put('/users/:id', (req, res) {
  final id = req.params['id'];
  res.json({'updated': id});
});

app.delete('/users/:id', (req, res) {
  res.status(204).end();
});
```

### Route Parameters

```dart
app.get('/users/:userId/posts/:postId', (req, res) {
  final userId = req.params['userId'];
  final postId = req.params['postId'];

  res.json({
    'userId': userId,
    'postId': postId,
  });
});
```

### Query Parameters

```dart
app.get('/search', (req, res) {
  final query = req.query['q'];
  final page = int.tryParse(req.query['page'] ?? '1') ?? 1;

  res.json({
    'query': query,
    'page': page,
  });
});
```

## Request Object

The `Request` object provides access to incoming request data:

```dart
app.post('/api/data', (req, res) {
  // Request body (requires body-parsing middleware)
  final body = req.body;

  // Headers
  final contentType = req.headers['content-type'];

  // URL path
  final path = req.path;

  // HTTP method
  final method = req.method;

  // Query string parameters
  final params = req.query;

  res.json({'received': body});
});
```

## Response Object

The `Response` object provides methods for sending responses:

```dart
// Send text
res.send('Hello!');

// Send JSON
res.json({'message': 'Hello!'});

// Set status code
res.status(201).json({'created': true});

// Set headers
res.setHeader('X-Custom-Header', 'value');

// Redirect
res.redirect('/new-location');

// End response without body
res.status(204).end();
```

## Middleware

### Built-in Middleware

```dart
// JSON body parsing
app.use(jsonMiddleware());

// URL-encoded body parsing
app.use(urlencodedMiddleware(extended: true));

// Static files
app.use(staticMiddleware('public'));

// CORS
app.use(corsMiddleware());
```

### Custom Middleware

```dart
void loggingMiddleware(Request req, Response res, NextFunction next) {
  print('${req.method} ${req.path}');
  next();
}

app.use(loggingMiddleware);
```

### Error Handling Middleware

```dart
void errorHandler(dynamic error, Request req, Response res, NextFunction next) {
  print('Error: $error');
  res.status(500).json({'error': 'Internal Server Error'});
}

// Error handlers have 4 parameters
app.use(errorHandler);
```

## Router

Organize routes with the Router:

```dart
Router createUserRouter() {
  final router = createRouter();

  router.get('/', (req, res) {
    res.json({'users': []});
  });

  router.post('/', (req, res) {
    res.status(201).json({'created': true});
  });

  router.get('/:id', (req, res) {
    res.json({'user': req.params['id']});
  });

  return router;
}

void main() {
  final app = createExpressApp();

  // Mount the router
  app.use('/api/users', createUserRouter());

  app.listen(3000);
}
```

## Async Handlers

Use async handlers for database calls and other async operations:

```dart
app.get('/users', asyncHandler((req, res) async {
  final users = await database.fetchUsers();
  res.json({'users': users});
}));
```

The `asyncHandler` wrapper ensures errors are properly caught and passed to error middleware.

## Validation

Validate request data:

```dart
app.post('/users', (req, res) {
  final body = req.body;

  // Validate required fields
  final validation = validateRequired(body, ['name', 'email']);

  if (validation.isErr) {
    return res.status(400).json({
      'error': 'Validation failed',
      'details': validation.err,
    });
  }

  // Create user...
  res.status(201).json({'created': true});
});
```

## Complete Example

```dart
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = createExpressApp();

  // Middleware
  app.use(jsonMiddleware());
  app.use(corsMiddleware());

  // Logging
  app.use((req, res, next) {
    print('[${DateTime.now()}] ${req.method} ${req.path}');
    next();
  });

  // Routes
  app.get('/', (req, res) {
    res.json({
      'name': 'My API',
      'version': '1.0.0',
    });
  });

  app.get('/health', (req, res) {
    res.json({'status': 'ok'});
  });

  app.use('/api/users', createUserRouter());

  // Error handler
  app.use((error, req, res, next) {
    print('Error: $error');
    res.status(500).json({'error': 'Something went wrong'});
  });

  // Start server
  final port = int.tryParse(Platform.environment['PORT'] ?? '3000') ?? 3000;
  app.listen(port, () {
    print('Server running on port $port');
  });
}
```

## API Reference

See the [full API documentation](/api/dart_node_express/) for all available functions and types.
