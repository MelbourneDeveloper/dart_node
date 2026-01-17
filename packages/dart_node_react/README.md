# dart_node_react

Type-safe React bindings for building web applications in Dart. If you know React, you'll feel right at home.

## Installation

```yaml
dependencies:
  dart_node_react: ^0.11.0-beta
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

Returns a `StateHook<T>` with `.value`, `.set()`, and `.setWithUpdater()`:

```dart
ReactElement counter() {
  final count = useState(0);

  return div(children: [
    p(children: [text('Count: ${count.value}')]),
    button(
      onClick: (_) => count.setWithUpdater((c) => c + 1),
      children: [text('Increment')],
    ),
    button(
      onClick: (_) => count.setWithUpdater((c) => c - 1),
      children: [text('Decrement')],
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

  return p(children: [text('Seconds: ${seconds.value}')]);
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
  final count = useState(0);

  // Only recalculate when count.value changes
  final fib = useMemo(
    () => fibonacci(count.value),
    [count.value],
  );

  return div(children: [
    p(children: [text('Fibonacci of ${count.value} is $fib')]),
  ]);
}
```

### useCallback

```dart
ReactElement searchBox({required void Function(String) onSearch}) {
  final query = useState('');

  // Memoize the callback
  final handleSubmit = useCallback(
    () => onSearch(query.value),
    [query.value, onSearch],
  );

  return form(
    onSubmit: (_) => handleSubmit(),
    children: [
      input(
        value: query.value,
        onChange: (e) => query.set(e.target.value),
      ),
      button(type: 'submit', children: [text('Search')]),
    ],
  );
}
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
  final email = useState('');
  final password = useState('');

  void handleSubmit(Event e) {
    e.preventDefault();
    print('Login: ${email.value} / ${password.value}');
  }

  return form(
    onSubmit: handleSubmit,
    children: [
      input(
        type: 'email',
        value: email.value,
        onChange: (e) => email.set(e.target.value),
        placeholder: 'Email',
      ),
      input(
        type: 'password',
        value: password.value,
        onChange: (e) => password.set(e.target.value),
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
  final todos = useState<List<Todo>>([]);
  final input = useState('');

  void addTodo() {
    if (input.value.trim().isEmpty) return;

    todos.setWithUpdater((prev) => [
      ...prev,
      Todo(id: DateTime.now().toString(), title: input.value, completed: false),
    ]);
    input.set('');
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
      h1(children: [text('Todo List')]),

      form(
        onSubmit: (e) {
          e.preventDefault();
          addTodo();
        },
        children: [
          input(
            value: input.value,
            onChange: (e) => input.set(e.target.value),
            placeholder: 'What needs to be done?',
          ),
          button(type: 'submit', children: [text('Add')]),
        ],
      ),

      ul(
        children: todos.value.map((todo) =>
          li(
            key: todo.id,
            className: todo.completed ? 'completed' : '',
            onClick: (_) => toggleTodo(todo.id),
            children: [text(todo.title)],
          )
        ).toList(),
      ),

      p(children: [
        text('${todos.value.where((t) => !t.completed).length} items left'),
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
  final root = ReactDOM.createRoot(document.getElementById('root'));
  root.render(todoApp());
}
```

## Source Code

The source code is available on [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_react).
