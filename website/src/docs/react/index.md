---
layout: layouts/docs.njk
title: dart_node_react
description: React bindings for building web applications in Dart with hooks, components, and JSX-like syntax.
eleventyNavigation:
  key: dart_node_react
  parent: Packages
  order: 3
---

`dart_node_react` provides type-safe React bindings for building web applications in Dart. If you know React, you'll feel right at home.

## Installation

```yaml
dependencies:
  dart_node_react: ^0.2.0
```

Also install React via npm:

```bash
npm install react react-dom
```

## Quick Start

```dart
import 'package:dart_node_react/dart_node_react.dart';

ReactElement app() {
  return div(
    className: 'app',
    children: [
      h1(children: [text('Hello, Dart!')]),
      p(children: [text('Welcome to React with Dart.')]),
    ],
  );
}

void main() {
  final container = document.getElementById('root');
  final root = ReactDOM.createRoot(container);
  root.render(app());
}
```

## Components

### Functional Components

```dart
ReactElement greeting({required String name}) {
  return div(
    className: 'greeting',
    children: [
      text('Hello, $name!'),
    ],
  );
}

// Usage
greeting(name: 'World');
```

### Components with Props

```dart
ReactElement userCard({
  required String name,
  required String email,
  String? avatarUrl,
}) {
  return div(
    className: 'user-card',
    children: [
      avatarUrl != null
          ? img(src: avatarUrl, alt: name)
          : div(className: 'avatar-placeholder'),
      h2(children: [text(name)]),
      p(children: [text(email)]),
    ],
  );
}
```

## Hooks

### useState

```dart
ReactElement counter() {
  final (count, setCount) = useState(0);

  return div(children: [
    p(children: [text('Count: $count')]),
    button(
      onClick: (_) => setCount((c) => c + 1),
      children: [text('Increment')],
    ),
    button(
      onClick: (_) => setCount((c) => c - 1),
      children: [text('Decrement')],
    ),
  ]);
}
```

### useEffect

```dart
ReactElement timer() {
  final (seconds, setSeconds) = useState(0);

  useEffect(() {
    final timer = Timer.periodic(Duration(seconds: 1), (_) {
      setSeconds((s) => s + 1);
    });

    // Cleanup function
    return () => timer.cancel();
  }, []); // Empty deps = run once on mount

  return p(children: [text('Seconds: $seconds')]);
}
```

### useRef

```dart
ReactElement focusInput() {
  final inputRef = useRef<HTMLInputElement>(null);

  void handleClick() {
    inputRef.current?.focus();
  }

  return div(children: [
    input(ref: inputRef, type: 'text'),
    button(
      onClick: (_) => handleClick(),
      children: [text('Focus Input')],
    ),
  ]);
}
```

### useMemo

```dart
ReactElement expensiveList({required List<int> numbers}) {
  // Only recalculate when numbers changes
  final sorted = useMemo(
    () => numbers.toList()..sort(),
    [numbers],
  );

  return ul(
    children: sorted.map((n) => li(children: [text('$n')])).toList(),
  );
}
```

### useCallback

```dart
ReactElement searchBox({required void Function(String) onSearch}) {
  final (query, setQuery) = useState('');

  // Memoize the callback
  final handleSubmit = useCallback(
    () => onSearch(query),
    [query, onSearch],
  );

  return form(
    onSubmit: (_) => handleSubmit(),
    children: [
      input(
        value: query,
        onChange: (e) => setQuery(e.target.value),
      ),
      button(type: 'submit', children: [text('Search')]),
    ],
  );
}
```

## Elements

### HTML Elements

```dart
// Divs and spans
div(className: 'container', children: [...])
span(className: 'highlight', children: [...])

// Headings
h1(children: [text('Title')])
h2(children: [text('Subtitle')])

// Paragraphs and text
p(children: [text('Some text')])
text('Raw text content')

// Links
a(href: 'https://example.com', children: [text('Click me')])

// Images
img(src: '/image.png', alt: 'Description')

// Forms
form(onSubmit: handleSubmit, children: [...])
input(type: 'text', value: value, onChange: handleChange)
button(type: 'submit', children: [text('Submit')])
```

### Lists

```dart
ReactElement todoList({required List<Todo> todos}) {
  return ul(
    className: 'todo-list',
    children: todos.map((todo) =>
      li(
        key: todo.id,
        children: [
          input(
            type: 'checkbox',
            checked: todo.completed,
          ),
          text(todo.title),
        ],
      )
    ).toList(),
  );
}
```

### Conditional Rendering

```dart
ReactElement userStatus({required User? user}) {
  return div(children: [
    user != null
        ? span(children: [text('Welcome, ${user.name}!')])
        : span(children: [text('Please log in')]),
  ]);
}
```

## Event Handling

```dart
ReactElement interactiveButton() {
  void handleClick(MouseEvent e) {
    print('Button clicked at (${e.clientX}, ${e.clientY})');
  }

  void handleMouseEnter(MouseEvent e) {
    print('Mouse entered');
  }

  return button(
    onClick: handleClick,
    onMouseEnter: handleMouseEnter,
    children: [text('Hover and Click Me')],
  );
}
```

### Form Events

```dart
ReactElement loginForm() {
  final (email, setEmail) = useState('');
  final (password, setPassword) = useState('');

  void handleSubmit(Event e) {
    e.preventDefault();
    print('Login: $email / $password');
  }

  return form(
    onSubmit: handleSubmit,
    children: [
      input(
        type: 'email',
        value: email,
        onChange: (e) => setEmail(e.target.value),
        placeholder: 'Email',
      ),
      input(
        type: 'password',
        value: password,
        onChange: (e) => setPassword(e.target.value),
        placeholder: 'Password',
      ),
      button(type: 'submit', children: [text('Log In')]),
    ],
  );
}
```

## Styling

### Inline Styles

```dart
div(
  style: {
    'backgroundColor': '#f0f0f0',
    'padding': '1rem',
    'borderRadius': '8px',
  },
  children: [...],
)
```

### CSS Classes

```dart
div(
  className: 'card card-primary',
  children: [...],
)
```

## Complete Example

```dart
import 'package:dart_node_react/dart_node_react.dart';

ReactElement todoApp() {
  final (todos, setTodos) = useState<List<Todo>>([]);
  final (input, setInput) = useState('');

  void addTodo() {
    if (input.trim().isEmpty) return;

    setTodos((prev) => [
      ...prev,
      Todo(id: DateTime.now().toString(), title: input, completed: false),
    ]);
    setInput('');
  }

  void toggleTodo(String id) {
    setTodos((prev) => prev.map((todo) =>
      todo.id == id
          ? Todo(id: todo.id, title: todo.title, completed: !todo.completed)
          : todo
    ).toList());
  }

  return div(
    className: 'todo-app',
    children: [
      h1(children: [text('Todo List')]),

      form(
        onSubmit: (e) {
          e.preventDefault();
          addTodo();
        },
        children: [
          input(
            value: input,
            onChange: (e) => setInput(e.target.value),
            placeholder: 'What needs to be done?',
          ),
          button(type: 'submit', children: [text('Add')]),
        ],
      ),

      ul(
        children: todos.map((todo) =>
          li(
            key: todo.id,
            className: todo.completed ? 'completed' : '',
            onClick: (_) => toggleTodo(todo.id),
            children: [text(todo.title)],
          )
        ).toList(),
      ),

      p(children: [
        text('${todos.where((t) => !t.completed).length} items left'),
      ]),
    ],
  );
}

class Todo {
  final String id;
  final String title;
  final bool completed;

  Todo({required this.id, required this.title, required this.completed});
}

void main() {
  final root = ReactDOM.createRoot(document.getElementById('root')!);
  root.render(todoApp());
}
```

## API Reference

See the [full API documentation](/api/dart_node_react/) for all available functions and types.
