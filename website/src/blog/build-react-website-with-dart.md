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

What if you could build React apps without the existential dread of `undefined is not a function`? What if your types actually meant something at runtime? What if you never had to debug another `Cannot read property 'map' of null` error at 2 AM?

Good news: you can. With **dart_node_react**, you write React applications entirely in Dart. Same React patterns you know. Real type safety you've been dreaming about.

## Why Dart? (Besides the Obvious Joy of Not Using JavaScript)

Let's be honest. TypeScript was a massive improvement over JavaScript. But its types are like a bouncer who checks IDs at the door and then goes home. Once you're past the compiler, anything goes.

Dart takes a different approach. Types exist at runtime. Null safety is sound. When your code compiles, you know your `String` is actually a `String` and not secretly `undefined` wearing a fake mustache.

Already know Flutter? You already know Dart. Now you can use those same skills to build React web apps. One language. Full stack. No context switching between "Dart brain" and "TypeScript brain."

## Setting Up Your Project

Getting started takes about 30 seconds. Create a new Dart project:

```bash
mkdir my_react_app && cd my_react_app
dart create -t package .
```

Add the dependencies to your `pubspec.yaml`:

```yaml
name: my_react_app
environment:
  sdk: ^3.0.0

dependencies:
  dart_node_core: ^0.1.0
  dart_node_react: ^0.1.0
```

Run `dart pub get`. Done. No webpack config. No babel. No 47 dev dependencies fighting each other.

## Your First Component

Create `web/app.dart`. This is where the magic happens:

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
        pEl('Look ma, no JavaScript!'),
      ],
    );
  }).toJS,
);
```

The `createElement` function wraps your component logic. Inside, you return React elements using helper functions like `div`, `h1`, and `pEl`. It feels like React because it *is* React, just with better types.

## State Management: useState Without the Guesswork

Here's where Dart really shines. The `useState` hook returns a `StateHook<T>` with actual, honest-to-goodness type safety:

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

Three ways to update state:

- `count.value` - read the current value
- `count.set(5)` - set a new value directly
- `count.setWithUpdater((old) => old + 1)` - update based on previous value

No more `useState<number | undefined>(undefined)` gymnastics. Just `useState(0)`. The compiler knows it's an `int`.

## Building Forms (The Part Everyone Dreads)

Forms don't have to be painful. Here's a login form that actually works:

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

The `getInputValue` helper extracts input values from events. Call `.toDart` to convert JavaScript strings to Dart strings. Clean and predictable.

## Side Effects with useEffect

Need to fetch data when a component mounts? `useEffect` works exactly like you'd expect:

```dart
ReactElement UserList() => createElement(
  ((JSAny props) {
    final usersState = useState<List<String>>([]);
    final loadingState = useState(true);

    useEffect(() {
      Future<void> loadUsers() async {
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

Pass an empty list `[]` to run the effect only on mount. Return a cleanup function or `null` if you don't need cleanup. No surprises here.

## All Your Favorite HTML Elements

dart_node_react provides functions for every HTML element you need:

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

You get `div`, `span`, `h1`-`h6`, `pEl`, `ul`, `li`, `button`, `input`, `form`, `header`, `footer`, `mainEl`, `section`, `nav`, `article`, and more. Everything you need to build real UIs.

## Compiling and Running

Create `web/index.html`:

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

Compile your Dart to JavaScript:

```bash
dart compile js web/app.dart -o web/app.dart.js
```

Serve the `web` directory and open it in your browser. That's it. Your React app is running, and you didn't write a single line of JavaScript.

## Putting It Together: A Task Manager

Here's a complete example combining everything you've learned:

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

State management, event handling, list rendering. All type-safe. All Dart.

## What's Next?

You've got the basics. Now go build something. Explore [more hooks](/api/dart_node_react/) like `useMemo` and `useCallback`. Check out the [full-stack example](https://github.com/AstroCodez/dart_node/tree/main/examples/frontend) with authentication, API integration, and WebSocket support.

No more fighting with type coercion. No more `any` escape hatches. Just clean, type-safe React apps in a language that respects your time.

Welcome to the future. It compiles to JavaScript, but at least you don't have to write it.
