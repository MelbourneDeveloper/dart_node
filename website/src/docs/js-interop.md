---
layout: layouts/docs.njk
title: JavaScript Interop
description: Learn how to call JavaScript from Dart and vice versa using dart:js_interop.
eleventyNavigation:
  key: JS Interop
  order: 4
---

Dart 3.3+ provides `dart:js_interop` for seamless interaction with JavaScript. This is how dart_node wraps npm packages like Express and React.

## The Basics

### Importing dart:js_interop

```dart
import 'dart:js_interop';
```

This gives you access to:
- Extension types for JavaScript objects
- Conversion utilities between Dart and JS
- The `external` keyword for JS bindings

## Calling JavaScript Functions

### Global Functions

```dart
import 'dart:js_interop';

// Declare the external function
@JS('console.log')
external void consoleLog(JSAny? message);

// Use it
void main() {
  consoleLog('Hello from Dart!'.toJS);
}
```

### Importing npm Modules

```dart
import 'dart:js_interop';

// Require a Node.js module
@JS('require')
external JSObject require(String module);

void main() {
  final express = require('express');
  // Now you have the express module!
}
```

## Extension Types

Extension types provide zero-cost wrappers around JavaScript objects. They're the foundation of dart_node's typed APIs.

```dart
import 'dart:js_interop';

// Define an extension type for a JS object
extension type JSPerson._(JSObject _) implements JSObject {
  // Constructor
  external factory JSPerson({String name, int age});

  // Properties
  external String get name;
  external set name(String value);
  external int get age;

  // Methods
  external void greet();
}

void main() {
  final person = JSPerson(name: 'Alice', age: 30);
  print(person.name); // Access JS property
  person.greet();     // Call JS method
}
```

## Type Conversions

### Dart to JavaScript

```dart
// Primitives
final jsString = 'hello'.toJS;           // JSString
final jsNumber = 42.toJS;                // JSNumber
final jsBool = true.toJS;                // JSBoolean

// Lists
final jsList = [1, 2, 3].toJS;           // JSArray

// Maps (as plain JS objects)
final jsObject = {'key': 'value'}.jsify(); // JSObject
```

### JavaScript to Dart

```dart
// Primitives
final dartString = jsString.toDart;      // String
final dartNumber = jsNumber.toDartInt;   // int
final dartBool = jsBool.toDart;          // bool

// Arrays
final dartList = jsList.toDart;          // List

// Objects (as Map)
final dartMap = jsObject.dartify();      // Map<String, dynamic>
```

## Working with Callbacks

JavaScript often uses callbacks. Here's how to handle them:

```dart
extension type EventEmitter._(JSObject _) implements JSObject {
  external void on(String event, JSFunction callback);
  external void emit(String event, JSAny? data);
}

void main() {
  final emitter = getEventEmitter();

  // Convert a Dart function to JS
  emitter.on('data', ((JSAny? data) {
    print('Received: ${data?.dartify()}');
  }).toJS);
}
```

## Promises and Futures

JavaScript Promises convert to Dart Futures:

```dart
extension type FetchAPI._(JSObject _) implements JSObject {
  external JSPromise<Response> fetch(String url);
}

Future<void> main() async {
  final api = getFetchAPI();

  // JSPromise converts to Future automatically
  final response = await api.fetch('https://api.example.com/data').toDart;
  print(response.status);
}
```

## How dart_node Uses Interop

Here's a simplified example of how dart_node wraps Express:

```dart
// Low-level JS binding
@JS('require')
external JSObject _require(String module);

// Extension type for Express app
extension type ExpressApp._(JSObject _) implements JSObject {
  external void get(String path, JSFunction handler);
  external void post(String path, JSFunction handler);
  external void listen(int port, JSFunction? callback);
}

// High-level Dart API
ExpressApp createExpressApp() {
  final express = _require('express');
  return (express as JSFunction).callAsFunction() as ExpressApp;
}

// Typed request handler
typedef RequestHandler = void Function(Request req, Response res);

// Convert Dart handler to JS
JSFunction wrapHandler(RequestHandler handler) {
  return ((JSObject req, JSObject res) {
    handler(Request._(req), Response._(res));
  }).toJS;
}

// Usage
void main() {
  final app = createExpressApp();

  app.get('/'.toJS, wrapHandler((req, res) {
    res.send('Hello!');
  }));

  app.listen(3000, null);
}
```

## Best Practices

### 1. Hide JSObject from Public APIs

```dart
// Bad: Exposes raw JS types
class MyService {
  JSObject getData() => fetchData();
}

// Good: Returns Dart types
class MyService {
  Map<String, dynamic> getData() => fetchData().dartify();
}
```

### 2. Use Extension Types for Type Safety

```dart
// Bad: Passing around raw JSObject
void processUser(JSObject user) {
  // What properties does user have? Who knows!
}

// Good: Typed extension type
void processUser(JSUser user) {
  print(user.name); // Compiler knows this exists
}
```

### 3. Handle Null Carefully

JavaScript's `null` and `undefined` are both valid. Use `JSAny?`:

```dart
extension type Config._(JSObject _) implements JSObject {
  external JSAny? get optionalValue;
}

void main() {
  final config = getConfig();

  // Check for null/undefined
  final value = config.optionalValue;
  if (value != null) {
    print(value.dartify());
  }
}
```

### 4. Validate at Boundaries

Validate JavaScript data when it enters your Dart code:

```dart
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  factory User.fromJS(JSObject obj) {
    final name = (obj['name'] as JSString?)?.toDart;
    final age = (obj['age'] as JSNumber?)?.toDartInt;

    if (name == null || age == null) {
      throw FormatException('Invalid user object');
    }

    return User(name: name, age: age);
  }
}
```

## Common Patterns

### Wrapping a Constructor

```dart
@JS('Date')
extension type JSDate._(JSObject _) implements JSObject {
  external factory JSDate();
  external factory JSDate.fromMilliseconds(int ms);
  external int getTime();
  external String toISOString();
}
```

### Wrapping Static Methods

```dart
@JS('JSON')
extension type JSJSON._(JSObject _) implements JSObject {
  external static String stringify(JSAny? value);
  external static JSAny? parse(String text);
}
```

### Accessing Global Objects

```dart
@JS('window')
external JSObject get window;

@JS('document')
external JSObject get document;

@JS('globalThis')
external JSObject get globalThis;
```

## Debugging Tips

1. **Check the browser console** - JS errors show up there
2. **Use source maps** - Debug Dart code directly
3. **Print JS objects** - `consoleLog(jsObject)` shows the raw structure
4. **Type assertions** - Use `as` carefully; it can hide errors

## Further Reading

- [Official JS Interop Documentation](https://dart.dev/interop/js-interop)
- [Extension Types](https://dart.dev/language/extension-types)
- [dart_node_core Source](/api/dart_node_core/) - See real-world interop examples
