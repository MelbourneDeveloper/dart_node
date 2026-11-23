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
  final jsValue = result[0];
  final value = (jsValue == null) ? null : jsValue.dartify();
  final setter = result[1];
  final fn = setter! as JSFunction;
  return StateHook._(value as T, (v) => fn.callAsFunction(null, v));
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
  final jsValue = result[0];
  final value = (jsValue == null) ? null : jsValue.dartify();
  final setter = result[1];
  final fn = setter! as JSFunction;
  return StateHook._(value as T, (v) => fn.callAsFunction(null, v));
}

/// State hook for JS interop types (JSString, JSObject, etc).
///
/// Use this instead of [useState] when state must remain as a JS type
/// without dartify/jsify conversion.
final class StateHookJS {
  StateHookJS._(this._value, this._setValue);

  final JSAny? _value;
  final void Function(JSAny?) _setValue;

  /// The current value of the state.
  JSAny? get value => _value;

  /// Updates [value] to [newValue].
  void set(JSAny? newValue) => _setValue(newValue);
}

/// Adds local state for JS interop types to a function component.
///
/// Use this instead of [useState] when state must remain as a JS type
/// (JSString, JSObject, etc.) without Dart conversion.
///
/// Example:
/// ```dart
/// final tokenState = useStateJS(null);
/// final token = tokenState.value; // JSAny?
/// tokenState.set('abc'.toJS);
/// ```
StateHookJS useStateJS(JSAny? initialValue) {
  final result = React.useState(initialValue);
  final jsValue = result[0];
  final setter = result[1];
  final fn = setter! as JSFunction;
  return StateHookJS._(jsValue, (v) => fn.callAsFunction(null, v));
}

/// State hook for lists of JS objects.
///
/// Use this instead of [useState] when state is a list of JS objects.
/// Avoids the jsify/dartify roundtrip issue where `List<JSObject>` becomes
/// `List<Object?>` after conversion.
final class StateHookJSArray<T extends JSAny> {
  StateHookJSArray._(this._value, this._setValue);

  final List<T> _value;
  final void Function(JSAny?) _setValue;

  /// The current value of the state.
  List<T> get value => _value;

  /// Updates [value] to [newValue].
  void set(List<T> newValue) => _setValue(newValue.toJS);

  /// Updates [value] to the return value of [computeNewValue].
  void setWithUpdater(List<T> Function(List<T> oldValue) computeNewValue) {
    JSAny? updater(JSAny? oldValue) {
      final dartOld = _jsArrayToList<T>(oldValue as JSArray?);
      return computeNewValue(dartOld).toJS;
    }

    _setValue(updater.toJS);
  }
}

/// Convert JSArray to `List<T>` without dartify (which loses type info).
List<T> _jsArrayToList<T extends JSAny>(JSArray? jsArray) {
  if (jsArray == null) return <T>[];
  final length = jsArray.length;
  final result = <T>[];
  for (var i = 0; i < length; i++) {
    final item = jsArray[i];
    if (item != null) result.add(item as T);
  }
  return result;
}

/// Adds local state for lists of JS objects to a function component.
///
/// Use this instead of [useState] when state is a list of JS objects
/// (like `List<JSObject>`). This avoids type conversion issues.
///
/// Example:
/// ```dart
/// final tasksState = useStateJSArray<JSObject>(<JSObject>[].toJS);
/// final tasks = tasksState.value; // List<JSObject>
/// tasksState.set([...tasks, newTask]);
/// tasksState.setWithUpdater((prev) => [...prev, newTask]);
/// ```
StateHookJSArray<T> useStateJSArray<T extends JSAny>(JSAny? initialValue) {
  final result = React.useState(initialValue);
  final jsValue = result[0];
  final setter = result[1];
  final fn = setter! as JSFunction;
  final value = _jsArrayToList<T>(jsValue as JSArray?);
  return StateHookJSArray._(value, (v) => fn.callAsFunction(null, v));
}
