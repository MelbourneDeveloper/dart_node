---
layout: layouts/docs.njk
title: dart_node_react_native
description: React Native bindings for building cross-platform mobile apps in Dart with Expo.
eleventyNavigation:
  key: dart_node_react_native
  parent: Packages
  order: 4
---

`dart_node_react_native` provides type-safe React Native bindings for building iOS and Android apps in Dart. Combined with Expo, you get a complete mobile development experience.

## Installation

```yaml
dependencies:
  dart_node_react_native: ^0.2.0
  dart_node_react: ^0.2.0  # Required peer dependency
```

Set up your Expo project:

```bash
npx create-expo-app my-app
cd my-app
```

## Quick Start

```dart
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:dart_node_react/dart_node_react.dart';

ReactElement app() {
  return safeAreaView(
    style: {'flex': 1, 'backgroundColor': '#fff'},
    children: [
      view(
        style: {'padding': 20},
        children: [
          rnText(
            style: {'fontSize': 24, 'fontWeight': 'bold'},
            children: [text('Hello, Dart!')],
          ),
          rnText(
            children: [text('Welcome to React Native with Dart.')],
          ),
        ],
      ),
    ],
  );
}
```

## Components

### View

The fundamental building block, similar to `div` in web:

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

For displaying text (note: `rnText` to avoid conflict with React's `text()`):

```dart
rnText(
  style: {
    'fontSize': 18,
    'fontWeight': '600',
    'color': '#333',
    'textAlign': 'center',
  },
  children: [text('Hello, World!')],
)
```

### TextInput

For user text input:

```dart
ReactElement searchInput() {
  final (query, setQuery) = useState('');

  return textInput(
    value: query,
    onChangeText: setQuery,
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

For pressable elements with opacity feedback:

```dart
touchableOpacity(
  onPress: () => print('Pressed!'),
  style: {
    'backgroundColor': '#007AFF',
    'padding': 12,
    'borderRadius': 8,
  },
  children: [
    rnText(
      style: {'color': '#fff', 'textAlign': 'center'},
      children: [text('Press Me')],
    ),
  ],
)
```

### Button

Simple button component:

```dart
rnButton(
  title: 'Submit',
  onPress: () => print('Button pressed!'),
  color: '#007AFF',
)
```

### ScrollView

For scrollable content:

```dart
scrollView(
  style: {'flex': 1},
  contentContainerStyle: {'padding': 20},
  children: [
    // Many children that exceed screen height
    ...items.map((item) => itemCard(item)),
  ],
)
```

### FlatList

For efficient list rendering:

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

For displaying images:

```dart
// Local image
image(
  source: AssetSource('assets/logo.png'),
  style: {'width': 100, 'height': 100},
)

// Remote image
image(
  source: UriSource('https://example.com/image.jpg'),
  style: {'width': 200, 'height': 150},
  resizeMode: 'cover',
)
```

### SafeAreaView

For respecting device safe areas (notch, home indicator):

```dart
safeAreaView(
  style: {'flex': 1},
  children: [
    // Content here is safe from notches and system UI
  ],
)
```

### ActivityIndicator

Loading spinner:

```dart
activityIndicator(
  size: 'large',
  color: '#007AFF',
)
```

## Styling

React Native uses JavaScript objects for styles (like React inline styles but with different properties):

```dart
view(
  style: {
    // Layout
    'flex': 1,
    'flexDirection': 'column',  // or 'row'
    'justifyContent': 'center',  // main axis
    'alignItems': 'center',      // cross axis

    // Spacing
    'padding': 20,
    'paddingHorizontal': 16,
    'margin': 10,
    'marginTop': 20,

    // Appearance
    'backgroundColor': '#ffffff',
    'borderRadius': 8,
    'borderWidth': 1,
    'borderColor': '#ccc',

    // Shadows (iOS)
    'shadowColor': '#000',
    'shadowOffset': {'width': 0, 'height': 2},
    'shadowOpacity': 0.25,
    'shadowRadius': 4,

    // Shadows (Android)
    'elevation': 5,
  },
  children: [...],
)
```

## Navigation

Use with React Navigation (via JS interop):

```dart
// Define screens
ReactElement homeScreen({required NavigationProps nav}) {
  return view(children: [
    rnText(children: [text('Home Screen')]),
    touchableOpacity(
      onPress: () => nav.navigate('Details', {'id': 123}),
      children: [rnText(children: [text('Go to Details')])],
    ),
  ]);
}

ReactElement detailsScreen({required NavigationProps nav}) {
  final id = nav.route.params['id'];

  return view(children: [
    rnText(children: [text('Details for $id')]),
    touchableOpacity(
      onPress: () => nav.goBack(),
      children: [rnText(children: [text('Go Back')])],
    ),
  ]);
}
```

## Complete Example

```dart
import 'package:dart_node_react_native/dart_node_react_native.dart';
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

  return safeAreaView(
    style: {'flex': 1, 'backgroundColor': '#f5f5f5'},
    children: [
      // Header
      view(
        style: {
          'padding': 20,
          'backgroundColor': '#007AFF',
        },
        children: [
          rnText(
            style: {
              'fontSize': 24,
              'fontWeight': 'bold',
              'color': '#fff',
            },
            children: [text('My Todos')],
          ),
        ],
      ),

      // Input
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
            value: input,
            onChangeText: setInput,
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
              rnText(
                style: {'color': '#fff', 'fontWeight': '600'},
                children: [text('Add')],
              ),
            ],
          ),
        ],
      ),

      // List
      flatList<Todo>(
        data: todos,
        keyExtractor: (todo, _) => todo.id,
        renderItem: (info) => touchableOpacity(
          onPress: () => toggleTodo(info.item.id),
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
                'borderColor': info.item.completed ? '#4CAF50' : '#ccc',
                'backgroundColor': info.item.completed ? '#4CAF50' : 'transparent',
                'marginRight': 12,
              },
            ),
            rnText(
              style: {
                'flex': 1,
                'fontSize': 16,
                'textDecorationLine': info.item.completed ? 'line-through' : 'none',
                'color': info.item.completed ? '#999' : '#333',
              },
              children: [text(info.item.title)],
            ),
          ],
        ),
        style: {'flex': 1},
      ),

      // Footer
      view(
        style: {'padding': 16, 'backgroundColor': '#fff'},
        children: [
          rnText(
            style: {'textAlign': 'center', 'color': '#666'},
            children: [
              text('${todos.where((t) => !t.completed).length} items remaining'),
            ],
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

## API Reference

See the [full API documentation](/api/dart_node_react_native/) for all available components and types.
