@JS()
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

// =============================================================================
// Global JS Bindings using @JS() annotation
// =============================================================================

// =============================================================================
// Typed React Element Hierarchy
// =============================================================================

/// Base type for all React elements - provides type safety over raw JSObject.
///
/// - [createElement documentation](https://react.dev/reference/react/createElement)
/// - [createElement 允许你创建一个 React 元素，它可以作为 JSX 的替代方案](https://zh-hans.react.dev/reference/react/createElement)
extension type ReactElement._(JSObject _) implements JSObject, JSAny {
  /// Wrap a raw JSObject as a ReactElement
  factory ReactElement.fromJS(JSObject js) = ReactElement._;

  /// The element type (string for DOM elements, function for components)
  JSAny get type => switch (_['type']) {
    final JSAny t => t,
    _ => throw StateError('ReactElement missing type'),
  };

  /// The props passed to the element
  JSObject? get props => switch (_['props']) {
    final JSObject p => p,
    _ => null,
  };

  /// The key for reconciliation
  JSAny? get key => _['key'];
}

/// React global object providing access to React's core APIs.
///
/// - [React documentation](https://react.dev/reference/react)
/// - [本部分提供了使用 React 的详细参考文档](https://zh-hans.react.dev/reference/react)
@JS('React')
extension type React._(JSObject _) implements JSObject {
  /// Creates and returns a new React element of the given type.
  external static JSObject createElement(
    JSAny type, [
    JSObject? props,
    JSAny? children,
  ]);

  /// Returns a stateful value and a function to update it.
  external static JSArray useState(JSAny? initialValue);

  /// Accepts a function that contains imperative, possibly effectful code.
  external static void useEffect(JSFunction effect, [JSArray? deps]);

  /// Returns a mutable ref object whose .current property is initialized.
  external static JSObject useRef(JSAny? initialValue);

  /// Returns a memoized value.
  external static JSAny? useMemo(JSFunction factory, JSArray deps);

  /// Returns a memoized callback.
  external static JSFunction useCallback(JSFunction callback, JSArray deps);

  /// Returns true if the object is a valid React element.
  external static bool isValidElement(JSAny? object);

  /// Clones and returns a new React element.
  external static JSObject cloneElement(
    JSObject element, [
    JSObject? props,
    JSAny? children,
  ]);
}

/// ReactDOM global object providing DOM-specific methods.
///
/// - [ReactDOM documentation](https://react.dev/reference/react-dom/client)
/// - [react-dom/client API 允许你在客户端（浏览器）渲染 React 组件](https://zh-hans.react.dev/reference/react-dom/client)
@JS('ReactDOM')
extension type ReactDOM._(JSObject _) implements JSObject {
  /// Creates a root for displaying React components inside a DOM element.
  external static ReactRoot createRoot(JSObject container);
}

/// A React root for rendering React elements into the DOM.
///
/// - [createRoot documentation](https://react.dev/reference/react-dom/client/createRoot)
/// - [createRoot 允许在浏览器的 DOM 节点中创建根节点以显示 React 组件](https://zh-hans.react.dev/reference/react-dom/client/createRoot)
extension type ReactRoot._(JSObject _) implements JSObject {
  /// Renders a React element into the root's DOM container.
  external void render(JSObject element);
}

/// Document global object for DOM access.
@JS('document')
extension type Document._(JSObject _) implements JSObject {
  /// Returns the element with the specified ID.
  external static JSObject? getElementById(String id);
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Create a React element (convenience wrapper).
///
/// - [createElement documentation](https://react.dev/reference/react/createElement)
/// - [createElement 允许你创建一个 React 元素，它可以作为 JSX 的替代方案](https://zh-hans.react.dev/reference/react/createElement)
ReactElement createElement(JSAny type, [JSObject? props, JSAny? children]) =>
    ReactElement._(
      (children != null)
          ? React.createElement(type, props ?? JSObject(), children)
          : (props != null)
          ? React.createElement(type, props)
          : React.createElement(type),
    );

/// Create a React element with multiple children using spread
ReactElement createElementWithChildren(
  JSAny type,
  JSObject? props,
  List<JSAny> children,
) => ReactElement._(
  _createElementApply(type, props ?? JSObject(), children.toJS),
);

@JS('React.createElement.apply')
external JSObject _reactCreateElementApply(JSAny? thisArg, JSArray args);

JSObject _createElementApply(JSAny type, JSObject props, JSArray children) {
  // Build args array: [type, props, ...children]
  final args = <JSAny?>[type, props].toJS;
  // Concatenate with children
  final fullArgs = _concatArrays(args, children);
  return _reactCreateElementApply(null, fullArgs);
}

@JS('Array.prototype.concat.call')
external JSArray _concatArrays(JSArray arr1, JSArray arr2);

/// Create props object from a Map (with function conversion)
JSObject createProps(Map<String, dynamic> props) {
  final obj = JSObject();
  for (final entry in props.entries) {
    obj.setProperty(entry.key.toJS, _toJS(entry.value));
  }
  return obj;
}

JSAny? _toJS(Object? value) => switch (value) {
  null => null,
  // Already a JS function - don't rewrap
  final JSFunction fn => fn,
  // Wrap void Function() to handle both 0 and 1 arg calls from JS
  final void Function() fn => fn.toJS,
  final void Function(JSAny) fn => fn.toJS,
  // Support JSObject parameter (used by event handlers)
  final void Function(JSObject) fn => fn.toJS,
  final Function _ => throw StateError(
    'Unsupported function signature: ${value.runtimeType}',
  ),
  _ => value.jsify(),
};

// =============================================================================
// Utility Functions
// =============================================================================

/// Returns true if the object is a valid React element.
///
/// Example:
/// ```dart
/// final element = div(children: [pEl('Hello')]);
/// print(isValidElement(element)); // true
/// print(isValidElement('string')); // false
/// ```
///
/// - [isValidElement documentation](https://react.dev/reference/react/isValidElement)
/// - [isValidElement 检测参数值是否为 React 元素](https://zh-hans.react.dev/reference/react/isValidElement)
bool isValidElement(JSAny? object) => React.isValidElement(object);

/// Clones and returns a new React element using element as the starting point.
///
/// The config argument allows you to override props, and children allows you
/// to provide new children.
///
/// Example:
/// ```dart
/// final original = pEl('Original');
/// final cloned = cloneElement(original, {'className': 'cloned'});
/// ```
///
/// - [cloneElement documentation](https://react.dev/reference/react/cloneElement)
/// - [cloneElement 允许你使用一个元素作为初始值创建一个新的 React 元素](https://zh-hans.react.dev/reference/react/cloneElement)
ReactElement cloneElement(
  ReactElement element, [
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => ReactElement._(
  (children != null && children.isNotEmpty)
      ? _cloneElementWithChildren(
          element,
          props != null ? createProps(props) : null,
          children.toJS,
        )
      : (props != null)
      ? React.cloneElement(element, createProps(props))
      : React.cloneElement(element),
);

@JS('React.cloneElement.apply')
external JSObject _reactCloneElementApply(JSAny? thisArg, JSArray args);

JSObject _cloneElementWithChildren(
  JSObject element,
  JSObject? props,
  JSArray children,
) {
  final args = <JSAny?>[element, props ?? JSObject()].toJS;
  final fullArgs = _concatArrays(args, children);
  return _reactCloneElementApply(null, fullArgs);
}

// =============================================================================
// Functional Components
// =============================================================================

/// Create a functional component - returns the component function itself.
///
/// Example:
/// ```dart
/// final MyComponent = createFunctionalComponent((props) {
///   return div(children: [pEl('Hello')]);
/// });
/// ```
JSFunction createFunctionalComponent(
  ReactElement Function(JSObject props) render,
) => ((JSAny props) => render(props as JSObject)).toJS;

/// Create a React element with an inline functional component.
///
/// Example:
/// ```dart
/// final element = functionalComponent('Counter', (props) {
///   final count = useState(0);
///   return div(children: [pEl('Count: ${count.value}')]);
/// });
/// ```
ReactElement functionalComponent(
  String name,
  ReactElement Function(JSObject props) render,
) => createElement(createFunctionalComponent(render));
