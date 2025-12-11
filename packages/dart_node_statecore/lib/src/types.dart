/// Core types for statecore
library;

/// Base class for all actions.
/// Extend this to create type-safe actions with pattern matching.
///
/// Example:
/// ```dart
/// // Define your actions as a sealed hierarchy in YOUR code
/// sealed class CounterAction extends Action {}
///
/// final class Increment extends CounterAction {}
/// final class Decrement extends CounterAction {}
/// final class SetValue extends CounterAction {
///   const SetValue(this.value);
///   final int value;
/// }
/// final class Reset extends CounterAction {}
///
/// // Reducer uses exhaustive pattern matching - no strings!
/// int counterReducer(int state, Action action) => switch (action) {
///   Increment() => state + 1,
///   Decrement() => state - 1,
///   SetValue(:final value) => value,
///   Reset() => 0,
///   _ => state, // Handle system actions
/// };
/// ```
abstract class Action {
  /// Creates an action.
  const Action();
}

/// System action for store initialization.
final class InitAction extends Action {
  /// Creates an init action.
  const InitAction();
}

/// System action for reducer replacement.
final class ReplaceAction extends Action {
  /// Creates a replace action.
  const ReplaceAction();
}

/// System action for time travel.
final class TimeTravelAction extends Action {
  /// Creates a time travel action to jump to [index].
  const TimeTravelAction(this.index);

  /// The history index to jump to.
  final int index;
}

/// The init action dispatched when the store is created.
const Action initAction = InitAction();

/// A reducer specifies how the application's state changes in response
/// to actions sent to the store.
typedef Reducer<S> = S Function(S state, Action action);

/// The next dispatcher in the middleware chain.
typedef NextDispatcher = void Function(Action action);

/// A middleware transform takes the next dispatcher and returns a new one.
typedef MiddlewareTransform = NextDispatcher Function(NextDispatcher next);

/// Middleware is a higher-order function that composes a dispatch function
/// to return a new dispatch function. It provides a third-party extension
/// point between dispatching an action and the moment it reaches the reducer.
///
/// Signature: `(api) => (next) => (action) => { ... }`
typedef Middleware<S> = MiddlewareTransform Function(MiddlewareApi<S> api);

/// The API available to middleware.
typedef MiddlewareApi<S> = ({
  S Function() getState,
  void Function(Action action) dispatch,
});

/// A listener that is called when the state changes.
typedef StateListener<S> = void Function();

/// Unsubscribe function returned by subscribe.
typedef Unsubscribe = void Function();

/// A store enhancer is a higher-order function that composes a store creator
/// to return a new enhanced store creator.
typedef StoreEnhancer<S> = Store<S> Function(
  StoreCreator<S> createStore,
  Reducer<S> reducer,
  S preloadedState,
);

/// A store creator function.
typedef StoreCreator<S> = Store<S> Function(
  Reducer<S> reducer,
  S preloadedState,
);

/// An action creator is a function that creates an action.
typedef ActionCreator<A extends Action> = A Function();

/// Store interface that defines the contract for a state container.
abstract interface class Store<S> {
  /// Returns the current state tree of your application.
  S getState();

  /// Dispatches an action. This is the only way to trigger a state change.
  void dispatch(Action action);

  /// Adds a change listener. It will be called any time an action is
  /// dispatched, and some part of the state tree may potentially have changed.
  /// Returns an unsubscribe function.
  Unsubscribe subscribe(StateListener<S> listener);

  /// Replaces the reducer currently used by the store to calculate the state.
  void replaceReducer(Reducer<S> nextReducer);
}
