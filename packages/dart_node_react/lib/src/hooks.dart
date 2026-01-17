import 'dart:js_interop';

import 'package:dart_node_react/src/react.dart';
import 'package:dart_node_react/src/ref.dart';

export 'package:dart_node_react/src/reducer_hook.dart';
// Re-export StateHook and ReducerHook from their own files
export 'package:dart_node_react/src/state_hook.dart';

// =============================================================================
// JS undefined constant for cleanup function returns
// =============================================================================

@JS('undefined')
external JSAny? get _jsUndefined;

// =============================================================================
// Additional React hook bindings
// =============================================================================

@JS('React.useLayoutEffect')
external void _reactUseLayoutEffect(JSFunction effect, [JSArray? deps]);

@JS('React.useImperativeHandle')
external void _reactUseImperativeHandle(
  JSAny? ref,
  JSFunction createHandle, [
  JSArray? deps,
]);

@JS('React.useDebugValue')
external void _reactUseDebugValue(JSAny? value, [JSFunction? format]);

// =============================================================================
// Helper to convert dart values to JS
// =============================================================================

JSAny? _toJsAny(Object? value) => (value == null) ? null : value.jsify();

// =============================================================================
// Effect Hooks
// =============================================================================

/// Runs [sideEffect] after every completed render of a function component.
///
/// If [dependencies] are given, [sideEffect] will only run if one of the
/// [dependencies] have changed. [sideEffect] may return a cleanup function
/// that is run before the component unmounts or re-renders.
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   final count = useState(1);
///   final evenOdd = useState('even');
///
///   useEffect(() {
///     evenOdd.set(count.value % 2 == 0 ? 'even' : 'odd');
///     return () {
///       print('cleanup: count is changing...');
///     };
///   }, [count.value]);
///
///   return div(children: [
///     pEl('\${count.value} is \${evenOdd.value}'),
///     button(text: '+', onClick: () => count.set(count.value + 1)),
///   ]);
/// });
/// ```
///
/// - [useEffect documentation](https://react.dev/reference/react/useEffect)
/// - [useEffect 是一个 React Hook，它允许你将组件与外部系统同步](https://zh-hans.react.dev/reference/react/useEffect)
void useEffect(Object? Function() sideEffect, [List<Object?>? dependencies]) {
  JSAny? wrappedSideEffect() {
    final result = sideEffect();
    return (result is void Function()) ? result.toJS : _jsUndefined;
  }

  final jsDeps = dependencies?.map(_toJsAny).toList().toJS;
  React.useEffect(wrappedSideEffect.toJS, jsDeps);
}

/// Runs [sideEffect] synchronously after a function component renders, but
/// before the screen is updated.
///
/// Compare to [useEffect] which runs [sideEffect] after the screen updates.
/// Prefer the standard [useEffect] when possible to avoid blocking visual
/// updates.
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   final width = useState(0);
///   final textareaRef = useRef<Element>(null);
///
///   useLayoutEffect(() {
///     width.set(textareaRef.current?.clientWidth ?? 0);
///   });
///
///   return div(children: [
///     pEl('textarea width: \${width.value}'),
///     textarea({'ref': textareaRef.jsRef}),
///   ]);
/// });
/// ```
///
/// - [useLayoutEffect documentation](https://react.dev/reference/react/useLayoutEffect)
/// - [useLayoutEffect 是 useEffect 的一个版本，在浏览器重新绘制屏幕之前触发](https://zh-hans.react.dev/reference/react/useLayoutEffect)
void useLayoutEffect(
  Object? Function() sideEffect, [
  List<Object?>? dependencies,
]) {
  JSAny? wrappedSideEffect() {
    final result = sideEffect();
    return (result is void Function()) ? result.toJS : _jsUndefined;
  }

  final jsDeps = dependencies?.map(_toJsAny).toList().toJS;
  _reactUseLayoutEffect(wrappedSideEffect.toJS, jsDeps);
}

// =============================================================================
// Ref Hooks
// =============================================================================

/// Returns an empty mutable [Ref] object.
///
/// To initialize a ref with a value, use [useRefInit] instead.
///
/// Changes to the [Ref.current] property do not cause the containing
/// function component to re-render.
///
/// The returned [Ref] object will persist for the full lifetime of the
/// function component. Compare to [createRef] which returns a new [Ref]
/// object on each render.
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   final inputRef = useRef<InputElement>(null);
///
///   return div(children: [
///     input({'ref': inputRef.jsRef}),
///     button(text: 'Focus', onClick: () => inputRef.current?.focus()),
///   ]);
/// });
/// ```
///
/// - [useRef documentation](https://react.dev/reference/react/useRef)
/// - [useRef 是一个 React Hook，它能帮助引用一个不需要渲染的值](https://zh-hans.react.dev/reference/react/useRef)
Ref<T?> useRef<T>([T? initialValue]) => useRefInit<T?>(initialValue);

/// Returns a mutable [Ref] object with [Ref.current] property initialized to
/// [initialValue].
///
/// Changes to the [Ref.current] property do not cause the containing
/// function component to re-render.
///
/// The returned [Ref] object will persist for the full lifetime of the
/// function component. Compare to [createRef] which returns a new [Ref]
/// object on each render.
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   final countRef = useRefInit(1);
///
///   void handleClick([_]) {
///     countRef.current = countRef.current + 1;
///     print('You clicked \${countRef.current} times!');
///   }
///
///   return button(text: 'Click me!', onClick: handleClick);
/// });
/// ```
///
/// - [useRef documentation](https://react.dev/reference/react/useRef)
/// - [useRef 是一个 React Hook，它能帮助引用一个不需要渲染的值](https://zh-hans.react.dev/reference/react/useRef)
Ref<T> useRefInit<T>(T initialValue) {
  final jsInitial = _toJsAny(initialValue);
  final jsRef = React.useRef(jsInitial);
  return Ref<T>.fromJs(JsRef.fromJs(jsRef));
}

/// Customizes the [ref] value that is exposed to parent components when using
/// forwardRef2 by setting `ref.current` to the return value of
/// `createHandle`.
///
/// In most cases, imperative code using refs should be avoided.
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Example:
/// ```dart
/// class FancyInputApi {
///   final void Function() focus;
///   FancyInputApi(this.focus);
/// }
///
/// final FancyInput = forwardRef2((props, ref) {
///   final inputRef = useRef<InputElement>(null);
///
///   useImperativeHandle(
///     ref,
///     () => FancyInputApi(() => inputRef.current?.focus()),
///     [],
///   );
///
///   return input({
///     'ref': inputRef.jsRef,
///     'value': props['value'],
///   });
/// });
/// ```
///
/// - [useImperativeHandle documentation](https://react.dev/reference/react/useImperativeHandle)
/// - [useImperativeHandle 是 React 中的一个 Hook，它能让你自定义由 ref 暴露出来的句柄](https://zh-hans.react.dev/reference/react/useImperativeHandle)
void useImperativeHandle<T>(
  Object? ref,
  T Function() createHandle, [
  List<Object?>? dependencies,
]) {
  JSAny? jsCreateHandle() => _toJsAny(createHandle());

  // ref will be a JsRef in forwardRef2, or a Ref in forwardRef.
  final jsRef = switch (ref) {
    final Ref<Object?> r => r.jsRef,
    final JsRef jr => jr,
    final JSAny js => js,
    _ => null,
  };

  final jsDeps = dependencies?.map(_toJsAny).toList().toJS;
  _reactUseImperativeHandle(jsRef, jsCreateHandle.toJS, jsDeps);
}

// =============================================================================
// Memoization Hooks
// =============================================================================

/// Returns a memoized version of the return value of [createFunction].
///
/// If one of the [dependencies] has changed, [createFunction] is run during
/// rendering of the function component. This optimization helps to avoid
/// expensive calculations on every render.
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   final count = useState(0);
///
///   final fib = useMemo(
///     () => fibonacci(count.value),
///     [count.value],
///   );
///
///   return div(children: [
///     pEl('Fibonacci of \${count.value} is \$fib'),
///     button(
///       text: '+',
///       onClick: () => count.setWithUpdater((prev) => prev + 1),
///     ),
///   ]);
/// });
/// ```
///
/// - [useMemo documentation](https://react.dev/reference/react/useMemo)
/// - [useMemo 是一个 React Hook，它在每次重新渲染的时候能够缓存计算的结果](https://zh-hans.react.dev/reference/react/useMemo)
T useMemo<T>(T Function() createFunction, [List<Object?>? dependencies]) {
  JSAny? jsCreateFunction() => _toJsAny(createFunction());

  final jsDeps = (dependencies ?? <Object?>[]).map(_toJsAny).toList().toJS;
  final result = React.useMemo(jsCreateFunction.toJS, jsDeps);
  return switch (result.dartify()) {
    final T v => v,
    _ => throw StateError('useMemo returned unexpected type'),
  };
}

/// Returns a memoized version of [callback] that only changes if one of the
/// [dependencies] has changed.
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   final count = useState(0);
///   final delta = useState(1);
///
///   final increment = useCallback((_) {
///     count.setWithUpdater((prev) => prev + delta.value);
///   }, [delta.value]);
///
///   return div(children: [
///     pEl('Delta is \${delta.value}'),
///     pEl('Count is \${count.value}'),
///     button(text: 'Increment count', onClick: increment),
///   ]);
/// });
/// ```
///
/// - [useCallback documentation](https://react.dev/reference/react/useCallback)
/// - [useCallback 是一个允许你在多次渲染中缓存函数的 React Hook](https://zh-hans.react.dev/reference/react/useCallback)
JSFunction useCallback(Function callback, List<Object?> dependencies) {
  final jsCallback = switch (callback) {
    final void Function() fn => fn.toJS,
    final void Function(JSAny) fn => fn.toJS,
    _ => throw StateError('Unsupported callback type: ${callback.runtimeType}'),
  };

  final jsDeps = dependencies.map(_toJsAny).toList().toJS;
  return React.useCallback(jsCallback, jsDeps);
}

// =============================================================================
// Debug Hooks
// =============================================================================

/// Displays [value] as a label for a custom hook in React DevTools.
///
/// To defer formatting [value] until the hooks are inspected, use the optional
/// [format] function.
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Example:
/// ```dart
/// // Custom Hook
/// StateHook<bool> useFriendStatus(int friendID) {
///   final isOnline = useState(false);
///
///   useEffect(() {
///     ChatAPI.subscribeToFriendStatus(friendID, (status) {
///       isOnline.set(status['isOnline']);
///     });
///     return () {
///       ChatAPI.unsubscribeFromFriendStatus(friendID);
///     };
///   });
///
///   // Use format function to avoid unnecessarily formatting isOnline
///   useDebugValue<bool>(
///     isOnline.value,
///     (isOnline) => isOnline ? 'Online' : 'Not Online',
///   );
///
///   return isOnline;
/// }
/// ```
///
/// - [useDebugValue documentation](https://react.dev/reference/react/useDebugValue)
/// - [useDebugValue 是一个 React Hook，可以让你在 React 开发工具中为自定义 Hook 添加标签](https://zh-hans.react.dev/reference/react/useDebugValue)
void useDebugValue<T>(T value, [String Function(T)? format]) {
  final jsValue = _toJsAny(value);
  JSString jsFormatFn(JSAny? v) {
    final dartValue = switch (v) {
      null => value,
      final jsVal => switch (jsVal.dartify()) {
        final T val => val,
        _ => value, // fallback to original value
      },
    };
    return format!(dartValue).toJS;
  }

  final jsFormat = (format != null) ? jsFormatFn.toJS : null;

  _reactUseDebugValue(jsValue, jsFormat);
}
