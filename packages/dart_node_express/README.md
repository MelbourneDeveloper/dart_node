# dart_node_express

Type-safe Express.js bindings for Dart. Build HTTP servers and REST APIs entirely in Dart.

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
import 'dart:js_interop';
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = express();

  app.get('/', handler((req, res) {
    res.send('Hello, Dart!');
  }));

  app.listen(3000, () {
    print('Server running on port 3000');
  }.toJS);
}
```

## Routing

### Basic Routes

```dart
app.get('/users', handler((req, res) {
  res.jsonMap({'users': []});
}));

app.post('/users', handler((req, res) {
  final body = req.body;
  res.status(201);
  res.jsonMap({'created': true});
}));

app.put('/users/:id', handler((req, res) {
  final id = req.params['id'];
  res.jsonMap({'updated': id});
}));

app.delete('/users/:id', handler((req, res) {
  res.status(204);
  res.end();
}));
```

### Route Parameters

```dart
app.get('/users/:userId/posts/:postId', handler((req, res) {
  final userId = req.params['userId'];
  final postId = req.params['postId'];

  res.jsonMap({
    'userId': userId,
    'postId': postId,
  });
}));
```

### Query Parameters

```dart
app.get('/search', handler((req, res) {
  final query = req.query['q'];
  final page = int.tryParse(req.query['page'] ?? '1') ?? 1;

  res.jsonMap({
    'query': query,
    'page': page,
  });
}));
```

## Request Object

The `Request` object provides access to incoming request data:

```dart
app.post('/api/data', handler((req, res) {
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

  res.jsonMap({'received': body});
}));
```

## Response Object

The `Response` object provides methods for sending responses:

```dart
// Send text
res.send('Hello!');

// Send JSON (for Dart Maps, use jsonMap)
res.jsonMap({'message': 'Hello!'});

// Set status code (separate call from response)
res.status(201);
res.jsonMap({'created': true});

// Set headers
res.set('X-Custom-Header', 'value');

// Redirect
res.redirect('/new-location');

// End response without body
res.status(204);
res.end();
```

## Middleware

### Custom Middleware

```dart
app.use(middleware((req, res, next) {
  print('${req.method} ${req.path}');
  next();
}));
```

### Chaining Middleware

```dart
app.use(chain([
  middleware((req, res, next) {
    print('First middleware');
    next();
  }),
  middleware((req, res, next) {
    print('Second middleware');
    next();
  }),
]));
```

### Request Context

Store and retrieve values in the request context:

```dart
// Set context in middleware
app.use(middleware((req, res, next) {
  setContext(req, 'userId', '123');
  next();
}));

// Get context in handler
app.get('/profile', handler((req, res) {
  final userId = getContext<String>(req, 'userId');
  res.jsonMap({'userId': userId});
}));
```

## Router

Organize routes with the Router:

```dart
Router createUserRouter() {
  final router = Router();

  router.get('/', handler((req, res) {
    res.jsonMap({'users': []});
  }));

  router.post('/', handler((req, res) {
    res.status(201);
    res.jsonMap({'created': true});
  }));

  router.get('/:id', handler((req, res) {
    res.jsonMap({'user': req.params['id']});
  }));

  return router;
}

void main() {
  final app = express();

  // Mount the router
  final router = createUserRouter();
  app.use('/api/users', router);

  app.listen(3000);
}
```

## Async Handlers

Use async handlers for database calls and other async operations:

```dart
app.get('/users', asyncHandler((req, res) async {
  final users = await database.fetchUsers();
  res.jsonMap({'users': users});
}));
```

The `asyncHandler` wrapper ensures errors are properly caught and passed to error middleware.

## Validation

Use the schema-based validation system:

```dart
// Define a validated data type
typedef CreateUserData = ({String name, String email, int? age});

// Create a schema
final createUserSchema = schema<CreateUserData>(
  {
    'name': string().minLength(2).maxLength(50),
    'email': string().email(),
    'age': optional(int_().positive()),
  },
  (data) => (
    name: data['name'] as String,
    email: data['email'] as String,
    age: data['age'] as int?,
  ),
);

// Use validation middleware
app.post('/users', validateBody(createUserSchema));
app.post('/users', handler((req, res) {
  final result = getValidatedBody<CreateUserData>(req);
  switch (result) {
    case Success(:final value):
      res.status(201);
      res.jsonMap({'name': value.name, 'email': value.email});
    case Error(:final error):
      res.status(400);
      res.jsonMap({'error': error});
  }
}));
```

### Available Validators

```dart
// String validators
string().minLength(2).maxLength(100).notEmpty().email().alphanumeric()

// Integer validators
int_().min(0).max(100).positive().range(1, 10)

// Boolean validators
bool_()

// Optional wrapper
optional(string())
```

## Complete Example

```dart
import 'dart:js_interop';
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = express();

  // Logging middleware
  app.use(middleware((req, res, next) {
    print('[${DateTime.now()}] ${req.method} ${req.path}');
    next();
  }));

  // Routes
  app.get('/', handler((req, res) {
    res.jsonMap({
      'name': 'My API',
      'version': '1.0.0',
    });
  }));

  app.get('/health', handler((req, res) {
    res.jsonMap({'status': 'ok'});
  }));

  // Mount routers
  app.use('/api/users', createUserRouter());

  // Start server
  app.listen(3000, () {
    print('Server running on port 3000');
  }.toJS);
}
```

## Source Code

The source code is available on [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_express).
