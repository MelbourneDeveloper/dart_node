import 'package:dart_node_statecore/src/types.dart';

/// A slice reducer handles a specific part of the state tree.
typedef SliceReducer<S, K> = K Function(K state, Action action);

/// Definition for a state slice with its key, reducer, and initial state.
typedef SliceDefinition<S, K> = ({
  K Function(S) selector,
  S Function(S, K) updater,
  SliceReducer<S, K> reducer,
  K initialState,
});

/// Combines multiple reducers into a single reducer function.
///
/// This is different from Redux's combineReducers in that it's fully typed
/// and uses a record-based state structure for better type safety.
///
/// Example:
/// ```dart
/// typedef AppState = ({int counter, List<String> todos});
///
/// final reducer = combineReducers<AppState>(
///   initialState: (counter: 0, todos: []),
///   slices: [
///     (
///       selector: (s) => s.counter,
///       updater: (s, v) => (counter: v, todos: s.todos),
///       reducer: counterReducer,
///       initialState: 0,
///     ),
///     (
///       selector: (s) => s.todos,
///       updater: (s, v) => (counter: s.counter, todos: v),
///       reducer: todosReducer,
///       initialState: <String>[],
///     ),
///   ],
/// );
/// ```
Reducer<S> combineReducers<S>({
  required S initialState,
  required List<SliceDefinition<S, dynamic>> slices,
}) =>
    (state, action) {
      var hasChanged = false;
      var nextState = state;

      for (final slice in slices) {
        final previousSliceState = slice.selector(nextState);
        final nextSliceState = slice.reducer(previousSliceState, action);

        if (!identical(previousSliceState, nextSliceState)) {
          hasChanged = true;
          nextState = slice.updater(nextState, nextSliceState);
        }
      }

      return hasChanged ? nextState : state;
    };

/// A simpler way to combine reducers using a Map-based state.
///
/// This is closer to Redux's original combineReducers API but with
/// less type safety. Prefer [combineReducers] for fully typed state.
///
/// Example:
/// ```dart
/// final reducer = combineReducersMap({
///   'counter': counterReducer,
///   'todos': todosReducer,
/// });
/// ```
Reducer<Map<String, Object?>> combineReducersMap(
  Map<String, Reducer<Object?>> reducers,
) =>
    (state, action) {
      var hasChanged = false;
      final nextState = <String, Object?>{};

      for (final entry in reducers.entries) {
        final key = entry.key;
        final reducer = entry.value;
        final previousStateForKey = state[key];
        final nextStateForKey = reducer(previousStateForKey, action);

        nextState[key] = nextStateForKey;
        hasChanged =
            hasChanged || !identical(previousStateForKey, nextStateForKey);
      }

      return hasChanged ? nextState : state;
    };
