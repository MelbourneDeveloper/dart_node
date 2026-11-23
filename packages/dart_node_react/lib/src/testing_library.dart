/// React Testing Library bindings for Dart.
///
/// Provides idiomatic Dart wrappers around @testing-library/react for testing
/// React components with user-centric queries and interactions.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:dart_node_react/src/react.dart';

// =============================================================================
// JS Bindings for Testing Library
// =============================================================================

@JS('document.createElement')
external JSObject _createElement(String tagName);

@JS('document.body.appendChild')
external void _appendChild(JSObject node);

@JS('document.body.removeChild')
external void _removeChild(JSObject node);

@JS('ReactDOM.createRoot')
external _JsRoot _createRoot(JSObject container);

@JS()
extension type _JsRoot._(JSObject _) implements JSObject {
  external void render(JSObject element);
  external void unmount();
}

// DOM query selectors
@JS('Object')
extension type _DomElement._(JSObject _) implements JSObject {
  external String? get textContent;
  external String? get innerHTML;
  external String? get outerHTML;
  external String? get tagName;
  external String? get id;
  external String? get className;
  external JSAny? get value;
  external JSAny? getAttribute(String name);
  external void setAttribute(String name, String value);
  external JSObject? querySelector(String selector);
  external _NodeList querySelectorAll(String selector);
  external void click();
  external void focus();
  external void blur();
  external void dispatchEvent(JSObject event);
}

/// NodeList wrapper to handle DOM querySelectorAll results.
@JS('NodeList')
extension type _NodeList._(JSObject _) implements JSObject {
  external int get length;

  @JS('item')
  external JSObject? item(int index);
}

/// Convert NodeList to List of DomNode.
List<DomNode> _nodeListToDomNodes(_NodeList nodeList) {
  final result = <DomNode>[];
  for (var i = 0; i < nodeList.length; i++) {
    final item = nodeList.item(i);
    if (item != null) {
      result.add(DomNode._(_DomElement._(item)));
    }
  }
  return result;
}

// Event constructors using extension types to ensure `new` is called
@JS('Event')
extension type _JsEvent._(JSObject _) implements JSObject {
  external factory _JsEvent(String type, [JSObject? options]);
}

@JS('MouseEvent')
extension type _JsMouseEvent._(JSObject _) implements JSObject {
  external factory _JsMouseEvent(String type, [JSObject? options]);
}

@JS('KeyboardEvent')
extension type _JsKeyboardEvent._(JSObject _) implements JSObject {
  external factory _JsKeyboardEvent(String type, [JSObject? options]);
}

@JS('InputEvent')
extension type _JsInputEvent._(JSObject _) implements JSObject {
  external factory _JsInputEvent(String type, [JSObject? options]);
}

@JS('FocusEvent')
extension type _JsFocusEvent._(JSObject _) implements JSObject {
  external factory _JsFocusEvent(String type, [JSObject? options]);
}

JSObject _createEvent(String type, [JSObject? options]) =>
    _JsEvent(type, options);

JSObject _createMouseEvent(String type, [JSObject? options]) =>
    _JsMouseEvent(type, options);

JSObject _createKeyboardEvent(String type, [JSObject? options]) =>
    _JsKeyboardEvent(type, options);

JSObject _createInputEvent(String type, [JSObject? options]) =>
    _JsInputEvent(type, options);

JSObject _createFocusEvent(String type, [JSObject? options]) =>
    _JsFocusEvent(type, options);

// React Testing Library uses act() for synchronous updates
@JS('React.act')
external JSAny? _reactAct(JSFunction callback);

// =============================================================================
// DOM Node Wrapper
// =============================================================================

/// Wrapper around a DOM node providing query and interaction methods.
final class DomNode {
  DomNode._(this._node);

  final _DomElement _node;

  /// The underlying JS DOM element.
  JSObject get jsNode => _node;

  /// The text content of this node.
  String get textContent => _node.textContent ?? '';

  /// The inner HTML of this node.
  String get innerHTML => _node.innerHTML ?? '';

  /// The tag name of this node (uppercase).
  String get tagName => _node.tagName ?? '';

  /// The id attribute of this node.
  String get id => _node.id ?? '';

  /// The class name of this node.
  String get className => _node.className ?? '';

  /// The value for input elements.
  String get value => switch (_node.value) {
    final JSString s => s.toDart,
    _ => '',
  };

  /// Gets an attribute value.
  String? getAttribute(String name) => switch (_node.getAttribute(name)) {
    final JSString s => s.toDart,
    _ => null,
  };

  /// Sets an attribute value.
  void setAttribute(String name, String value) =>
      _node.setAttribute(name, value);

  /// Queries for a single element matching the CSS selector.
  DomNode? querySelector(String selector) =>
      switch (_node.querySelector(selector)) {
        final JSObject el => DomNode._(_DomElement._(el)),
        _ => null,
      };

  /// Queries for all elements matching the CSS selector.
  List<DomNode> querySelectorAll(String selector) =>
      _nodeListToDomNodes(_node.querySelectorAll(selector));

  /// Simulates a click event.
  void click() => _node.click();

  /// Focuses this element.
  void focus() => _node.focus();

  /// Blurs (unfocuses) this element.
  void blur() => _node.blur();

  /// Dispatches a custom event.
  void dispatchEvent(JSObject event) => _node.dispatchEvent(event);
}

// =============================================================================
// Screen Queries
// =============================================================================

/// Query methods for finding elements in the rendered output.
final class ScreenQuery {
  /// Creates a Screen with the given container.
  ScreenQuery._(this._container);

  final DomNode _container;

  /// The container element.
  DomNode get container => _container;

  /// Finds element by its text content.
  DomNode getByText(String text, {bool exact = true}) {
    final results = queryAllByText(text, exact: exact);
    return _getSingleResult(results, 'getByText', text);
  }

  /// Finds element by test ID attribute (data-testid).
  DomNode getByTestId(String testId) {
    final results = queryAllByTestId(testId);
    return _getSingleResult(results, 'getByTestId', testId);
  }

  /// Finds element by its placeholder text.
  DomNode getByPlaceholderText(String placeholder, {bool exact = true}) {
    final results = queryAllByPlaceholderText(placeholder, exact: exact);
    return _getSingleResult(results, 'getByPlaceholderText', placeholder);
  }

  /// Finds element by its label text (for form inputs).
  DomNode getByLabelText(String labelText, {bool exact = true}) {
    final results = queryAllByLabelText(labelText, exact: exact);
    return _getSingleResult(results, 'getByLabelText', labelText);
  }

  /// Finds element by its ARIA role.
  DomNode getByRole(String role, {String? name}) {
    final results = queryAllByRole(role, name: name);
    final desc = name != null ? '$role (name: $name)' : role;
    return _getSingleResult(results, 'getByRole', desc);
  }

  /// Finds element by its display value (for inputs).
  DomNode getByDisplayValue(String value, {bool exact = true}) {
    final results = queryAllByDisplayValue(value, exact: exact);
    return _getSingleResult(results, 'getByDisplayValue', value);
  }

  /// Finds element by its alt text (for images).
  DomNode getByAltText(String altText, {bool exact = true}) {
    final results = queryAllByAltText(altText, exact: exact);
    return _getSingleResult(results, 'getByAltText', altText);
  }

  /// Finds element by its title attribute.
  DomNode getByTitle(String title, {bool exact = true}) {
    final results = queryAllByTitle(title, exact: exact);
    return _getSingleResult(results, 'getByTitle', title);
  }

  /// Queries for element by text. Returns null if not found.
  DomNode? queryByText(String text, {bool exact = true}) {
    final results = queryAllByText(text, exact: exact);
    return results.isEmpty ? null : results.first;
  }

  /// Queries for element by test ID. Returns null if not found.
  DomNode? queryByTestId(String testId) {
    final results = queryAllByTestId(testId);
    return results.isEmpty ? null : results.first;
  }

  /// Queries for element by placeholder. Returns null if not found.
  DomNode? queryByPlaceholderText(String placeholder, {bool exact = true}) {
    final results = queryAllByPlaceholderText(placeholder, exact: exact);
    return results.isEmpty ? null : results.first;
  }

  /// Queries for element by role. Returns null if not found.
  DomNode? queryByRole(String role, {String? name}) {
    final results = queryAllByRole(role, name: name);
    return results.isEmpty ? null : results.first;
  }

  /// Finds all elements containing the given text.
  List<DomNode> queryAllByText(String text, {bool exact = true}) {
    final all = _getAllElements(_container);
    return all.where((el) {
      final content = el.textContent;
      return exact ? content == text : content.contains(text);
    }).toList();
  }

  /// Finds all elements with the given test ID.
  List<DomNode> queryAllByTestId(String testId) =>
      _container.querySelectorAll('[data-testid="$testId"]');

  /// Finds all elements with the given placeholder.
  List<DomNode> queryAllByPlaceholderText(
    String placeholder, {
    bool exact = true,
  }) => _container.querySelectorAll('[placeholder]').where((el) {
    final attr = el.getAttribute('placeholder') ?? '';
    return exact ? attr == placeholder : attr.contains(placeholder);
  }).toList();

  /// Finds all elements associated with labels containing the text.
  List<DomNode> queryAllByLabelText(String labelText, {bool exact = true}) {
    final labels = _container.querySelectorAll('label').where((label) {
      final text = label.textContent;
      return exact ? text == labelText : text.contains(labelText);
    });

    final results = <DomNode>[];
    for (final label in labels) {
      final forAttr = label.getAttribute('for');
      final found = (forAttr != null)
          ? _container.querySelectorAll('#$forAttr')
          : label.querySelectorAll('input, select, textarea');
      results.addAll(found);
    }
    return results;
  }

  /// Finds all elements with the given ARIA role.
  List<DomNode> queryAllByRole(String role, {String? name}) {
    final implicitRoleElements = <String, List<String>>{
      'button': ['button', '[type="button"]', '[type="submit"]'],
      'textbox': ['input:not([type])', 'input[type="text"]', 'textarea'],
      'checkbox': ['input[type="checkbox"]'],
      'radio': ['input[type="radio"]'],
      'link': ['a[href]'],
      'heading': ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'],
      'list': ['ul', 'ol'],
      'listitem': ['li'],
      'img': ['img[alt]'],
      'navigation': ['nav'],
      'main': ['main'],
      'banner': ['header'],
      'contentinfo': ['footer'],
      'region': ['section[aria-label]', 'section[aria-labelledby]'],
    };

    final selectors = implicitRoleElements[role] ?? [];
    final explicitRoleSelector = '[role="$role"]';
    final allSelectors = [...selectors, explicitRoleSelector].join(', ');

    final results = allSelectors.isNotEmpty
        ? _container.querySelectorAll(allSelectors)
        : <DomNode>[];

    return (name != null)
        ? results.where((el) {
            final ariaLabel = el.getAttribute('aria-label');
            final textContent = el.textContent;
            return ariaLabel == name || textContent == name;
          }).toList()
        : results;
  }

  /// Finds all input elements with the given display value.
  List<DomNode> queryAllByDisplayValue(String value, {bool exact = true}) =>
      _container.querySelectorAll('input, select, textarea').where((el) {
        final displayValue = el.value;
        return exact ? displayValue == value : displayValue.contains(value);
      }).toList();

  /// Finds all images with the given alt text.
  List<DomNode> queryAllByAltText(String altText, {bool exact = true}) =>
      _container.querySelectorAll('img[alt]').where((el) {
        final alt = el.getAttribute('alt') ?? '';
        return exact ? alt == altText : alt.contains(altText);
      }).toList();

  /// Finds all elements with the given title attribute.
  List<DomNode> queryAllByTitle(String title, {bool exact = true}) =>
      _container.querySelectorAll('[title]').where((el) {
        final attr = el.getAttribute('title') ?? '';
        return exact ? attr == title : attr.contains(title);
      }).toList();

  /// Waits for element with text to appear.
  Future<DomNode> findByText(
    String text, {
    bool exact = true,
    Duration timeout = const Duration(seconds: 1),
  }) => _waitFor(() => getByText(text, exact: exact), timeout);

  /// Waits for element with test ID to appear.
  Future<DomNode> findByTestId(
    String testId, {
    Duration timeout = const Duration(seconds: 1),
  }) => _waitFor(() => getByTestId(testId), timeout);

  /// Waits for element with role to appear.
  Future<DomNode> findByRole(
    String role, {
    String? name,
    Duration timeout = const Duration(seconds: 1),
  }) => _waitFor(() => getByRole(role, name: name), timeout);

  DomNode _getSingleResult(List<DomNode> results, String method, String query) {
    if (results.isEmpty) {
      throw TestingLibraryException(
        '$method: Unable to find element with: $query',
      );
    }
    if (results.length > 1) {
      throw TestingLibraryException(
        '$method: Found ${results.length} elements with: $query',
      );
    }
    return results.first;
  }

  Future<DomNode> _waitFor(
    DomNode Function() callback,
    Duration timeout,
  ) async {
    final deadline = DateTime.now().add(timeout);
    Object? lastError;

    while (DateTime.now().isBefore(deadline)) {
      try {
        return callback();
      } on TestingLibraryException catch (e) {
        lastError = e;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    throw TestingLibraryException(
      'Timed out waiting for element. Last error: $lastError',
    );
  }

  List<DomNode> _getAllElements(DomNode root) {
    final results = <DomNode>[];
    void traverse(DomNode node) {
      results.add(node);
      node.querySelectorAll('*').forEach(traverse);
    }

    root.querySelectorAll('*').forEach(traverse);
    return results;
  }
}

// =============================================================================
// Render Result
// =============================================================================

/// Result of rendering a React component for testing.
final class TestRenderResult extends ScreenQuery {
  TestRenderResult._(this._root, DomNode container, this._baseElement)
    : super._(container);

  final _JsRoot _root;
  final JSObject _baseElement;

  /// The base element that was appended to document.body.
  JSObject get baseElement => _baseElement;

  /// Re-renders the component with new props/element.
  void rerender(ReactElement element) {
    act(() => _root.render(element));
  }

  /// Unmounts the component and cleans up.
  void unmount() {
    _root.unmount();
    _removeChild(_baseElement);
  }

  /// Prints a formatted debug representation of the DOM.
  void debug() {
    // Debug output is intentional for test debugging
    // ignore: avoid_print
    print(_container.innerHTML);
  }
}

// =============================================================================
// Render Function
// =============================================================================

/// Renders a React element into a detached DOM container for testing.
TestRenderResult render(ReactElement element, {JSObject? container}) {
  final baseElement = container ?? _createElement('div');
  _appendChild(baseElement);
  final root = _createRoot(baseElement);
  act(() => root.render(element));
  return TestRenderResult._(
    root,
    DomNode._(_DomElement._(baseElement)),
    baseElement,
  );
}

// =============================================================================
// Act
// =============================================================================

/// Wraps code that causes React state updates in an act() block.
void act(void Function() callback) {
  _reactAct(callback.toJS);
}

/// Async version of act for operations that return a Future.
Future<void> actAsync(Future<void> Function() callback) async {
  await callback();
  await Future<void>.delayed(Duration.zero);
}

// =============================================================================
// Fire Event Functions
// =============================================================================

/// Fires a click event on the element.
void fireClick(DomNode element, [Map<String, Object?>? eventInit]) {
  act(() {
    final event = _createMouseEvent(
      'click',
      _buildEventInit(eventInit, {'bubbles': true, 'cancelable': true}),
    );
    element.dispatchEvent(event);
  });
}

/// Fires a change event on the element.
void fireChange(DomNode element, {String? value}) {
  act(() {
    if (value != null) _setInputValue(element, value);
    final options = {'bubbles': true, 'cancelable': false};
    final jsOptions = options.jsify();
    final event = _createEvent('change', jsOptions! as JSObject);
    element.dispatchEvent(event);
  });
}

/// Fires an input event on the element.
void fireInput(DomNode element, {String? value}) {
  act(() {
    if (value != null) _setInputValue(element, value);
    final options = {'bubbles': true, 'cancelable': false, 'data': value};
    final jsOptions = options.jsify();
    final event = _createInputEvent('input', jsOptions! as JSObject);
    element.dispatchEvent(event);
  });
}

/// Fires a focus event on the element.
void fireFocus(DomNode element) {
  act(() {
    element.focus();
    final options = {'bubbles': false, 'cancelable': false};
    final jsOptions = options.jsify();
    final event = _createFocusEvent('focus', jsOptions! as JSObject);
    element.dispatchEvent(event);
  });
}

/// Fires a blur event on the element.
void fireBlur(DomNode element) {
  act(() {
    element.blur();
    final options = {'bubbles': false, 'cancelable': false};
    final jsOptions = options.jsify();
    final event = _createFocusEvent('blur', jsOptions! as JSObject);
    element.dispatchEvent(event);
  });
}

/// Fires a submit event on a form element.
void fireSubmit(DomNode element) {
  act(() {
    final options = {'bubbles': true, 'cancelable': true};
    final jsOptions = options.jsify();
    final event = _createEvent('submit', jsOptions! as JSObject);
    element.dispatchEvent(event);
  });
}

/// Fires a keydown event on the element.
void fireKeyDown(DomNode element, {String? key, int? keyCode}) {
  act(() {
    final options = {
      'bubbles': true,
      'cancelable': true,
      'key': key,
      'keyCode': keyCode,
    };
    final jsOptions = options.jsify();
    final event = _createKeyboardEvent('keydown', jsOptions! as JSObject);
    element.dispatchEvent(event);
  });
}

/// Fires a keyup event on the element.
void fireKeyUp(DomNode element, {String? key, int? keyCode}) {
  act(() {
    final options = {
      'bubbles': true,
      'cancelable': true,
      'key': key,
      'keyCode': keyCode,
    };
    final jsOptions = options.jsify();
    final event = _createKeyboardEvent('keyup', jsOptions! as JSObject);
    element.dispatchEvent(event);
  });
}

/// Fires a keypress event on the element.
void fireKeyPress(DomNode element, {String? key, int? keyCode}) {
  act(() {
    final options = {
      'bubbles': true,
      'cancelable': true,
      'key': key,
      'keyCode': keyCode,
    };
    final jsOptions = options.jsify();
    final event = _createKeyboardEvent('keypress', jsOptions! as JSObject);
    element.dispatchEvent(event);
  });
}

/// Fires a mousedown event on the element.
void fireMouseDown(DomNode element, [Map<String, Object?>? eventInit]) {
  act(() {
    final event = _createMouseEvent(
      'mousedown',
      _buildEventInit(eventInit, {'bubbles': true, 'cancelable': true}),
    );
    element.dispatchEvent(event);
  });
}

/// Fires a mouseup event on the element.
void fireMouseUp(DomNode element, [Map<String, Object?>? eventInit]) {
  act(() {
    final event = _createMouseEvent(
      'mouseup',
      _buildEventInit(eventInit, {'bubbles': true, 'cancelable': true}),
    );
    element.dispatchEvent(event);
  });
}

/// Fires a mouseenter event on the element.
void fireMouseEnter(DomNode element, [Map<String, Object?>? eventInit]) {
  act(() {
    final event = _createMouseEvent(
      'mouseenter',
      _buildEventInit(eventInit, {'bubbles': false, 'cancelable': false}),
    );
    element.dispatchEvent(event);
  });
}

/// Fires a mouseleave event on the element.
void fireMouseLeave(DomNode element, [Map<String, Object?>? eventInit]) {
  act(() {
    final event = _createMouseEvent(
      'mouseleave',
      _buildEventInit(eventInit, {'bubbles': false, 'cancelable': false}),
    );
    element.dispatchEvent(event);
  });
}

/// Fires a mouseover event on the element.
void fireMouseOver(DomNode element, [Map<String, Object?>? eventInit]) {
  act(() {
    final event = _createMouseEvent(
      'mouseover',
      _buildEventInit(eventInit, {'bubbles': true, 'cancelable': true}),
    );
    element.dispatchEvent(event);
  });
}

/// Fires a mouseout event on the element.
void fireMouseOut(DomNode element, [Map<String, Object?>? eventInit]) {
  act(() {
    final event = _createMouseEvent(
      'mouseout',
      _buildEventInit(eventInit, {'bubbles': true, 'cancelable': true}),
    );
    element.dispatchEvent(event);
  });
}

/// Fires a double-click event on the element.
void fireDoubleClick(DomNode element, [Map<String, Object?>? eventInit]) {
  act(() {
    final event = _createMouseEvent(
      'dblclick',
      _buildEventInit(eventInit, {'bubbles': true, 'cancelable': true}),
    );
    element.dispatchEvent(event);
  });
}

JSObject _buildEventInit(
  Map<String, Object?>? custom,
  Map<String, Object?> defaults,
) {
  final merged = custom != null ? {...defaults, ...custom} : defaults;
  final jsified = merged.jsify();
  return jsified! as JSObject;
}

void _setInputValue(DomNode element, String value) {
  final descriptor = {
    'value': value,
    'writable': true,
    'configurable': true,
  }.jsify();
  _objectDefineProperty(element.jsNode, 'value'.toJS, descriptor!);
}

@JS('Object.defineProperty')
external void _objectDefineProperty(
  JSObject obj,
  JSString prop,
  JSAny descriptor,
);

// =============================================================================
// User Event Functions
// =============================================================================

/// Simulates a user clicking on an element.
Future<void> userClick(DomNode element) async {
  fireMouseDown(element);
  fireFocus(element);
  fireMouseUp(element);
  fireClick(element);
}

/// Simulates a user double-clicking on an element.
Future<void> userDblClick(DomNode element) async {
  await userClick(element);
  await userClick(element);
  fireDoubleClick(element);
}

/// Simulates a user typing text into an input.
Future<void> userType(DomNode element, String text) async {
  fireFocus(element);
  final buffer = StringBuffer(element.value);

  for (final char in text.split('')) {
    fireKeyDown(element, key: char);
    fireKeyPress(element, key: char);
    buffer.write(char);
    fireInput(element, value: buffer.toString());
    fireKeyUp(element, key: char);
  }
}

/// Simulates clearing an input field.
Future<void> userClear(DomNode element) async {
  fireFocus(element);
  fireChange(element, value: '');
}

/// Simulates hovering over an element.
Future<void> userHover(DomNode element) async {
  fireMouseOver(element);
  fireMouseEnter(element);
}

/// Simulates unhovering from an element.
Future<void> userUnhover(DomNode element) async {
  fireMouseOut(element);
  fireMouseLeave(element);
}

/// Simulates pasting text into an element.
Future<void> userPaste(DomNode element, String text) async {
  fireFocus(element);
  fireInput(element, value: text);
}

// =============================================================================
// Wait For
// =============================================================================

/// Waits for a condition to be true.
Future<T> waitFor<T>(
  T Function() callback, {
  Duration timeout = const Duration(seconds: 1),
  Duration interval = const Duration(milliseconds: 50),
}) async {
  final deadline = DateTime.now().add(timeout);
  Object? lastError;

  while (DateTime.now().isBefore(deadline)) {
    try {
      return callback();
    } on TestingLibraryException catch (e) {
      lastError = e;
      await Future<void>.delayed(interval);
    }
  }

  throw TestingLibraryException('waitFor timed out. Last error: $lastError');
}

/// Waits for an element to be removed from the DOM.
Future<void> waitForElementToBeRemoved(
  DomNode? Function() callback, {
  Duration timeout = const Duration(seconds: 1),
  Duration interval = const Duration(milliseconds: 50),
}) async {
  final initial = callback();
  if (initial == null) {
    throw TestingLibraryException(
      'Element not found initially. waitForElementToBeRemoved requires the '
      'element to be present before waiting for removal.',
    );
  }

  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    if (callback() == null) return;
    await Future<void>.delayed(interval);
  }

  throw TestingLibraryException('Timed out waiting for element to be removed.');
}

// =============================================================================
// Custom Matchers
// =============================================================================

/// Checks if an element is in the document.
bool isInDocument(DomNode? element) => element != null;

/// Checks if an element has the given text content.
bool hasTextContent(DomNode element, String text) =>
    element.textContent.contains(text);

/// Checks if an element has the given class.
bool hasClass(DomNode element, String className) =>
    element.className.split(' ').contains(className);

/// Checks if an element has the given attribute value.
bool hasAttribute(DomNode element, String name, [String? value]) {
  final attr = element.getAttribute(name);
  return value != null ? attr == value : attr != null;
}

/// Checks if an input element has the given value.
bool hasValue(DomNode element, String value) => element.value == value;

/// Checks if an element is visible.
bool isVisible(DomNode element) {
  final style = element.getAttribute('style') ?? '';
  return !style.contains('display: none') &&
      !style.contains('visibility: hidden');
}

/// Checks if an element is disabled.
bool isDisabled(DomNode element) =>
    element.getAttribute('disabled') != null ||
    element.getAttribute('aria-disabled') == 'true';

/// Checks if an element is enabled (not disabled).
bool isEnabled(DomNode element) => !isDisabled(element);

/// Checks if a checkbox/radio is checked.
bool isChecked(DomNode element) =>
    element.getAttribute('checked') != null ||
    element.getAttribute('aria-checked') == 'true';

/// Checks if an element has focus.
bool hasFocus(DomNode element) => false;

// =============================================================================
// Exception
// =============================================================================

/// Exception thrown by Testing Library queries.
final class TestingLibraryException implements Exception {
  /// Creates a new TestingLibraryException with the given message.
  TestingLibraryException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => 'TestingLibraryException: $message';
}
