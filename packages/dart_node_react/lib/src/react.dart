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

/// Base type for all React elements - provides type safety over raw JSObject
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

/// React global object
@JS('React')
extension type React._(JSObject _) implements JSObject {
  external static JSObject createElement(
    JSAny type, [
    JSObject? props,
    JSAny? children,
  ]);
  external static JSArray useState(JSAny? initialValue);
  external static void useEffect(JSFunction effect, [JSArray? deps]);
  external static JSObject useRef(JSAny? initialValue);
  external static JSAny? useMemo(JSFunction factory, JSArray deps);
  external static JSFunction useCallback(JSFunction callback, JSArray deps);
}

/// ReactDOM global object
@JS('ReactDOM')
extension type ReactDOM._(JSObject _) implements JSObject {
  external static ReactRoot createRoot(JSObject container);
}

/// React root for rendering
extension type ReactRoot._(JSObject _) implements JSObject {
  external void render(JSObject element);
}

/// Document global object
@JS('document')
extension type Document._(JSObject _) implements JSObject {
  external static JSObject? getElementById(String id);
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Create a React element (convenience wrapper)
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
) =>
    ReactElement._(
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
  final Function _ =>
    throw StateError('Unsupported function signature: ${value.runtimeType}'),
  _ => value.jsify(),
};
