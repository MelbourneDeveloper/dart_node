
`dart_node_react_native` 提供类型安全的 React Native 绑定，用于在 Dart 中构建 iOS 和 Android 应用程序。结合 Expo，您可以获得完整的移动开发体验。

## 安装

```yaml
dependencies:
  dart_node_react_native: ^0.11.0-beta
  dart_node_react: ^0.11.0-beta  # 必需的对等依赖
```

设置您的 Expo 项目：

```bash
npx create-expo-app my-app
cd my-app
```

## 快速开始

```dart
import 'package:dart_node_react/dart_node_react.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';

ReactElement app() {
  return safeAreaView(
    style: {'flex': 1, 'backgroundColor': '#fff'},
    children: [
      view(
        style: {'padding': 20},
        children: [
          text(
            'Hello, Dart!',
            style: {'fontSize': 24, 'fontWeight': 'bold'},
          ),
          text('Welcome to React Native with Dart.'),
        ],
      ),
    ],
  );
}
```

## 组件

### View

基础构建块，类似于 Web 中的 `div`：

```dart
view(
  style: {
    'flex': 1,
    'flexDirection': 'row',
    'justifyContent': 'center',
    'alignItems': 'center',
    'backgroundColor': '#f5f5f5',
  },
  children: [...],
)
```

### Text

用于显示文本：

```dart
text(
  'Hello, World!',
  style: {
    'fontSize': 18,
    'fontWeight': '600',
    'color': '#333',
    'textAlign': 'center',
  },
)
```

### TextInput

用于用户文本输入：

```dart
ReactElement searchInput() {
  final query = useState('');

  return textInput(
    value: query.value,
    onChangeText: (value) => query.set(value),
    placeholder: 'Search...',
    style: {
      'height': 40,
      'borderWidth': 1,
      'borderColor': '#ccc',
      'borderRadius': 8,
      'paddingHorizontal': 12,
    },
  );
}
```

### TouchableOpacity

用于具有透明度反馈的可按压元素：

```dart
touchableOpacity(
  onPress: () => print('Pressed!'),
  style: {
    'backgroundColor': '#007AFF',
    'padding': 12,
    'borderRadius': 8,
  },
  children: [
    text(
      'Press Me',
      style: {'color': '#fff', 'textAlign': 'center'},
    ),
  ],
)
```

### Button

简单的按钮组件：

```dart
rnButton(
  title: 'Submit',
  onPress: () => print('Button pressed!'),
  color: '#007AFF',
)
```

### ScrollView

用于可滚动内容：

```dart
scrollView(
  style: {'flex': 1},
  contentContainerStyle: {'padding': 20},
  children: [
    // 超出屏幕高度的多个子元素
    ...items.map((item) => itemCard(item)),
  ],
)
```

### FlatList

用于高效的列表渲染：

```dart
ReactElement userList({required List<User> users}) {
  return flatList<User>(
    data: users,
    keyExtractor: (user, _) => user.id,
    renderItem: (info) => userCard(user: info.item),
    ItemSeparatorComponent: () => view(
      style: {'height': 1, 'backgroundColor': '#eee'},
    ),
  );
}
```

### Image

用于显示图片：

```dart
// 本地图片
image(
  source: AssetSource('assets/logo.png'),
  style: {'width': 100, 'height': 100},
)

// 远程图片
image(
  source: UriSource('https://example.com/image.jpg'),
  style: {'width': 200, 'height': 150},
  resizeMode: 'cover',
)
```

### SafeAreaView

用于适应设备安全区域（刘海、Home 指示器）：

```dart
safeAreaView(
  style: {'flex': 1},
  children: [
    // 此处内容不会被刘海和系统 UI 遮挡
  ],
)
```

### ActivityIndicator

加载指示器：

```dart
activityIndicator(
  size: 'large',
  color: '#007AFF',
)
```

## 样式

React Native 使用 JavaScript 对象来设置样式（类似于 React 内联样式但属性不同）：

```dart
view(
  style: {
    // 布局
    'flex': 1,
    'flexDirection': 'column',  // 或 'row'
    'justifyContent': 'center',  // 主轴
    'alignItems': 'center',      // 交叉轴

    // 间距
    'padding': 20,
    'paddingHorizontal': 16,
    'margin': 10,
    'marginTop': 20,

    // 外观
    'backgroundColor': '#ffffff',
    'borderRadius': 8,
    'borderWidth': 1,
    'borderColor': '#ccc',

    // 阴影（iOS）
    'shadowColor': '#000',
    'shadowOffset': {'width': 0, 'height': 2},
    'shadowOpacity': 0.25,
    'shadowRadius': 4,

    // 阴影（Android）
    'elevation': 5,
  },
  children: [...],
)
```

## 导航

与 React Navigation 一起使用（通过 JS 互操作）：

```dart
// 定义屏幕
ReactElement homeScreen({required NavigationProps nav}) {
  return view(children: [
    text('Home Screen'),
    touchableOpacity(
      onPress: () => nav.navigate('Details', {'id': 123}),
      children: [text('Go to Details')])],
    ),
  ]);
}

ReactElement detailsScreen({required NavigationProps nav}) {
  final id = nav.route.params['id'];

  return view(children: [
    text('Details for $id'),
    touchableOpacity(
      onPress: () => nav.goBack(),
      children: [text('Go Back')])],
    ),
  ]);
}
```

## 完整示例

```dart
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:dart_node_react/dart_node_react.dart';

ReactElement todoApp() {
  final todos = useState<List<Todo>>([]);
  final inputValue = useState('');

  void addTodo() {
    if (inputValue.value.trim().isEmpty) return;

    todos.setWithUpdater((prev) => [
      ...prev,
      Todo(id: DateTime.now().toString(), title: inputValue.value, completed: false),
    ]);
    inputValue.set('');
  }

  void toggleTodo(String id) {
    todos.setWithUpdater((prev) => prev.map((todo) =>
      todo.id == id
          ? Todo(id: todo.id, title: todo.title, completed: !todo.completed)
          : todo
    ).toList());
  }

  return safeAreaView(
    style: {'flex': 1, 'backgroundColor': '#f5f5f5'},
    children: [
      // 头部
      view(
        style: {
          'padding': 20,
          'backgroundColor': '#007AFF',
        },
        children: [
          text(
            'My Todos',
            style: {
              'fontSize': 24,
              'fontWeight': 'bold',
              'color': '#fff',
            },
          ),
        ],
      ),

      // 输入框
      view(
        style: {
          'flexDirection': 'row',
          'padding': 16,
          'backgroundColor': '#fff',
        },
        children: [
          textInput(
            style: {
              'flex': 1,
              'height': 44,
              'borderWidth': 1,
              'borderColor': '#ddd',
              'borderRadius': 8,
              'paddingHorizontal': 12,
            },
            value: inputValue.value,
            onChangeText: (value) => inputValue.set(value),
            placeholder: 'Add a todo...',
          ),
          touchableOpacity(
            onPress: addTodo,
            style: {
              'marginLeft': 12,
              'backgroundColor': '#007AFF',
              'paddingHorizontal': 20,
              'justifyContent': 'center',
              'borderRadius': 8,
            },
            children: [
              text(
                'Add',
                style: {'color': '#fff', 'fontWeight': '600'},
              ),
            ],
          ),
        ],
      ),

      // 列表
      scrollView(
        style: {'flex': 1},
        children: todos.value.map((todo) => touchableOpacity(
          onPress: () => toggleTodo(todo.id),
          style: {
            'flexDirection': 'row',
            'alignItems': 'center',
            'padding': 16,
            'backgroundColor': '#fff',
            'borderBottomWidth': 1,
            'borderBottomColor': '#eee',
          },
          children: [
            view(
              style: {
                'width': 24,
                'height': 24,
                'borderRadius': 12,
                'borderWidth': 2,
                'borderColor': todo.completed ? '#4CAF50' : '#ccc',
                'backgroundColor': todo.completed ? '#4CAF50' : 'transparent',
                'marginRight': 12,
              },
            ),
            text(
              todo.title,
              style: {
                'flex': 1,
                'fontSize': 16,
                'textDecorationLine': todo.completed ? 'line-through' : 'none',
                'color': todo.completed ? '#999' : '#333',
              },
            ),
          ],
        )).toList(),
      ),

      // 底部
      view(
        style: {'padding': 16, 'backgroundColor': '#fff'},
        children: [
          text(
            '${todos.value.where((t) => !t.completed).length} items remaining',
            style: {'textAlign': 'center', 'color': '#666'},
          ),
        ],
      ),
    ],
  );
}

class Todo {
  final String id;
  final String title;
  final bool completed;

  Todo({required this.id, required this.title, required this.completed});
}
```

## API 参考

请参阅[完整 API 文档](/api/dart_node_react_native/)了解所有可用组件和类型。
