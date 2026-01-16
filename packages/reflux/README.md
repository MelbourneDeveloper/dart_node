
Reflux is a state management library for **React with Dart** and **Flutter**. It provides a predictable state container with full type safety using Dart's sealed classes for exhaustive pattern matching.

## Installation

```yaml
dependencies:
  reflux: ^0.9.0
```

## Core Concepts

### Store

The store holds the complete state tree of your application. There should be a single store for the entire app.

```dart
import 'package:reflux/reflux.dart';

final store = createStore(counterReducer, (count: 0));
```

### Actions

Actions are sealed classes that describe what happened. Use Dart's pattern matching on the actual TYPE, not strings.

```dart
sealed class CounterAction extends Action {}

final class Increment extends CounterAction {}
final class Decrement extends CounterAction {}
final class SetValue extends CounterAction {
  const SetValue(this.value);
  final int value;
}
```

### Reducers

Reducers are pure functions that specify how state changes in response to actions.

```dart
typedef CounterState = ({int count});

CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      Decrement() => (count: state.count - 1),
      SetValue(:final value) => (count: value),
      _ => state,
    };
```

## Quick Start

```dart
import 'package:reflux/reflux.dart';

// State as a record
typedef CounterState = ({int count});

// Actions as sealed classes
sealed class CounterAction extends Action {}
final class Increment extends CounterAction {}
final class Decrement extends CounterAction {}

// Reducer with pattern matching
CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      Decrement() => (count: state.count - 1),
      _ => state,
    };

void main() {
  final store = createStore(counterReducer, (count: 0));

  store.subscribe(() => print('Count: ${store.getState().count}'));

  store.dispatch(Increment()); // Count: 1
  store.dispatch(Increment()); // Count: 2
  store.dispatch(Decrement()); // Count: 1
}
```

## Middleware

Middleware provides a third-party extension point between dispatching an action and the reducer.

```dart
Middleware<CounterState> loggerMiddleware() =>
    (api) => (next) => (action) {
          print('Dispatching: ${action.runtimeType}');
          next(action);
          print('State: ${api.getState()}');
        };

final store = createStore(
  counterReducer,
  (count: 0),
  enhancer: applyMiddleware([loggerMiddleware()]),
);
```

## Selectors

Selectors extract and memoize derived data from the state.

```dart
final getCount = createSelector1(
  (CounterState s) => s.count,
  (count) => count * 2,
);

final doubledCount = getCount(store.getState());
```

## Time Travel

The TimeTravelEnhancer allows you to undo/redo state changes.

```dart
final timeTravel = TimeTravelEnhancer<CounterState>();

final store = createStore(
  counterReducer,
  (count: 0),
  enhancer: timeTravel.enhancer,
);

store.dispatch(Increment());
store.dispatch(Increment());

timeTravel.undo(); // Go back one step
timeTravel.redo(); // Go forward one step
```

## API Reference

See the [full API documentation](/api/reflux/) for all available functions and types.

## Source Code

The source code is available on [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/reflux).
