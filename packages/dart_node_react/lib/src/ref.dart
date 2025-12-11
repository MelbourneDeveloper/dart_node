import 'dart:js_interop';

/// A JavaScript ref object returned by React.createRef() or useRef().
///
/// Dart factories will automatically unwrap [Ref] objects to this JS
/// representation, so using this class directly shouldn't be necessary.
extension type JsRef._(JSObject _) implements JSObject {
  /// Creates a JsRef from a raw JSObject.
  factory JsRef.fromJs(JSObject jsObject) = JsRef._;

  /// The current value stored in the ref.
  external JSAny? get current;

  /// Sets the current value stored in the ref.
  external set current(JSAny? value);
}

/// Storage for complex Dart objects that can't survive jsify/dartify.
final Expando<Object> _dartObjectStore = Expando<Object>('refDartValue');

/// When this is provided as the ref prop, a reference to the rendered
/// component will be available via [current].
///
/// See [createRef] for usage examples and more info.
final class Ref<T> {
  /// Creates a Ref from a JavaScript ref object.
  Ref._(this.jsRef);

  /// Creates a Ref from a JavaScript ref object.
  factory Ref.fromJs(JsRef jsRef) => Ref._(jsRef);

  /// A JavaScript ref object returned by React.createRef() or useRef().
  final JsRef jsRef;

  /// A reference to the latest instance of the rendered component.
  ///
  /// See [createRef] for usage examples and more info.
  T get current {
    final stored = _dartObjectStore[jsRef];
    if (stored != null) return stored as T;
    final jsCurrent = jsRef.current;
    return (jsCurrent == null) ? null as T : jsCurrent.dartify() as T;
  }

  /// Sets the value of [current].
  ///
  /// See:
  /// https://reactjs.org/docs/hooks-faq.html#is-there-something-like-instance-variables
  set current(T value) {
    if (value != null) _dartObjectStore[jsRef] = value;
    jsRef.current = (value == null) ? null : (value as Object).jsify();
  }
}

// React.createRef external binding
@JS('React.createRef')
external JsRef _reactCreateRef();

/// Creates a [Ref] object that can be attached to a ReactElement via the ref
/// prop.
///
/// Example:
/// ```dart
/// final inputRef = createRef<InputElement>();
///
/// // In render:
/// input({'ref': inputRef.jsRef, 'type': 'text'})
///
/// // Later:
/// inputRef.current?.focus();
/// ```
///
/// Learn more: https://reactjs.org/docs/refs-and-the-dom.html#creating-refs
Ref<T?> createRef<T>() => Ref<T?>.fromJs(_reactCreateRef());
