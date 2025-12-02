import 'dart:js_interop';

// React.useReducer external binding
@JS('React.useReducer')
external JSArray _reactUseReducer(
  JSFunction reducer,
  JSAny? initialState, [
  JSFunction? init,
]);

/// The return value of [useReducer].
///
/// The current state is available via [state] and action dispatcher is
/// available via [dispatch].
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Learn more: https://reactjs.org/docs/hooks-reference.html#usereducer
final class ReducerHook<TState, TAction> {
  ReducerHook._(this._state, this._dispatchFn);

  /// The first item of the pair returned by React.useReducer.
  final TState _state;

  /// The second item in the pair returned by React.useReducer.
  final void Function(Object?) _dispatchFn;

  /// The current state of the component.
  ///
  /// See: https://reactjs.org/docs/hooks-reference.html#usereducer
  TState get state => _state;

  /// Dispatches [action] and triggers state changes.
  ///
  /// Note: The dispatch function identity is stable and will not change on
  /// re-renders.
  ///
  /// See: https://reactjs.org/docs/hooks-reference.html#usereducer
  void dispatch(TAction action) => _dispatchFn(action);
}

/// Initializes state of a function component to [initialState] and creates a
/// `dispatch` method.
///
/// Example:
/// ```dart
/// Map<String, dynamic> reducer(
///   Map<String, dynamic> state,
///   Map<String, dynamic> action,
/// ) {
///   switch (action['type']) {
///     case 'increment':
///       return {...state, 'count': state['count'] + 1};
///     case 'decrement':
///       return {...state, 'count': state['count'] - 1};
///     default:
///       return state;
///   }
/// }
///
/// final MyComponent = registerFunctionComponent((props) {
///   final state = useReducer(reducer, {'count': 0});
///
///   return div(children: [
///     pEl('Count: \${state.state['count']}'),
///     button(
///       text: '+',
///       onClick: () => state.dispatch({'type': 'increment'}),
///     ),
///     button(
///       text: '-',
///       onClick: () => state.dispatch({'type': 'decrement'}),
///     ),
///   ]);
/// });
/// ```
///
/// Learn more: https://reactjs.org/docs/hooks-reference.html#usereducer
ReducerHook<TState, TAction> useReducer<TState, TAction>(
  TState Function(TState state, TAction action) reducer,
  TState initialState,
) {
  JSAny? jsReducer(JSAny? jsState, JSAny? jsAction) {
    final dartState = jsState.dartify() as TState;
    final dartAction = jsAction.dartify() as TAction;
    final newState = reducer(dartState, dartAction);
    return (newState == null) ? null : (newState as Object).jsify();
  }

  final jsInitialState = (initialState == null)
      ? null
      : (initialState as Object).jsify();

  final result = _reactUseReducer(jsReducer.toJS, jsInitialState);
  final state = result[0].dartify() as TState;
  final dispatch = result[1]! as JSFunction;

  return ReducerHook._(
    state,
    (action) {
      dispatch.callAsFunction(null, action.jsify());
    },
  );
}

/// Initializes state of a function component to `init(initialArg)` and creates
/// `dispatch` method.
///
/// Example:
/// ```dart
/// Map<String, dynamic> initializeCount(int initialValue) {
///   return {'count': initialValue};
/// }
///
/// Map<String, dynamic> reducer(
///   Map<String, dynamic> state,
///   Map<String, dynamic> action,
/// ) {
///   switch (action['type']) {
///     case 'increment':
///       return {...state, 'count': state['count'] + 1};
///     case 'decrement':
///       return {...state, 'count': state['count'] - 1};
///     case 'reset':
///       return initializeCount(action['payload']);
///     default:
///       return state;
///   }
/// }
///
/// final MyComponent = registerFunctionComponent((props) {
///   final state = useReducerLazy(
///     reducer,
///     props['initialCount'],
///     initializeCount,
///   );
///
///   return div(children: [
///     pEl('Count: \${state.state['count']}'),
///     button(
///       text: '+',
///       onClick: () => state.dispatch({'type': 'increment'}),
///     ),
///     button(
///       text: 'Reset',
///       onClick: () => state.dispatch({
///         'type': 'reset',
///         'payload': props['initialCount'],
///       }),
///     ),
///   ]);
/// });
/// ```
///
/// Learn more: https://reactjs.org/docs/hooks-reference.html#lazy-initialization
ReducerHook<TState, TAction> useReducerLazy<TState, TAction, TInit>(
  TState Function(TState state, TAction action) reducer,
  TInit initialArg,
  TState Function(TInit) init,
) {
  JSAny? jsReducer(JSAny? jsState, JSAny? jsAction) {
    final dartState = jsState.dartify() as TState;
    final dartAction = jsAction.dartify() as TAction;
    final newState = reducer(dartState, dartAction);
    return (newState == null) ? null : (newState as Object).jsify();
  }

  JSAny? jsInit(JSAny? jsArg) {
    final dartArg = jsArg.dartify() as TInit;
    final state = init(dartArg);
    return (state == null) ? null : (state as Object).jsify();
  }

  final jsInitialArg = (initialArg == null)
      ? null
      : (initialArg as Object).jsify();

  final result = _reactUseReducer(jsReducer.toJS, jsInitialArg, jsInit.toJS);
  final state = result[0].dartify() as TState;
  final dispatch = result[1]! as JSFunction;

  return ReducerHook._(
    state,
    (action) {
      dispatch.callAsFunction(null, action.jsify());
    },
  );
}
