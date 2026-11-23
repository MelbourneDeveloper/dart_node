import 'package:dart_node_statecore/src/types.dart';

/// Applies middleware to the dispatch method of the store.
///
/// Middleware is the suggested way to extend functionality with custom
/// behavior. It provides a third-party extension point between dispatching
/// an action and the moment it reaches the reducer.
///
/// The middleware signature is:
/// ```dart
/// Middleware<AppState> loggerMiddleware() => (api) => (next) => (action) {
///   print('Dispatching: ${action.type}');
///   next(action);
///   print('Next state: ${api.getState()}');
/// };
///
/// final store = createStore(
///   reducer,
///   initialState,
///   enhancer: applyMiddleware([loggerMiddleware()]),
/// );
/// ```
StoreEnhancer<S> applyMiddleware<S>(List<Middleware<S>> middlewares) =>
    (createStoreFn, reducer, preloadedState) {
      final store = createStoreFn(reducer, preloadedState);

      if (middlewares.isEmpty) return store;

      // Create a dispatch that throws if called during middleware setup
      NextDispatcher dispatch = _throwingDispatch;

      final middlewareApi = (
        getState: store.getState,
        dispatch: (Action action) => dispatch(action),
      );

      // Build the middleware chain
      final chain = middlewares.map((m) => m(middlewareApi)).toList();

      // Compose the chain with the store's dispatch
      dispatch = _composeMiddleware(chain)(store.dispatch);

      return _MiddlewareStore(store, dispatch);
    };

Never _throwingDispatch(Action action) => throw StateError(
      'Dispatching while constructing middleware is not allowed.',
    );

/// Composes middleware transform functions from right to left.
MiddlewareTransform _composeMiddleware(List<MiddlewareTransform> chain) {
  if (chain.isEmpty) return (next) => next;
  if (chain.length == 1) return chain.first;

  return chain.reduce((a, b) => (next) => a(b(next)));
}

/// A store wrapper that uses the middleware-enhanced dispatch.
final class _MiddlewareStore<S> implements Store<S> {
  _MiddlewareStore(this._store, this._dispatch);

  final Store<S> _store;
  final NextDispatcher _dispatch;

  @override
  S getState() => _store.getState();

  @override
  void dispatch(Action action) => _dispatch(action);

  @override
  Unsubscribe subscribe(StateListener<S> listener) =>
      _store.subscribe(listener);

  @override
  void replaceReducer(Reducer<S> nextReducer) =>
      _store.replaceReducer(nextReducer);
}
