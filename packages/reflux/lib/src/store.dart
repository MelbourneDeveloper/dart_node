import 'package:reflux/src/types.dart';

/// Exception thrown when an action is dispatched while a reducer is executing.
final class DispatchInReducerException implements Exception {
  @override
  String toString() =>
      'DispatchInReducerException: Cannot dispatch actions while a reducer is '
      'executing. Reducers must be pure functions with no side effects.';
}

/// Exception thrown when subscribe is called from within a reducer.
final class SubscribeInReducerException implements Exception {
  @override
  String toString() =>
      'SubscribeInReducerException: Cannot subscribe while a reducer is '
      'executing.';
}

/// Creates a store that holds the state tree.
///
/// The only way to change the data in the store is to call `dispatch()` on it.
///
/// There should only be a single store in your app. To specify how different
/// parts of the state tree respond to actions, combine several reducers into
/// a single reducer function using `combineReducers`.
///
/// [reducer] A function that returns the next state tree, given the current
/// state tree and the action to handle.
///
/// [preloadedState] The initial state. You may optionally specify it to
/// hydrate the state from the server in universal apps, or to restore a
/// previously serialized user session.
///
/// [enhancer] Optional store enhancer. Use `applyMiddleware()` to add
/// middleware support.
Store<S> createStore<S>(
  Reducer<S> reducer,
  S preloadedState, {
  StoreEnhancer<S>? enhancer,
}) => enhancer != null
    ? enhancer(_createStoreImpl, reducer, preloadedState)
    : _createStoreImpl(reducer, preloadedState);

Store<S> _createStoreImpl<S>(Reducer<S> reducer, S preloadedState) =>
    _StoreImpl(reducer, preloadedState);

final class _StoreImpl<S> implements Store<S> {
  _StoreImpl(this._reducer, this._state) {
    // Dispatch init action to populate initial state
    dispatch(initAction);
  }

  Reducer<S> _reducer;
  S _state;
  final List<StateListener<S>> _listeners = [];
  bool _isDispatching = false;

  @override
  S getState() => _state;

  @override
  void dispatch(Action action) {
    if (_isDispatching) throw DispatchInReducerException();

    _isDispatching = true;
    try {
      _state = _reducer(_state, action);
    } finally {
      _isDispatching = false;
    }

    // Notify listeners - copy list to handle unsubscribe during iteration
    for (final listener in [..._listeners]) {
      listener();
    }
  }

  @override
  Unsubscribe subscribe(StateListener<S> listener) {
    if (_isDispatching) throw SubscribeInReducerException();

    _listeners.add(listener);

    var isSubscribed = true;
    return () {
      if (!isSubscribed) return;
      if (_isDispatching) throw DispatchInReducerException();

      isSubscribed = false;
      _listeners.remove(listener);
    };
  }

  @override
  void replaceReducer(Reducer<S> nextReducer) {
    _reducer = nextReducer;
    dispatch(const ReplaceAction());
  }
}
