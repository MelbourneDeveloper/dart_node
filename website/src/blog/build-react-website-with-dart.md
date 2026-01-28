---
layout: layouts/blog.njk
title: "Build a React Website With Dart"
description: "Learn how to build type-safe React web applications using Dart and the dart_node_react package. Step-by-step tutorial with working code examples."
date: 2026-01-28
author: "dart_node team"
category: tutorials
tags:
  - react
  - dart
  - frontend
  - tutorial
  - web-development
---

Want to build React websites with Dart instead of JavaScript or TypeScript? The **dart_node_react** package makes this possible with full type safety and familiar React patterns. This tutorial walks you through building a React web application entirely in Dart.

## Why Build React Apps with Dart?

React developers often wish TypeScript's types existed at runtime. Dart solves this problem. Types are checked at compile time *and* runtime. Null safety is sound. When you write Dart code, you know exactly what types you're working with.

Flutter developers already know Dart. With dart_node_react, you can use those same skills to build React web applications. Share code between Flutter and React. Use one language across your entire stack.

## Setting Up Your Project

Create a new Dart project for your React frontend:

```bash
mkdir my_react_app && cd my_react_app
dart create -t package .
```

Add the required dependencies to your `pubspec.yaml`:

```yaml
name: my_react_app
environment:
  sdk: ^3.0.0

dependencies:
  dart_node_core: ^0.1.0
  dart_node_react: ^0.1.0
```

Run `dart pub get` to install the packages.

## Your First React Component

Create a file at `web/app.dart`. This is your application entry point:

```dart
import 'dart:js_interop';
import 'package:dart_node_react/dart_node_react.dart';

void main() {
  final root = Document.getElementById('root');
  (root != null)
      ? ReactDOM.createRoot(root).render(App())
      : throw StateError('Root element not found');
}

ReactElement App() => createElement(
  ((JSAny props) {
    return div(
      className: 'app',
      children: [
        h1('Hello from Dart!'),
        pEl('This React app is built entirely with Dart.'),
      ],
    );
  }).toJS,
);
```

The `createElement` function wraps your component logic. Inside, you return React elements using helper functions like `div`, `h1`, and `pEl` (for paragraph elements).

## Managing State with Hooks

dart_node_react provides type-safe React hooks. The `useState` hook manages component state:

```dart
ReactElement Counter() => createElement(
  ((JSAny props) {
    final count = useState(0);

    return div(
      className: 'counter',
      children: [
        h2('Count: ${count.value}'),
        button(
          text: 'Increment',
          onClick: (_) => count.setWithUpdater((c) => c + 1),
        ),
        button(
          text: 'Reset',
          onClick: (_) => count.set(0),
        ),
      ],
    );
  }).toJS,
);
```

The `useState` hook returns a `StateHook<T>` object with:

- `value` - the current state value
- `set(newValue)` - replaces the state
- `setWithUpdater((oldValue) => newValue)` - updates based on previous state

## Handling User Input

Building forms requires handling input events. Here's a login form example:

```dart
ReactElement LoginForm() => createElement(
  ((JSAny props) {
    final emailState = useState('');
    final passwordState = useState('');
    final errorState = useState<String?>(null);

    void handleSubmit() {
      if (emailState.value.isEmpty || passwordState.value.isEmpty) {
        errorState.set('Please fill in all fields');
        return;
      }
      // Submit login request
      print('Logging in: ${emailState.value}');
    }

    return div(
      className: 'login-form',
      children: [
        h2('Sign In'),
        if (errorState.value != null)
          div(className: 'error', child: span(errorState.value!)),
        input(
          type: 'email',
          placeholder: 'Email',
          value: emailState.value,
          className: 'input',
          onChange: (e) => emailState.set(getInputValue(e).toDart),
        ),
        input(
          type: 'password',
          placeholder: 'Password',
          value: passwordState.value,
          className: 'input',
          onChange: (e) => passwordState.set(getInputValue(e).toDart),
        ),
        button(
          text: 'Sign In',
          className: 'btn btn-primary',
          onClick: handleSubmit,
        ),
      ],
    );
  }).toJS,
);
```

The `getInputValue` helper extracts the input value from change events. Call `.toDart` to convert the JavaScript string to a Dart string.

## Side Effects with useEffect

Load data when components mount using `useEffect`:

```dart
ReactElement UserList() => createElement(
  ((JSAny props) {
    final usersState = useState<List<String>>([]);
    final loadingState = useState(true);

    useEffect(() {
      Future<void> loadUsers() async {
        // Simulate API call
        await Future.delayed(Duration(seconds: 1));
        usersState.set(['Alice', 'Bob', 'Charlie']);
        loadingState.set(false);
      }

      unawaited(loadUsers());
      return null;
    }, []);

    return div(
      className: 'user-list',
      children: [
        h2('Users'),
        if (loadingState.value)
          span('Loading...')
        else
          ul(
            children: usersState.value
                .map((user) => li(child: span(user)))
                .toList(),
          ),
      ],
    );
  }).toJS,
);
```

Pass an empty list `[]` as the second argument to run the effect only on mount. Return a cleanup function or `null` if no cleanup is needed.

## Building the HTML Structure

dart_node_react provides functions for all standard HTML elements:

```dart
ReactElement PageLayout() => createElement(
  ((JSAny props) {
    return div(
      className: 'layout',
      children: [
        header(
          className: 'header',
          child: h1('My Dart React App'),
        ),
        mainEl(
          className: 'main-content',
          children: [
            section(
              className: 'hero',
              children: [
                h2('Welcome'),
                pEl('Build type-safe React apps with Dart.'),
              ],
            ),
          ],
        ),
        footer(
          className: 'footer',
          child: pEl('Built with dart_node_react'),
        ),
      ],
    );
  }).toJS,
);
```

Common elements include `div`, `span`, `h1`-`h6`, `pEl`, `ul`, `li`, `button`, `input`, `form`, `header`, `footer`, `mainEl`, `section`, `nav`, and `article`.

## Compiling and Running

Create an HTML file at `web/index.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>My Dart React App</title>
</head>
<body>
  <div id="root"></div>
  <script src="https://unpkg.com/react@18/umd/react.development.js"></script>
  <script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
  <script src="app.dart.js"></script>
</body>
</html>
```

Compile your Dart code to JavaScript:

```bash
dart compile js web/app.dart -o web/app.dart.js
```

Serve the `web` directory with any static file server and open it in your browser.

## Complete Example: Task Manager

Here's a complete task manager component demonstrating all concepts:

```dart
ReactElement TaskManager() => createElement(
  ((JSAny props) {
    final tasksState = useState<List<String>>([]);
    final newTaskState = useState('');

    void addTask() {
      switch (newTaskState.value.trim().isEmpty) {
        case true:
          return;
        case false:
          tasksState.setWithUpdater(
            (tasks) => [...tasks, newTaskState.value],
          );
          newTaskState.set('');
      }
    }

    void removeTask(int index) {
      tasksState.setWithUpdater((tasks) {
        final updated = [...tasks];
        updated.removeAt(index);
        return updated;
      });
    }

    return div(
      className: 'task-manager',
      children: [
        h2('My Tasks'),
        div(
          className: 'add-task',
          children: [
            input(
              type: 'text',
              placeholder: 'New task...',
              value: newTaskState.value,
              onChange: (e) => newTaskState.set(getInputValue(e).toDart),
            ),
            button(text: 'Add', onClick: addTask),
          ],
        ),
        ul(
          className: 'task-list',
          children: tasksState.value.indexed
              .map(
                (item) => li(
                  children: [
                    span(item.$2),
                    button(
                      text: 'Delete',
                      onClick: (_) => removeTask(item.$1),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }).toJS,
);
```

## Next Steps

You now have the foundation to build React websites with Dart. Explore the [dart_node_react documentation](/api/dart_node_react/) for more hooks like `useEffect`, `useMemo`, and `useCallback`. Check out the [examples repository](https://github.com/AstroCodez/dart_node/tree/main/examples/frontend) for a complete full-stack application with authentication, API calls, and WebSocket integration.

Start building type-safe React applications with Dart today.
