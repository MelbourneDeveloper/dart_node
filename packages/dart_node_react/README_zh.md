# dart_node_react

类型安全的 React 绑定，用于在 Dart 中构建 Web 应用程序。如果您熟悉 React，您会感到非常亲切。

## 安装

```yaml
dependencies:
  dart_node_react: ^0.13.0-beta
```

通过 npm 安装 React：

```bash
npm install react react-dom
```

## 快速开始

```dart
import 'dart:js_interop';

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
  if (container case final JSObject c) {
    createRoot(c).render(app());
  }
}
```

## 组件

### 函数组件

```dart
ReactElement greeting({required String name}) {
  return div(
    className: 'greeting',
    children: [
      pEl('Hello, $name!'),
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
      h2(name),
      pEl(email),
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

  return pEl('Seconds: ${seconds.value}');
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
  final inputRef = useRef<JSObject>(null);

  void handleClick() {
    if (inputRef.jsRef.current case final JSObject node) {
      node.callMethod('focus'.toJS);
    }
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

  // 仅当 count.value 变化时重新计算
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

  // 记忆化回调
  final handleSubmit = useCallback(
    () => onSearch(query.value),
    [query.value, onSearch],
  );

  return form(null, [
    input(
      value: query.value,
      onChange: (e) {
        if (e.target case final JSObject t) {
          if (t['value'] case final JSString s) query.set(s.toDart);
        }
      },
    ),
    button(text: 'Search', props: {'type': 'submit', 'onClick': handleSubmit}),
  ]);
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
span('highlight text', className: 'highlight')

// 标题
h1('Title')
h2('Subtitle')

// 段落和文本
pEl('Some text')

// 链接
a(href: 'https://example.com', text: 'Click me')

// 图片
img(src: '/image.png', alt: 'Description')

// 表单
form(null, [...])
input(type: 'text', value: value, onChange: handleChange)
button(text: 'Submit', props: {'type': 'submit'})
```

### 列表

```dart
ReactElement todoList({required List<Todo> todos}) {
  return ul(
    className: 'todo-list',
    children: todos
        .map(
          (todo) => li(
            todo.title,
            props: {'key': todo.id},
          ),
        )
        .toList(),
  );
}
```

### 条件渲染

```dart
ReactElement userStatus({required User? user}) {
  return div(children: [
    user != null
        ? span('Welcome, ${user.name}!')
        : span('Please log in'),
  ]);
}
```

## 事件处理

```dart
ReactElement interactiveButton() {
  void handleClick() {
    print('Button clicked');
  }

  return button(
    text: 'Hover and Click Me',
    onClick: handleClick,
  );
}
```

### 表单事件

```dart
ReactElement loginForm() {
  final email = useState('');
  final password = useState('');

  void handleSubmit(SyntheticEvent e) {
    e.preventDefault();
    print('Login: ${email.value} / ${password.value}');
  }

  String readValue(SyntheticEvent e) => switch (e.target) {
    final JSObject t => switch (t['value']) {
      final JSString s => s.toDart,
      _ => '',
    },
    _ => '',
  };

  return form({'onSubmit': handleSubmit}, [
    input(
      type: 'email',
      value: email.value,
      onChange: (e) => email.set(readValue(e)),
      placeholder: 'Email',
    ),
    input(
      type: 'password',
      value: password.value,
      onChange: (e) => password.set(readValue(e)),
      placeholder: 'Password',
    ),
    button(text: 'Log In', props: {'type': 'submit'}),
  ]);
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
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';

ReactElement todoApp() {
  final todos = useState<List<Todo>>([]);
  final text = useState('');

  void addTodo() {
    if (text.value.trim().isEmpty) return;

    todos.setWithUpdater((prev) => [
      ...prev,
      Todo(id: DateTime.now().toString(), title: text.value, completed: false),
    ]);
    text.set('');
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

      form({
        'onSubmit': (SyntheticEvent e) {
          e.preventDefault();
          addTodo();
        },
      }, [
        input(
          value: text.value,
          onChange: (e) {
            if (e.target case final JSObject t) {
              if (t['value'] case final JSString s) text.set(s.toDart);
            }
          },
          placeholder: 'What needs to be done?',
        ),
        button(text: 'Add', props: {'type': 'submit'}),
      ]),

      ul(
        children: todos.value
            .map(
              (todo) => li(
                todo.title,
                className: todo.completed ? 'completed' : '',
                props: {
                  'key': todo.id,
                  'onClick': () => toggleTodo(todo.id),
                },
              ),
            )
            .toList(),
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
  final container = Document.getElementById('root');
  if (container case final JSObject c) {
    createRoot(c).render(todoApp());
  }
}
```

## 源代码

源代码可在 [GitHub](https://github.com/MelbourneDeveloper/dart_node/tree/main/packages/dart_node_react) 上获取。
