// Fragment, Suspense, and StrictMode are capitalized to match React's API
// naming conventions where these are accessed as React.Fragment, etc.
// ignore_for_file: non_constant_identifier_names
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/src/react.dart';
import 'package:dart_node_react/src/ref.dart';

// =============================================================================
// React Special Component Bindings
// =============================================================================

@JS('React.Fragment')
external JSAny get _reactFragment;

@JS('React.Suspense')
external JSAny get _reactSuspense;

@JS('React.StrictMode')
external JSAny get _reactStrictMode;

@JS('React.forwardRef')
external JSAny _reactForwardRef(JSFunction render);

@JS('React.memo')
external JSAny _reactMemo(JSAny component, [JSFunction? areEqual]);

@JS('React.lazy')
external JSAny _reactLazy(JSFunction factory);

// =============================================================================
// Fragment
// =============================================================================

/// The Fragment type for grouping children without adding extra DOM nodes.
///
/// Use with [createElement] or the [fragment] helper function.
///
/// Example:
/// ```dart
/// createElement(Fragment, null, [child1, child2, child3]);
/// ```
///
/// See: https://reactjs.org/docs/fragments.html
JSAny get Fragment => _reactFragment;

/// Creates a Fragment element that groups children without adding extra
/// DOM nodes.
///
/// Example:
/// ```dart
/// fragment(children: [
///   h1('Title'),
///   pEl('Paragraph'),
/// ]);
/// ```
///
/// See: https://reactjs.org/docs/fragments.html
ReactElement fragment({List<ReactElement>? children}) =>
    (children != null && children.isNotEmpty)
    ? createElementWithChildren(_reactFragment, null, children)
    : createElement(_reactFragment);

// =============================================================================
// Suspense
// =============================================================================

/// The Suspense type for displaying a fallback while children are loading.
///
/// Use with [createElement] or the [suspense] helper function.
///
/// Example:
/// ```dart
/// createElement(
///   Suspense,
///   createProps({'fallback': loadingSpinner}),
///   lazyComponent,
/// );
/// ```
///
/// See: https://reactjs.org/docs/concurrent-mode-suspense.html
JSAny get Suspense => _reactSuspense;

/// Creates a Suspense element that displays [fallback] while [child] is
/// loading.
///
/// Example:
/// ```dart
/// suspense(
///   fallback: pEl('Loading...'),
///   child: lazyLoadedComponent,
/// );
/// ```
///
/// See: https://reactjs.org/docs/concurrent-mode-suspense.html
ReactElement suspense({
  required ReactElement fallback,
  ReactElement? child,
  List<ReactElement>? children,
}) {
  final props = createProps({'fallback': fallback});
  return (children != null && children.isNotEmpty)
      ? createElementWithChildren(_reactSuspense, props, children)
      : (child != null)
      ? createElement(_reactSuspense, props, child)
      : createElement(_reactSuspense, props);
}

// =============================================================================
// StrictMode
// =============================================================================

/// The StrictMode type for highlighting potential problems in an application.
///
/// StrictMode is a tool for highlighting potential problems in an application.
/// It activates additional checks and warnings for its descendants.
///
/// Note: Strict mode checks are run in development mode only; they do not
/// impact the production build.
///
/// Example:
/// ```dart
/// createElement(StrictMode, null, appRoot);
/// ```
///
/// See: https://reactjs.org/docs/strict-mode.html
JSAny get StrictMode => _reactStrictMode;

/// Creates a StrictMode wrapper element.
///
/// Example:
/// ```dart
/// strictMode(child: myApp);
/// ```
///
/// See: https://reactjs.org/docs/strict-mode.html
ReactElement strictMode({ReactElement? child, List<ReactElement>? children}) =>
    (children != null && children.isNotEmpty)
    ? createElementWithChildren(_reactStrictMode, null, children)
    : (child != null)
    ? createElement(_reactStrictMode, null, child)
    : createElement(_reactStrictMode);

// =============================================================================
// forwardRef
// =============================================================================

/// Typedef for a function component that receives props and a forwarded ref.
typedef ForwardRefRenderFunction =
    ReactElement Function(Map<String, Object?> props, JsRef? ref);

/// Creates a React component that forwards the ref attribute to a child.
///
/// Use this when you need to pass a ref through a component to one of its
/// children.
///
/// Example:
/// ```dart
/// final FancyButton = forwardRef2((props, ref) {
///   return button(
///     props: {'ref': ref, 'className': 'fancy-button'},
///     text: props['label'] as String,
///   );
/// });
///
/// // Usage:
/// final buttonRef = createRef<Element>();
/// createElement(FancyButton, createProps({
///   'label': 'Click me!',
///   'ref': buttonRef.jsRef,
/// }));
/// ```
///
/// See: https://reactjs.org/docs/forwarding-refs.html
JSAny forwardRef2(ForwardRefRenderFunction render, {String? displayName}) {
  JSAny jsRender(JSObject jsProps, JSAny? jsRef) {
    final dartified = jsProps.dartify();
    final props = (dartified is Map<Object?, Object?>)
        ? dartified.cast<String, Object?>()
        : <String, Object?>{};
    final ref = (jsRef != null) ? JsRef.fromJs(jsRef as JSObject) : null;
    return render(props, ref);
  }

  final component = _reactForwardRef(jsRender.toJS);
  if (displayName != null) {
    (component as JSObject)['displayName'] = displayName.toJS;
  }
  return component;
}

// =============================================================================
// memo
// =============================================================================

/// Creates a memoized version of a component that only re-renders when its
/// props have changed.
///
/// By default, it will only shallowly compare complex objects in the props
/// object. If you want control over the comparison, you can provide an
/// [arePropsEqual] function.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   return div(children: [pEl('Value: \${props['value']}')]);
/// });
///
/// final MemoizedComponent = memo2(MyComponent);
/// ```
///
/// With custom comparison:
/// ```dart
/// final MemoizedComponent = memo2(
///   MyComponent,
///   arePropsEqual: (prevProps, nextProps) {
///     return prevProps['id'] == nextProps['id'];
///   },
/// );
/// ```
///
/// See: https://reactjs.org/docs/react-api.html#reactmemo
JSAny memo2(
  JSAny component, {
  bool Function(Map<String, Object?> prevProps, Map<String, Object?> nextProps)?
  arePropsEqual,
}) {
  JSBoolean? jsAreEqual(JSObject prevProps, JSObject nextProps) {
    final prevDartified = prevProps.dartify();
    final nextDartified = nextProps.dartify();
    final prev = (prevDartified is Map<Object?, Object?>)
        ? prevDartified.cast<String, Object?>()
        : <String, Object?>{};
    final next = (nextDartified is Map<Object?, Object?>)
        ? nextDartified.cast<String, Object?>()
        : <String, Object?>{};
    return arePropsEqual!(prev, next).toJS;
  }

  return (arePropsEqual != null)
      ? _reactMemo(component, jsAreEqual.toJS)
      : _reactMemo(component);
}

// =============================================================================
// lazy
// =============================================================================

/// Creates a lazy-loaded component using dynamic imports.
///
/// The [load] function should return a Future that resolves to a component.
/// The lazy component should be rendered inside a `Suspense` component.
///
/// Example:
/// ```dart
/// // Define lazy component
/// final LazyComponent = lazy(() async {
///   // Simulate loading delay
///   await Future.delayed(Duration(seconds: 1));
///   return MyHeavyComponent;
/// });
///
/// // Use with Suspense
/// suspense(
///   fallback: pEl('Loading...'),
///   child: createElement(LazyComponent, props),
/// );
/// ```
///
/// See: https://reactjs.org/docs/code-splitting.html#reactlazy
JSAny lazy(Future<JSAny> Function() load) {
  Future<JSObject> jsLoad() async {
    final component = await load();
    // React.lazy expects a module with a 'default' export
    final module = JSObject();
    module['default'] = component;
    return module;
  }

  return _reactLazy((() => jsLoad().toJS).toJS);
}
