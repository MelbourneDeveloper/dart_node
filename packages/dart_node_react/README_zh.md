# dart_node_react

类型安全的 React 绑定，用于在 Dart 中构建 Web 应用程序。如果您熟悉 React，您会感到非常亲切。

## 安装

```yaml
dependencies:
  dart_node_react: ^0.11.0-beta
```

通过 npm 安装 React：

```bash
npm install react react-dom
```

## 快速开始

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

## 组件

### 函数组件

```dart
ReactElement greeting({required String name}) {
  return div(
    className: 'greeting',
    children: [
      text('Hello, $name!'),
    ],
  );
}

// 使用方式
greeting(name: 'World');
```

### 带 Props 的组件

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

返回包含 `.value`、`.set()` 和 `.setWithUpdater()` 的 `StateHook<T>`：

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

用于昂贵的初始状态计算：

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

    // 清理函数
    return () => timer.cancel();
  }, []); // 空依赖数组 = 仅在挂载时运行一次

  return p(children: [text('Seconds: ${seconds.value}')]);
}
```

### useLayoutEffect

useEffect 的同步版本，在屏幕更新前运行：

```dart
useLayoutEffect(() {
  // DOM 测量
  return () { /* 清理 */ };
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

  // 仅当 count.value 变化时重新计算
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

  // 记忆化回调
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

在 React DevTools 中显示自定义标签：

```dart
useDebugValue<bool>(
  isOnline.value,
  (isOnline) => isOnline ? 'Online' : 'Not Online',
);
```

## 元素

### HTML 元素

```dart
// Div 和 span
div(className: 'container', children: [...])
span(className: 'highlight', children: [...])

// 标题
h1(children: [text('Title')])
h2(children: [text('Subtitle')])

// 段落和文本
p(children: [text('Some text')])
text('Raw text content')

// 链接
a(href: 'https://example.com', children: [text('Click me')])

// 图片
img(src: '/image.png', alt: 'Description')

// 表单
form(onSubmit: handleSubmit, children: [...])
input(type: 'text', value: value, onChange: handleChange)
button(type: 'submit', children: [text('Submit')])
```

### 列表

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

### 条件渲染

```dart
ReactElement userStatus({required User? user}) {
  return div(children: [
    user != null
        ? span(children: [text('Welcome, ${user.name}!')])
        : span(children: [text('Please log in')]),
  ]);
}
```

## 事件处理

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

### 表单事件

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

## 样式

### 内联样式

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

### CSS 类

```dart
div(
  className: 'card card-primary',
  children: [...],
)
```

## 完整示例

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

## 源代码

源代码可在 [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_react) 上获取。
