# Statecore Demo

A counter app demonstrating **shared state logic** between React (web) and React Native (mobile).

## Running the Web App

```bash
# 1. Install deps
dart pub get

# 2. Compile Dart to JS
dart compile js web/app.dart -o web/build/app.js

# 3. Start a local server
python3 -m http.server 8080

# 4. Open in browser
open http://localhost:8080/web/
```

## Running Tests

```bash
dart test -p chrome
```

## The Point

Write your state management ONCE, use it EVERYWHERE:

```
lib/
├── state/
│   └── counter_state.dart    # SHARED: Actions, Reducer, Selectors
├── web/
│   └── counter_app.dart      # React web UI
└── mobile/
    └── counter_app.dart      # React Native UI
```

Both UIs import the SAME state logic. No duplication. No drift.

## Features Demonstrated

### State (counter_state.dart)
- **State as Record**: `typedef CounterState = ({int count, int step, List<int> history})`
- **Sealed Action Classes**: Type-safe actions with exhaustive pattern matching
- **Reducer**: Pure function with switch expressions on action types
- **Selectors**: Memoized with `createSelector1`
- **Middleware**: Optional logging

### Web UI (counter_app.dart)
- Uses React with JSX-like DSL (`$div`, `$button`, etc.)
- Subscribes to store for re-renders

### Mobile UI (counter_app.dart)
- Uses React Native components (`view`, `text`, `touchableOpacity`)
- Same store subscription pattern

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
      Reset() => initialState(),
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
// Web
final store = createCounterStore();
// Render React component that uses store

// Mobile
final store = createCounterStore();
// Render React Native component that uses store
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
4. **No Logic Drift**: Web and mobile can't diverge - same code
5. **Easy Refactoring**: Change state logic in ONE place
