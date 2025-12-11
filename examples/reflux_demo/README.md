# Reflux Demo

A counter app demonstrating **shared state logic** between Flutter and React web.

## Project Structure

```
packages/
├── counter_state/       # SHARED: Pure Dart state management
│   └── lib/counter_state.dart
├── flutter_counter/     # Flutter app
│   ├── lib/main.dart
│   └── test/widget_test.dart
└── web_counter/         # React web app
    ├── lib/counter_app.dart
    ├── web/app.dart
    └── test/web_counter_test.dart
```

## Running the Flutter App

```bash
cd packages/flutter_counter
flutter run
```

## Running the Web App

```bash
cd packages/web_counter

# Compile Dart to JS
dart compile js web/app.dart -o web/build/app.js

# Start a local server
python3 -m http.server 8080

# Open in browser
open http://localhost:8080/web/
```

## Running Tests

```bash
# Flutter tests
cd packages/flutter_counter
flutter test

# Web tests
cd packages/web_counter
dart test -p chrome
```

## The Point

Write your state management ONCE, use it EVERYWHERE:

- `counter_state`: Pure Dart - actions, reducer, selectors, middleware
- `flutter_counter`: Flutter UI consuming the shared state
- `web_counter`: React web UI consuming the shared state

Both UIs import the SAME state logic. No duplication. No drift.

## Features Demonstrated

### State (counter_state)
- **State as Record**: `typedef CounterState = ({int count, int step, List<int> history})`
- **Sealed Action Classes**: Type-safe actions with exhaustive pattern matching
- **Reducer**: Pure function with switch expressions on action types
- **Selectors**: Memoized with `createSelector1`
- **Middleware**: Optional logging

### Flutter UI (flutter_counter)
- Standard Flutter widgets
- Subscribes to store for rebuilds via setState
- Comprehensive widget tests with golden captures

### Web UI (web_counter)
- Uses React with JSX-like DSL (`$div`, `$button`, etc.)
- Subscribes to store for re-renders
- Full UI integration tests

## Key Concepts

### 1. State is Just a Record
```dart
typedef CounterState = ({int count, int step, List<int> history});
```
No classes needed. Structural typing FTW.

### 2. Actions as Sealed Classes (Type-Safe!)
```dart
sealed class CounterAction extends Action {
  const CounterAction();
}

final class Increment extends CounterAction {
  const Increment();
}

final class Decrement extends CounterAction {
  const Decrement();
}

final class SetStep extends CounterAction {
  const SetStep(this.step);
  final int step;
}

final class Reset extends CounterAction {
  const Reset();
}
```

### 3. Reducers with Pattern Matching on TYPES (not strings!)
```dart
CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + state.step, ...),
      Decrement() => (count: state.count - state.step, ...),
      SetStep(:final step) => (count: state.count, step: step, ...),
      Reset() => (count: 0, step: state.step, history: [0]),
      _ => state, // Handle system actions
    };
```

### 4. Memoized Selectors
```dart
final selectCanUndo = createSelector1(
  selectHistory,
  (history) => history.length > 1,
);
```

### 5. One Store, Many UIs
```dart
// Flutter
final store = createCounterStore();
// Use store.subscribe() with setState

// Web
final store = createCounterStore();
// Use React hooks with store subscription
```

Same store API. Same actions. Same state. Different UI.

## Dispatching Actions

```dart
// Dispatch type-safe actions - no strings!
store.dispatch(const Increment());
store.dispatch(const Decrement());
store.dispatch(const SetStep(5));
store.dispatch(const Reset());
```

## Why This Matters

1. **Type Safety**: Pattern matching ensures exhaustive handling of all action types
2. **Test State Once**: Unit test reducers, selectors in isolation
3. **UI Tests Are Simple**: Just verify UI reacts to state changes
4. **No Logic Drift**: Flutter and web can't diverge - same code
5. **Easy Refactoring**: Change state logic in ONE place
