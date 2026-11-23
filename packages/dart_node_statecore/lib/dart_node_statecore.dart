/// Statecore - A predictable state container for Dart applications.
///
/// Inspired by Redux patterns, statecore provides a unidirectional data flow
/// architecture with full type safety using Dart's type system and sealed
/// classes for exhaustive pattern matching.
///
/// ## Core Concepts
///
/// - **Store**: Holds the complete state tree of your application.
/// - **Actions**: Sealed classes that describe what happened - pattern match on
///   the actual TYPE, not strings!
/// - **Reducers**: Pure functions that specify how state changes in response
///   to actions.
/// - **Middleware**: Extension points for adding custom behavior.
/// - **Selectors**: Functions that extract and memoize derived data.
///
/// ## Example
///
/// ```dart
/// // Define state as a record
/// typedef CounterState = ({int count});
///
/// // Define actions as sealed classes
/// sealed class CounterAction extends Action {}
/// final class Increment extends CounterAction {}
/// final class Decrement extends CounterAction {}
/// final class SetValue extends CounterAction {
///   const SetValue(this.value);
///   final int value;
/// }
///
/// // Create a reducer with exhaustive pattern matching
/// CounterState counterReducer(CounterState state, Action action) =>
///     switch (action) {
///       Increment() => (count: state.count + 1),
///       Decrement() => (count: state.count - 1),
///       SetValue(:final value) => (count: value),
///       _ => state,
///     };
///
/// // Create the store
/// final store = createStore(counterReducer, (count: 0));
///
/// // Subscribe to changes
/// store.subscribe(() => print('Count: ${store.getState().count}'));
///
/// // Dispatch actions
/// store.dispatch(Increment());
/// store.dispatch(Decrement());
/// store.dispatch(SetValue(42));
/// ```
library;

export 'src/action_creators.dart';
export 'src/combine_reducers.dart';
export 'src/compose.dart';
export 'src/enhancers.dart';
export 'src/middleware.dart';
export 'src/selectors.dart';
export 'src/store.dart';
export 'src/types.dart';
