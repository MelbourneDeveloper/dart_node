/// React Test Utilities for testing React components in Dart.
///
/// Provides wrappers around React.addons.TestUtils for simulating events
/// and testing component rendering.
// The Simulate class mirrors React's API which is a namespace with static
// methods.
// ignore_for_file: avoid_classes_with_only_static_members
library;

import 'dart:js_interop';

import 'package:dart_node_react/src/react.dart';

// =============================================================================
// React Test Utils JS Bindings
// =============================================================================

@JS('ReactDOM.createRoot')
external _JsRoot _createRoot(JSObject container);

@JS()
extension type _JsRoot._(JSObject _) implements JSObject {
  external void render(JSObject element);
  external void unmount();
}

@JS('document.createElement')
external JSObject _createElement(String tagName);

@JS('React.addons.TestUtils.renderIntoDocument')
external JSAny? _renderIntoDocument(JSObject? instance);

@JS('React.addons.TestUtils.findRenderedDOMComponentWithClass')
external JSAny? _findRenderedDOMComponentWithClass(
  JSAny? tree,
  String className,
);

@JS('React.addons.TestUtils.findRenderedDOMComponentWithTag')
external JSAny? _findRenderedDOMComponentWithTag(JSAny? tree, String tag);

@JS('React.addons.TestUtils.scryRenderedDOMComponentsWithClass')
external JSArray _scryRenderedDOMComponentsWithClass(
  JSAny? tree,
  String className,
);

@JS('React.addons.TestUtils.scryRenderedDOMComponentsWithTag')
external JSArray _scryRenderedDOMComponentsWithTag(
  JSAny? tree,
  String tagName,
);

@JS('React.addons.TestUtils.isDOMComponent')
external bool _isDOMComponent(JSAny? instance);

@JS('React.addons.TestUtils.isElement')
external bool _isElement(JSAny? object);

@JS('React.addons.TestUtils.isCompositeComponent')
external bool _isCompositeComponent(JSAny? instance);

// Simulate events
@JS('React.addons.TestUtils.Simulate.click')
external void _simulateClick(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.change')
external void _simulateChange(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.submit')
external void _simulateSubmit(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.focus')
external void _simulateFocus(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.blur')
external void _simulateBlur(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.keyDown')
external void _simulateKeyDown(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.keyUp')
external void _simulateKeyUp(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.keyPress')
external void _simulateKeyPress(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.mouseDown')
external void _simulateMouseDown(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.mouseUp')
external void _simulateMouseUp(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.mouseEnter')
external void _simulateMouseEnter(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.mouseLeave')
external void _simulateMouseLeave(JSAny? node, [JSObject? eventData]);

@JS('React.addons.TestUtils.Simulate.input')
external void _simulateInput(JSAny? node, [JSObject? eventData]);

// =============================================================================
// Test Render Result
// =============================================================================

/// Result of rendering a React element for testing.
///
/// Provides methods to query and interact with the rendered component.
final class RenderResult {
  RenderResult._(this._root, this._container);

  final _JsRoot _root;
  final JSObject _container;

  /// The container DOM element.
  JSObject get container => _container;

  /// Unmounts the rendered component and cleans up.
  void unmount() {
    _root.unmount();
  }

  /// Finds a single DOM element with the given class name.
  /// Throws if zero or more than one element is found.
  JSAny? findByClass(String className) =>
      _findRenderedDOMComponentWithClass(_container, className);

  /// Finds a single DOM element with the given tag name.
  /// Throws if zero or more than one element is found.
  JSAny? findByTag(String tagName) =>
      _findRenderedDOMComponentWithTag(_container, tagName);

  /// Finds all DOM elements with the given class name.
  List<JSAny?> queryAllByClass(String className) =>
      _scryRenderedDOMComponentsWithClass(_container, className).toDart;

  /// Finds all DOM elements with the given tag name.
  List<JSAny?> queryAllByTag(String tagName) =>
      _scryRenderedDOMComponentsWithTag(_container, tagName).toDart;
}

// =============================================================================
// Render Functions
// =============================================================================

/// Renders a React element into a detached DOM node for testing.
///
/// Returns a [RenderResult] that provides methods to query and interact
/// with the rendered component.
///
/// Example:
/// ```dart
/// test('counter increments', () {
///   final result = render(Counter({'initialCount': 0}));
///   final button = result.findByTag('button');
///   Simulate.click(button);
///   // Assert the count increased
///   result.unmount();
/// });
/// ```
RenderResult render(ReactElement element) {
  final container = _createElement('div');
  final root = _createRoot(container)..render(element);
  return RenderResult._(root, container);
}

/// Renders a React element into a detached DOM node (legacy API).
///
/// Returns the rendered component instance.
///
/// Note: Prefer [render] for new code as it returns a [RenderResult]
/// with helpful query methods.
JSAny? renderIntoDocument(ReactElement element) =>
    _renderIntoDocument(element);

// =============================================================================
// Query Functions
// =============================================================================

/// Returns true if [object] is a valid React element.
bool isElement(JSAny? object) => _isElement(object);

/// Returns true if [instance] is a DOM component (such as `<div>` or `<span>`).
bool isDOMComponent(JSAny? instance) => _isDOMComponent(instance);

/// Returns true if [instance] is a composite component (created with
/// registerFunctionComponent or forwardRef2).
bool isCompositeComponent(JSAny? instance) => _isCompositeComponent(instance);

// =============================================================================
// Event Simulation
// =============================================================================

JSObject? _jsifyEventData(Map<String, Object?>? eventData) =>
    (eventData != null) ? eventData.jsify() as JSObject? : null;

/// Event simulation interface.
///
/// Provides methods for simulating user interactions with React components.
///
/// Example:
/// ```dart
/// final button = result.findByTag('button');
/// Simulate.click(button);
///
/// final input = result.findByTag('input');
/// Simulate.change(input, {'target': {'value': 'hello'}});
/// ```
abstract final class Simulate {
  /// Simulates a click event on [node].
  static void click(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateClick(node, _jsifyEventData(eventData));

  /// Simulates a change event on [node].
  static void change(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateChange(node, _jsifyEventData(eventData));

  /// Simulates a submit event on [node].
  static void submit(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateSubmit(node, _jsifyEventData(eventData));

  /// Simulates a focus event on [node].
  static void focus(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateFocus(node, _jsifyEventData(eventData));

  /// Simulates a blur event on [node].
  static void blur(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateBlur(node, _jsifyEventData(eventData));

  /// Simulates a keyDown event on [node].
  static void keyDown(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateKeyDown(node, _jsifyEventData(eventData));

  /// Simulates a keyUp event on [node].
  static void keyUp(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateKeyUp(node, _jsifyEventData(eventData));

  /// Simulates a keyPress event on [node].
  static void keyPress(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateKeyPress(node, _jsifyEventData(eventData));

  /// Simulates a mouseDown event on [node].
  static void mouseDown(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateMouseDown(node, _jsifyEventData(eventData));

  /// Simulates a mouseUp event on [node].
  static void mouseUp(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateMouseUp(node, _jsifyEventData(eventData));

  /// Simulates a mouseEnter event on [node].
  static void mouseEnter(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateMouseEnter(node, _jsifyEventData(eventData));

  /// Simulates a mouseLeave event on [node].
  static void mouseLeave(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateMouseLeave(node, _jsifyEventData(eventData));

  /// Simulates an input event on [node].
  static void input(JSAny? node, [Map<String, Object?>? eventData]) =>
      _simulateInput(node, _jsifyEventData(eventData));
}
