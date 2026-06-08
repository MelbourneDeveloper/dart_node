# dart_node_react

Type-safe React bindings for building web applications in Dart. If you know React, you'll feel right at home.

## Installation

```yaml
dependencies:
  dart_node_react: ^0.13.0-beta
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
      h1('Hello, Dart!'),
      pEl('Welcome to React with Dart.'),
    ],
  );
}

void main() {
  final container = Document.getElementById('root');
  (container != null)
      ? ReactDOM.createRoot(container).render(app())
      : throw StateError('Root element not found');
}
```

## Components

### Functional Components

```dart
ReactElement greeting({required String name}) {
  return div(
    className: 'greeting',
    child: pEl('Hello, $name!'),
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
      h2(name),
      pEl(email),
    ],
  );
}
```

## Hooks

### useState

Returns a `StateHook<T>` with `.value`, `.set()`, and `.setWithUpdater()`:

```dart
ReactElement counter() {
  final count = useState(0);

  return div(children: [
    pEl('Count: ${count.value}'),
    button(
      text: 'Increment',
      onClick: () => count.setWithUpdater((c) => c + 1),
    ),
    button(
      text: 'Decrement',
      onClick: () => count.setWithUpdater((c) => c - 1),
    ),
  ]);
}
```

### useStateLazy

For expensive initial state computation:

```dart
final data = useStateLazy(() => expensiveComputation());
```

### useEffect

```dart
ReactElement timer() {
  final seconds = useState(0);

  useEffect(() {
    final timer = Timer.periodic(Duration(seconds: 1), (_) {
      seconds.setWithUpdater((s) => s + 1);
    });

    // Cleanup function
    return () => timer.cancel();
  }, []); // Empty deps = run once on mount

  return pEl('Seconds: ${seconds.value}');
}
```

### useLayoutEffect

Synchronous version of useEffect that runs before screen updates:

```dart
useLayoutEffect(() {
  // DOM measurements
  return () { /* cleanup */ };
}, [dependency]);
```

### useRef

```dart
// A focusable DOM node exposed through a ref.
extension type FocusableElement._(JSObject _) implements JSObject {
  external void focus();
}

ReactElement focusInput() {
  final inputRef = useRef<FocusableElement>();

  void handleClick() {
    inputRef.current?.focus();
  }

  return div(children: [
    input(type: 'text', props: {'ref': inputRef.jsRef}),
    button(
      text: 'Focus Input',
      onClick: handleClick,
    ),
  ]);
}
```

### useMemo

```dart
ReactElement expensiveList({required List<int> numbers}) {
  final count = useState(0);

  // Only recalculate when count.value changes
  final fib = useMemo(
    () => fibonacci(count.value),
    [count.value],
  );

  return div(children: [
    pEl('Fibonacci of ${count.value} is $fib'),
  ]);
}
```

### useCallback

```dart
ReactElement searchBox({required void Function(String) onSearch}) {
  final query = useState('');

  void handleSubmit() => onSearch(query.value);

  // Memoize the callback to pass a stable reference to child components.
  final memoizedSubmit = useCallback(handleSubmit, [query.value, onSearch]);

  return form(
    {'onSubmit': memoizedSubmit},
    [
      input(
        value: query.value,
        onChange: (e) => query.set(inputValue(e)),
      ),
      button(text: 'Search', onClick: handleSubmit),
    ],
  );
}

// Reads the current value from an input change event.
String inputValue(SyntheticEvent event) => switch (event.target) {
  final JSObject target => switch (target['value']) {
    final JSString value => value.toDart,
    _ => '',
  },
  _ => '',
};
```

### useDebugValue

Display custom labels in React DevTools:

```dart
useDebugValue<bool>(
  isOnline.value,
  (isOnline) => isOnline ? 'Online' : 'Not Online',
);
```

## Elements

### HTML Elements

```dart
// Divs and spans
div(className: 'container', children: [...])
span('Highlighted text', className: 'highlight')

// Headings
h1('Title')
h2('Subtitle')

// Paragraphs and text
pEl('Some text')

// Links
a(href: 'https://example.com', text: 'Click me')

// Images
img(src: '/image.png', alt: 'Description')

// Forms
form({'onSubmit': handleSubmit}, [...])
input(type: 'text', value: value, onChange: handleChange)
button(text: 'Submit', onClick: handleClick)
```

### Lists

```dart
ReactElement todoList({required List<Todo> todos}) {
  return ul(
    className: 'todo-list',
    children: todos.map((todo) =>
      li(
        todo.title,
        props: {'key': todo.id},
        className: todo.completed ? 'completed' : '',
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
        ? span('Welcome, ${user.name}!')
        : span('Please log in'),
  ]);
}
```

## Event Handling

```dart
ReactElement interactiveButton() {
  void handleClick() {
    print('Button clicked');
  }

  return button(
    text: 'Click Me',
    onClick: handleClick,
  );
}
```

### Form Events

```dart
ReactElement loginForm() {
  final email = useState('');
  final password = useState('');

  void handleSubmit() {
    print('Login: ${email.value} / ${password.value}');
  }

  return form(
    {'onSubmit': (JSObject e) => SyntheticEvent.fromJs(e).preventDefault()},
    [
      input(
        type: 'email',
        value: email.value,
        onChange: (e) => email.set(inputValue(e)),
        placeholder: 'Email',
      ),
      input(
        type: 'password',
        value: password.value,
        onChange: (e) => password.set(inputValue(e)),
        placeholder: 'Password',
      ),
      button(text: 'Log In', onClick: handleSubmit),
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
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';

// Reads the current value from an input change event.
String inputValue(SyntheticEvent event) => switch (event.target) {
  final JSObject target => switch (target['value']) {
    final JSString value => value.toDart,
    _ => '',
  },
  _ => '',
};

ReactElement todoApp() {
  final todos = useState<List<Todo>>([]);
  final newTodo = useState('');

  void addTodo() {
    if (newTodo.value.trim().isEmpty) return;

    todos.setWithUpdater((prev) => [
      ...prev,
      Todo(id: DateTime.now().toString(), title: newTodo.value, completed: false),
    ]);
    newTodo.set('');
  }

  void toggleTodo(String id) {
    todos.setWithUpdater((prev) => prev.map((todo) =>
      todo.id == id
          ? Todo(id: todo.id, title: todo.title, completed: !todo.completed)
          : todo
    ).toList());
  }

  return div(
    className: 'todo-app',
    children: [
      h1('Todo List'),

      form(
        {
          'onSubmit': (JSObject e) {
            SyntheticEvent.fromJs(e).preventDefault();
            addTodo();
          },
        },
        [
          input(
            value: newTodo.value,
            onChange: (e) => newTodo.set(inputValue(e)),
            placeholder: 'What needs to be done?',
          ),
          button(text: 'Add', onClick: addTodo),
        ],
      ),

      ul(
        children: todos.value.map((todo) =>
          li(
            todo.title,
            props: {
              'key': todo.id,
              'onClick': () => toggleTodo(todo.id),
            },
            className: todo.completed ? 'completed' : '',
          )
        ).toList(),
      ),

      pEl('${todos.value.where((t) => !t.completed).length} items left'),
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
  final root = Document.getElementById('root');
  (root != null)
      ? ReactDOM.createRoot(root).render(todoApp())
      : throw StateError('Root element not found');
}
```

## Source Code

The source code is available on [GitHub](https://github.com/MelbourneDeveloper/dart_node/tree/main/packages/dart_node_react).
