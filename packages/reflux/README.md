# Reflux

Redux-inspired state management for **React with Dart ([dart_node](https://dartnode.dev))** and **Flutter**.

Predictable state container with full type safety using Dart's sealed classes for exhaustive pattern matching.

## Getting Started

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

## Part of dart_node

[GitHub](https://github.com/MelbourneDeveloper/dart_node)
