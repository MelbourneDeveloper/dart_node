/// ReactDOM bindings for Dart.
///
/// Provides methods for rendering React elements to the DOM.
library;

import 'dart:js_interop';

import 'package:dart_node_react/src/react.dart';

// Re-export core types from react.dart
export 'react.dart' show Document, ReactDOM, ReactRoot;

// =============================================================================
// ReactDOM JS Bindings
// =============================================================================

@JS('ReactDOM.createPortal')
external JSObject _reactDomCreatePortal(JSAny children, JSObject container);

@JS('ReactDOM.flushSync')
external JSAny? _reactDomFlushSync(JSFunction callback);

@JS('ReactDOM.createRoot')
external ReactRoot _reactDomCreateRoot(JSObject container);

@JS('ReactDOM.hydrateRoot')
external ReactRoot _reactDomHydrateRoot(
  JSObject container,
  JSObject initialChildren,
);

// =============================================================================
// ReactPortal Type
// =============================================================================

/// A virtual DOM node representing a React Portal.
///
/// Portals provide a first-class way to render children into a DOM node that
/// exists outside the DOM hierarchy of the parent component.
///
/// See: https://reactjs.org/docs/portals.html
extension type ReactPortal._(JSObject _) implements JSObject {
  /// Creates a ReactPortal from a raw JSObject.
  factory ReactPortal.fromJs(JSObject jsObject) = ReactPortal._;

  /// The children rendered by this portal.
  @JS('children')
  external JSAny? get children;

  /// The container element where children are rendered.
  @JS('containerInfo')
  external JSAny? get containerInfo;
}

// =============================================================================
// ReactDOM Helper Functions
// =============================================================================

/// Creates a React root for rendering into a DOM node (React 18+).
///
/// This is the recommended way to render React applications in React 18+.
///
/// Example:
/// ```dart
/// final container = Document.getElementById('root')!;
/// final root = createRoot(container);
/// root.render(myApp);
/// ```
///
/// See: https://react.dev/reference/react-dom/client/createRoot
ReactRoot createRoot(JSObject container) => _reactDomCreateRoot(container);

/// Creates a React root for hydrating server-rendered content (React 18+).
///
/// Use this instead of `createRoot` when hydrating a container whose HTML
/// contents were rendered by ReactDOMServer.
///
/// Example:
/// ```dart
/// final container = Document.getElementById('root')!;
/// final root = hydrateRoot(container, myApp);
/// ```
///
/// See: https://react.dev/reference/react-dom/client/hydrateRoot
ReactRoot hydrateRoot(JSObject container, ReactElement initialChildren) =>
    _reactDomHydrateRoot(container, initialChildren);

/// Renders a React element into a portal, allowing it to appear in a different
/// part of the DOM tree.
///
/// Portals provide a first-class way to render children into a DOM node that
/// exists outside the DOM hierarchy of the parent component.
///
/// Example:
/// ```dart
/// final modalRoot = Document.getElementById('modal-root')!;
/// final modal = createPortal(
///   div(children: [pEl('Modal content')]),
///   modalRoot,
/// );
/// ```
///
/// See: https://react.dev/reference/react-dom/createPortal
ReactPortal createPortal(ReactElement children, JSObject container) =>
    ReactPortal.fromJs(_reactDomCreatePortal(children, container));

/// Lets you force React to flush any updates inside the provided callback
/// synchronously.
///
/// This ensures that the DOM is updated immediately. Use sparingly as it can
/// hurt performance.
///
/// Example:
/// ```dart
/// flushSync(() {
///   state.set(newValue);
/// });
/// // DOM has been updated
/// ```
///
/// See: https://react.dev/reference/react-dom/flushSync
void flushSync(void Function() callback) {
  _reactDomFlushSync(callback.toJS);
}
