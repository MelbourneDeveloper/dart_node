---
layout: layouts/docs.njk
title: dart_node_statecore
description: Redux-style predictable state management for Dart applications.
eleventyNavigation:
  key: dart_node_statecore
  parent: Packages
  order: 9
---

`dart_node_statecore` is a predictable state container for Dart applications, inspired by Redux patterns. It provides unidirectional data flow with full type safety using Dart's sealed classes for exhaustive pattern matching.

## Installation

```yaml
dependencies:
  dart_node_statecore: ^0.1.0-beta
```

## Core Concepts

- **Store**: Holds the complete state tree of your application
- **Actions**: Sealed classes that describe what happened
- **Reducers**: Pure functions that specify how state changes
- **Middleware**: Extension points for adding custom behavior
- **Selectors**: Functions that extract and memoize derived data

## Quick Start

```dart
import 'package:dart_node_statecore/dart_node_statecore.dart';

// Define state as a record
typedef CounterState = ({int count});

// Define actions as sealed classes
sealed class CounterAction extends Action {}
final class Increment extends CounterAction {}
final class Decrement extends CounterAction {}
final class SetValue extends CounterAction {
  const SetValue(this.value);
  final int value;
}

// Create a reducer with exhaustive pattern matching
CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      Decrement() => (count: state.count - 1),
      SetValue(:final value) => (count: value),
      _ => state,
    };

void main() {
  // Create the store
  final store = createStore(counterReducer, (count: 0));

  // Subscribe to changes
  store.subscribe(() => print('Count: ${store.getState().count}'));

  // Dispatch actions
  store.dispatch(Increment()); // Count: 1
  store.dispatch(Increment()); // Count: 2
  store.dispatch(Decrement()); // Count: 1
  store.dispatch(SetValue(42)); // Count: 42
}
```

## Defining Actions

Use sealed classes for type-safe actions:

```dart
sealed class TodoAction extends Action {}

final class AddTodo extends TodoAction {
  const AddTodo(this.text);
  final String text;
}

final class ToggleTodo extends TodoAction {
  const ToggleTodo(this.id);
  final int id;
}

final class RemoveTodo extends TodoAction {
  const RemoveTodo(this.id);
  final int id;
}

final class ClearCompleted extends TodoAction {}
```

## Writing Reducers

Reducers are pure functions that take state and action, returning new state:

```dart
typedef Todo = ({int id, String text, bool completed});
typedef TodoState = ({List<Todo> todos, int nextId});

TodoState todoReducer(TodoState state, Action action) => switch (action) {
  AddTodo(:final text) => (
    todos: [...state.todos, (id: state.nextId, text: text, completed: false)],
    nextId: state.nextId + 1,
  ),
  ToggleTodo(:final id) => (
    todos: state.todos.map((t) =>
      t.id == id ? (id: t.id, text: t.text, completed: !t.completed) : t
    ).toList(),
    nextId: state.nextId,
  ),
  RemoveTodo(:final id) => (
    todos: state.todos.where((t) => t.id != id).toList(),
    nextId: state.nextId,
  ),
  ClearCompleted() => (
    todos: state.todos.where((t) => !t.completed).toList(),
    nextId: state.nextId,
  ),
  _ => state,
};
```

## Combining Reducers

For complex applications, split reducers by domain:

```dart
typedef AppState = ({
  TodoState todos,
  UserState user,
  SettingsState settings,
});

final rootReducer = combineReducers<AppState>({
  'todos': (state, action) => (
    todos: todoReducer(state.todos, action),
    user: state.user,
    settings: state.settings,
  ),
  'user': (state, action) => (
    todos: state.todos,
    user: userReducer(state.user, action),
    settings: state.settings,
  ),
  'settings': (state, action) => (
    todos: state.todos,
    user: state.user,
    settings: settingsReducer(state.settings, action),
  ),
});
```

## Selectors

Extract and memoize derived data:

```dart
// Simple selector
int selectTodoCount(TodoState state) => state.todos.length;

// Memoized selector
final selectCompletedTodos = createSelector(
  (TodoState state) => state.todos,
  (List<Todo> todos) => todos.where((t) => t.completed).toList(),
);

// Composed selectors
final selectCompletedCount = createSelector(
  selectCompletedTodos,
  (List<Todo> completed) => completed.length,
);
```

## Middleware

Add custom behavior like logging or async operations:

```dart
// Logging middleware
Middleware<S> loggingMiddleware<S>() => (store) => (next) => (action) {
  print('Dispatching: $action');
  final result = next(action);
  print('Next state: ${store.getState()}');
  return result;
};

// Thunk middleware for async actions
Middleware<S> thunkMiddleware<S>() => (store) => (next) => (action) {
  if (action is ThunkAction<S>) {
    return action(store.dispatch, store.getState);
  }
  return next(action);
};

// Apply middleware
final store = createStore(
  reducer,
  initialState,
  applyMiddleware([
    loggingMiddleware(),
    thunkMiddleware(),
  ]),
);
```

## Async Actions with Thunks

```dart
typedef ThunkAction<S> = Future<void> Function(
  void Function(Action) dispatch,
  S Function() getState,
);

// Async action creator
ThunkAction<AppState> fetchTodos() => (dispatch, getState) async {
  dispatch(FetchTodosStarted());

  try {
    final todos = await api.getTodos();
    dispatch(FetchTodosSuccess(todos));
  } catch (e) {
    dispatch(FetchTodosError(e.toString()));
  }
};

// Dispatch async action
store.dispatch(fetchTodos());
```

## Store Enhancers

Enhance store capabilities:

```dart
// DevTools enhancer
StoreEnhancer<S> devToolsEnhancer<S>() => (createStore) =>
  (reducer, initialState, enhancer) {
    final store = createStore(reducer, initialState, enhancer);
    // Add devtools integration...
    return store;
  };

// Compose enhancers
final store = createStore(
  reducer,
  initialState,
  compose([
    applyMiddleware([loggingMiddleware()]),
    devToolsEnhancer(),
  ]),
);
```

## Complete Example: Todo App

```dart
import 'package:dart_node_statecore/dart_node_statecore.dart';

// State
typedef Todo = ({int id, String text, bool completed});
typedef TodoState = ({List<Todo> todos, int nextId, String filter});

// Actions
sealed class TodoAction extends Action {}
final class AddTodo extends TodoAction {
  const AddTodo(this.text);
  final String text;
}
final class ToggleTodo extends TodoAction {
  const ToggleTodo(this.id);
  final int id;
}
final class SetFilter extends TodoAction {
  const SetFilter(this.filter);
  final String filter; // 'all', 'active', 'completed'
}

// Reducer
TodoState todoReducer(TodoState state, Action action) => switch (action) {
  AddTodo(:final text) => (
    todos: [...state.todos, (id: state.nextId, text: text, completed: false)],
    nextId: state.nextId + 1,
    filter: state.filter,
  ),
  ToggleTodo(:final id) => (
    todos: state.todos.map((t) =>
      t.id == id ? (id: t.id, text: t.text, completed: !t.completed) : t
    ).toList(),
    nextId: state.nextId,
    filter: state.filter,
  ),
  SetFilter(:final filter) => (
    todos: state.todos,
    nextId: state.nextId,
    filter: filter,
  ),
  _ => state,
};

// Selectors
List<Todo> selectFilteredTodos(TodoState state) => switch (state.filter) {
  'active' => state.todos.where((t) => !t.completed).toList(),
  'completed' => state.todos.where((t) => t.completed).toList(),
  _ => state.todos,
};

void main() {
  final store = createStore(
    todoReducer,
    (todos: <Todo>[], nextId: 1, filter: 'all'),
  );

  store.subscribe(() {
    final state = store.getState();
    final filtered = selectFilteredTodos(state);
    print('Filter: ${state.filter}, Todos: ${filtered.length}');
  });

  store.dispatch(AddTodo('Learn Dart'));
  store.dispatch(AddTodo('Build app'));
  store.dispatch(ToggleTodo(1));
  store.dispatch(SetFilter('active'));
}
```

## API Reference

See the [full API documentation](/api/dart_node_statecore/) for all available functions and types.
