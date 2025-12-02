import 'dart:js_interop';

import 'package:dart_node_react/src/react.dart';

/// The return value of [useState].
///
/// The current value of the state is available via [value] and
/// functions to update it are available via [set] and [setWithUpdater].
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Learn more: https://reactjs.org/docs/hooks-state.html
final class StateHook<T> {
  StateHook._(this._value, this._setValue);

  /// The first item of the pair returned by React.useState.
  final T _value;

  /// The second item in the pair returned by React.useState.
  final void Function(JSAny?) _setValue;

  /// The current value of the state.
  ///
  /// See: https://reactjs.org/docs/hooks-reference.html#usestate
  T get value => _value;

  /// Updates [value] to [newValue].
  ///
  /// See: https://reactjs.org/docs/hooks-state.html#updating-state
  void set(T newValue) {
    final jsValue = (newValue == null) ? null : (newValue as Object).jsify();
    _setValue(jsValue);
  }

  /// Updates [value] to the return value of [computeNewValue].
  ///
  /// See: https://reactjs.org/docs/hooks-reference.html#functional-updates
  void setWithUpdater(T Function(T oldValue) computeNewValue) {
    JSAny? updater(JSAny? oldValue) {
      final dartOld = oldValue.dartify() as T;
      final newVal = computeNewValue(dartOld);
      return (newVal == null) ? null : (newVal as Object).jsify();
    }

    _setValue(updater.toJS);
  }
}

/// Adds local state to a function component by returning a [StateHook] with
/// [StateHook.value] initialized to [initialValue].
///
/// Note: If the [initialValue] is expensive to compute, [useStateLazy] should
/// be used instead.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   final count = useState(0);
///
///   return div(children: [
///     pEl('Count: \${count.value}'),
///     button(
///       text: 'Increment',
///       onClick: () => count.setWithUpdater((prev) => prev + 1),
///     ),
///   ]);
/// });
/// ```
///
/// Learn more: https://reactjs.org/docs/hooks-state.html
StateHook<T> useState<T>(T initialValue) {
  final jsInitial = (initialValue == null)
      ? null
      : (initialValue as Object).jsify();
  final result = React.useState(jsInitial);
  final value = result[0].dartify() as T;
  final setter = result[1];
  final fn = setter! as JSFunction;
  return StateHook._(value, (v) => fn.callAsFunction(null, v));
}

/// Adds local state to a function component by returning a [StateHook] with
/// [StateHook.value] initialized to the return value of [init].
///
/// Use this when the initial state is expensive to compute.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   final count = useStateLazy(() {
///     // Expensive computation here
///     return someExpensiveComputation(props);
///   });
///
///   return div(children: [
///     pEl('Count: \${count.value}'),
///   ]);
/// });
/// ```
///
/// Learn more: https://reactjs.org/docs/hooks-reference.html#lazy-initial-state
StateHook<T> useStateLazy<T>(T Function() init) {
  JSAny? jsInit() {
    final val = init();
    return (val == null) ? null : (val as Object).jsify();
  }

  final result = React.useState(jsInit.toJS);
  final value = result[0].dartify() as T;
  final setter = result[1];
  final fn = setter! as JSFunction;
  return StateHook._(value, (v) => fn.callAsFunction(null, v));
}
