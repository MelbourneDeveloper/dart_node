import 'package:dart_node_statecore/src/types.dart';

/// Composes multiple store enhancers into a single enhancer.
///
/// This is useful when you want to apply multiple enhancers to the store.
/// The enhancers are applied from right to left (last to first).
///
/// Example:
/// ```dart
/// final store = createStore(
///   reducer,
///   initialState,
///   enhancer: composeEnhancers([
///     applyMiddleware([loggerMiddleware]),
///     devToolsEnhancer,
///   ]),
/// );
/// ```
StoreEnhancer<S> composeEnhancers<S>(List<StoreEnhancer<S>> enhancers) {
  if (enhancers.isEmpty) {
    return (createStore, reducer, preloadedState) =>
        createStore(reducer, preloadedState);
  }

  if (enhancers.length == 1) return enhancers.first;

  // Apply enhancers from right to left
  return (createStore, reducer, preloadedState) {
    var currentCreateStore = createStore;
    for (var i = enhancers.length - 1; i >= 0; i--) {
      final enhancer = enhancers[i];
      final prevCreateStore = currentCreateStore;
      currentCreateStore =
          (r, s) => enhancer(prevCreateStore, r, s);
    }
    return currentCreateStore(reducer, preloadedState);
  };
}

/// Creates an enhancer that wraps the store with additional functionality.
///
/// This is a utility for creating custom enhancers without dealing
/// with the full enhancer signature.
///
/// Example:
/// ```dart
/// final timestampEnhancer = createEnhancer<AppState>((store) {
///   // Return enhanced store with timestamp on each dispatch
///   return _TimestampStore(store);
/// });
/// ```
StoreEnhancer<S> createEnhancer<S>(
  Store<S> Function(Store<S> store) enhance,
) =>
    (createStore, reducer, preloadedState) {
      final store = createStore(reducer, preloadedState);
      return enhance(store);
    };

/// Dev tools enhancer that logs all actions and state changes.
///
/// This provides basic Redux DevTools-like functionality for debugging.
///
/// Example:
/// ```dart
/// final store = createStore(
///   reducer,
///   initialState,
///   enhancer: devToolsEnhancer(
///     name: 'MyApp',
///     onAction: (action, prevState, nextState) {
///       print('Action: ${action.type}');
///       print('Prev: $prevState');
///       print('Next: $nextState');
///     },
///   ),
/// );
/// ```
StoreEnhancer<S> devToolsEnhancer<S>({
  String name = 'Store',
  void Function(Action action, S prevState, S nextState)? onAction,
  bool enabled = true,
}) =>
    (createStore, reducer, preloadedState) {
      if (!enabled) return createStore(reducer, preloadedState);

      S wrappedReducer(S state, Action action) {
        final prevState = state;
        final nextState = reducer(state, action);

        onAction?.call(action, prevState, nextState);

        return nextState;
      }

      return createStore(wrappedReducer, preloadedState);
    };

/// Time travel enhancer that allows rewinding and replaying actions.
///
/// This enhancer keeps a history of all states and allows you to
/// jump to any point in the history.
///
/// Example:
/// ```dart
/// final timeTravel = TimeTravelEnhancer<AppState>();
/// final store = createStore(
///   reducer,
///   initialState,
///   enhancer: timeTravel.enhancer,
/// );
///
/// // Later...
/// timeTravel.jumpTo(5); // Jump to state at index 5
/// timeTravel.undo(); // Go back one state
/// timeTravel.redo(); // Go forward one state
/// ```
final class TimeTravelEnhancer<S> {
  final List<S> _history = [];
  int _currentIndex = -1;
  Store<S>? _store;
  bool _isTimeTraveling = false;

  /// The store enhancer function.
  StoreEnhancer<S> get enhancer => (createStore, reducer, preloadedState) {
        S wrappedReducer(S state, Action action) {
          if (_isTimeTraveling) return state;

          final nextState = reducer(state, action);

          // Record state in history
          if (_currentIndex < _history.length - 1) {
            // We've time traveled and are now making new changes
            // Truncate future history
            _history.removeRange(_currentIndex + 1, _history.length);
          }
          _history.add(nextState);
          _currentIndex = _history.length - 1;

          return nextState;
        }

        _store = createStore(wrappedReducer, preloadedState);
        _history.add(preloadedState);
        _currentIndex = 0;

        return _TimeTravelStore(this, _store!);
      };

  /// Returns the current history of states.
  List<S> get history => List.unmodifiable(_history);

  /// Returns the current index in the history.
  int get currentIndex => _currentIndex;

  /// Whether we can undo (go back in history).
  bool get canUndo => _currentIndex > 0;

  /// Whether we can redo (go forward in history).
  bool get canRedo => _currentIndex < _history.length - 1;

  /// Jump to a specific index in history.
  void jumpTo(int index) {
    if (index < 0 || index >= _history.length) {
      throw RangeError('Index $index is out of bounds [0, ${_history.length})');
    }
    _currentIndex = index;
    _notifyStore();
  }

  /// Go back one state in history.
  void undo() {
    if (!canUndo) return;
    _currentIndex--;
    _notifyStore();
  }

  /// Go forward one state in history.
  void redo() {
    if (!canRedo) return;
    _currentIndex++;
    _notifyStore();
  }

  /// Reset history and start fresh.
  void reset() {
    final currentState = _store?.getState();
    _history
      ..clear()
      ..add(currentState as S);
    _currentIndex = 0;
  }

  void _notifyStore() {
    _isTimeTraveling = true;
    // Dispatch a special action to trigger listeners
    _store?.dispatch(TimeTravelAction(_currentIndex));
    _isTimeTraveling = false;
  }
}

final class _TimeTravelStore<S> implements Store<S> {
  _TimeTravelStore(this._timeTravel, this._store);

  final TimeTravelEnhancer<S> _timeTravel;
  final Store<S> _store;

  @override
  S getState() => _timeTravel._history[_timeTravel._currentIndex];

  @override
  void dispatch(Action action) => _store.dispatch(action);

  @override
  Unsubscribe subscribe(StateListener<S> listener) =>
      _store.subscribe(listener);

  @override
  void replaceReducer(Reducer<S> nextReducer) =>
      _store.replaceReducer(nextReducer);
}
