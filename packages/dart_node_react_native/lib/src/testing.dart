/// React Native Testing Library for Dart.
///
/// Provides testing utilities for React Native components compiled from Dart.
/// Tests render components to a virtual tree and allow querying/interactions.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';

// =============================================================================
// Test Tree Node - Represents a rendered component
// =============================================================================

/// A node in the test render tree representing a React Native component.
final class TestNode {
  TestNode._({required this.type, required this.props, required this.children});

  /// Creates a TestNode for testing purposes.
  // ignore: prefer_constructors_over_static_methods
  static TestNode create({
    required String type,
    required Map<String, Object?> props,
    required List<TestNode> children,
  }) => TestNode._(type: type, props: props, children: children);

  /// The component type (e.g., 'View', 'Text', 'TextInput')
  final String type;

  /// The props passed to this component
  final Map<String, Object?> props;

  /// Child nodes
  final List<TestNode> children;

  /// Get the text content of this node and all descendants
  String get textContent {
    final buffer = StringBuffer();
    _collectText(this, buffer);
    return buffer.toString();
  }

  void _collectText(TestNode node, StringBuffer buffer) {
    // If this is a text node (child of Text component), add its content
    final text = node.props['__text__'];
    if (text != null) {
      buffer.write(text);
    }
    for (final child in node.children) {
      _collectText(child, buffer);
    }
  }

  /// Find all nodes matching a predicate
  List<TestNode> findAll(bool Function(TestNode) predicate) {
    final results = <TestNode>[];
    _findAll(this, predicate, results);
    return results;
  }

  void _findAll(
    TestNode node,
    bool Function(TestNode) predicate,
    List<TestNode> results,
  ) {
    if (predicate(node)) {
      results.add(node);
    }
    for (final child in node.children) {
      _findAll(child, predicate, results);
    }
  }

  /// Find nodes by component type
  List<TestNode> findByType(String componentType) =>
      findAll((node) => node.type == componentType);

  /// Find nodes containing text
  List<TestNode> findByText(String text, {bool exact = false}) => findAll(
    (node) =>
        exact ? node.textContent == text : node.textContent.contains(text),
  );

  /// Find nodes with a specific prop value
  List<TestNode> findByProp(String propName, Object? value) =>
      findAll((node) => node.props[propName] == value);

  /// Find nodes with testID prop
  List<TestNode> findByTestId(String testId) => findByProp('testID', testId);

  /// Fire onPress handler if present
  void firePress() {
    final onPress = props['onPress'];
    switch (onPress) {
      case final void Function() fn:
        fn();
      case final JSFunction fn:
        fn.callAsFunction();
      case null:
        throw TestingException('No onPress handler on $type');
    }
  }

  /// Fire onChangeText handler with value
  void fireChangeText(String text) {
    final onChangeText = props['onChangeText'];
    switch (onChangeText) {
      case final void Function(String) fn:
        fn(text);
      case final JSFunction fn:
        fn.callAsFunction(null, text.toJS);
      case null:
        throw TestingException('No onChangeText handler on $type');
    }
  }

  /// Fire onValueChange handler with value
  void fireValueChange(bool value) {
    final onValueChange = props['onValueChange'];
    switch (onValueChange) {
      case final void Function(bool) fn:
        fn(value);
      case final JSFunction fn:
        fn.callAsFunction(null, value.toJS);
      case null:
        throw TestingException('No onValueChange handler on $type');
    }
  }

  /// Get the value prop (for TextInput)
  String? get value {
    final v = props['value'];
    return switch (v) {
      final String s => s,
      _ => null,
    };
  }

  /// Get the placeholder prop (for TextInput)
  String? get placeholder {
    final p = props['placeholder'];
    return switch (p) {
      final String s => s,
      _ => null,
    };
  }

  @override
  String toString() => 'TestNode($type, children: ${children.length})';
}

// =============================================================================
// Test Render Result
// =============================================================================

/// Result of rendering a component for testing.
final class TestRenderResult {
  TestRenderResult._(this._root);

  /// Creates a TestRenderResult for testing purposes.
  // ignore: prefer_constructors_over_static_methods
  static TestRenderResult create(TestNode root) => TestRenderResult._(root);

  final TestNode _root;

  /// The root node of the render tree
  TestNode get root => _root;

  /// Get text content of entire tree
  String get textContent => _root.textContent;

  /// Find nodes by component type.
  List<TestNode> findByType(String type) => _root.findByType(type);

  /// Find nodes containing text.
  List<TestNode> findByText(String text, {bool exact = false}) =>
      _root.findByText(text, exact: exact);

  /// Find nodes with testID prop.
  List<TestNode> findByTestId(String testId) => _root.findByTestId(testId);

  /// Find nodes with a specific prop value.
  List<TestNode> findByProp(String name, Object? value) =>
      _root.findByProp(name, value);

  /// Get a single node by type
  TestNode getByType(String type) {
    final results = findByType(type);
    if (results.isEmpty) {
      throw TestingException('No node found with type: $type');
    }
    if (results.length > 1) {
      throw TestingException('Multiple nodes found with type: $type');
    }
    return results.first;
  }

  /// Get a single node by text
  TestNode getByText(String text, {bool exact = false}) {
    final results = findByText(text, exact: exact);
    if (results.isEmpty) {
      throw TestingException('No node found with text: $text');
    }
    if (results.length > 1) {
      throw TestingException('Multiple nodes found with text: $text');
    }
    return results.first;
  }

  /// Get a single node by testID
  TestNode getByTestId(String testId) {
    final results = findByTestId(testId);
    if (results.isEmpty) {
      throw TestingException('No node found with testID: $testId');
    }
    if (results.length > 1) {
      throw TestingException('Multiple nodes found with testID: $testId');
    }
    return results.first;
  }

  /// Query by type (returns null if not found) instead of throwing.
  TestNode? queryByType(String type) {
    final results = findByType(type);
    return results.isEmpty ? null : results.first;
  }

  /// Query by text (returns null if not found) instead of throwing.
  TestNode? queryByText(String text, {bool exact = false}) {
    final results = findByText(text, exact: exact);
    return results.isEmpty ? null : results.first;
  }

  /// Query by testID (returns null if not found) instead of throwing.
  TestNode? queryByTestId(String testId) {
    final results = findByTestId(testId);
    return results.isEmpty ? null : results.first;
  }

  /// Wait for text to appear
  Future<TestNode> waitForText(
    String text, {
    bool exact = false,
    Duration timeout = const Duration(seconds: 1),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final results = findByText(text, exact: exact);
      if (results.isNotEmpty) return results.first;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw TestingException('Timeout waiting for text: $text');
  }

  /// Debug print the tree
  void debug() {
    _printNode(_root, 0);
  }

  void _printNode(TestNode node, int indent) {
    final prefix = '  ' * indent;
    final propsStr = node.props.entries
        .where((e) => e.key != '__text__' && e.value != null)
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    // Debug output is intentional for test debugging purposes.
    // ignore: avoid_print
    print('$prefix<${node.type}${propsStr.isNotEmpty ? ' $propsStr' : ''}>');
    for (final child in node.children) {
      _printNode(child, indent + 1);
    }
  }
}

// =============================================================================
// Exception
// =============================================================================

/// Exception thrown by testing library.
final class TestingException implements Exception {
  /// Creates a new testing exception with the given message.
  TestingException(this.message);

  /// The exception message.
  final String message;

  @override
  String toString() => 'TestingException: $message';
}

// =============================================================================
// Mock React Native - Captures render tree instead of native rendering
// =============================================================================

/// Install mock React Native components for testing
void setupTestEnvironment() {
  // Mock React.createElement to capture the element tree
  _mockReactNative();
}

void _mockReactNative() {
  // Create mock RN components that track their children
  final mockRN = JSObject();

  // Each component just returns an object describing the render
  for (final comp in [
    'View',
    'Text',
    'TextInput',
    'TouchableOpacity',
    'Button',
    'ScrollView',
    'SafeAreaView',
    'ActivityIndicator',
    'FlatList',
    'Image',
    'Switch',
  ]) {
    mockRN[comp] = comp.toJS;
  }

  // Mock AppRegistry
  final mockAppRegistry = JSObject();
  mockAppRegistry['registerComponent'] =
      ((JSString name, JSFunction provider) {}).toJS;
  mockRN['AppRegistry'] = mockAppRegistry;

  globalContext['reactNative'] = mockRN;
}

/// Render a React element for testing.
TestRenderResult renderForTest(ReactElement element) =>
    TestRenderResult._(_elementToTestNode(element));

TestNode _elementToTestNode(JSAny? element) {
  if (element == null) {
    return TestNode._(type: 'null', props: {}, children: []);
  }

  // Check if it's a ReactElement (has type and props)
  if (element.isA<JSObject>()) {
    final jsElement = element as JSObject;
    final typeVal = jsElement['type'];
    final propsVal = jsElement['props'];

    // Get component type
    String type;
    if (typeVal != null && typeVal.isA<JSString>()) {
      type = (typeVal as JSString).toDart;
    } else if (typeVal != null && typeVal.isA<JSFunction>()) {
      // Functional component - call it to get the rendered element
      final fn = typeVal as JSFunction;
      final rendered = fn.callAsFunction(null, propsVal ?? JSObject());
      return _elementToTestNode(rendered);
    } else {
      type = 'Unknown';
    }

    // Parse props
    final props = <String, Object?>{};
    if (propsVal != null && propsVal.isA<JSObject>()) {
      final jsProps = propsVal as JSObject;
      final keys = _getObjectKeys(jsProps);
      for (final key in keys) {
        if (key == 'children') continue; // Handle separately
        final value = jsProps[key];
        props[key] = _jsToValue(value);
      }
    }

    // Parse children
    final children = <TestNode>[];
    final childrenVal = (propsVal != null && propsVal.isA<JSObject>())
        ? (propsVal as JSObject)['children']
        : null;
    if (childrenVal != null) {
      if (childrenVal.isA<JSArray>()) {
        final arr = childrenVal as JSArray;
        for (var i = 0; i < arr.length; i++) {
          final child = arr[i];
          if (child != null) {
            children.add(_elementToTestNode(child));
          }
        }
      } else if (childrenVal.isA<JSString>()) {
        // Text content
        props['__text__'] = (childrenVal as JSString).toDart;
      } else if (childrenVal.isA<JSObject>()) {
        children.add(_elementToTestNode(childrenVal));
      }
    }

    return TestNode._(type: type, props: props, children: children);
  }

  // Primitive text
  if (element.isA<JSString>()) {
    return TestNode._(
      type: 'TextContent',
      props: {'__text__': (element as JSString).toDart},
      children: [],
    );
  }

  return TestNode._(type: 'Unknown', props: {}, children: []);
}

List<String> _getObjectKeys(JSObject obj) {
  final keys = _objectKeys(obj);
  final result = <String>[];
  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    if (key != null && key.isA<JSString>()) {
      result.add((key as JSString).toDart);
    }
  }
  return result;
}

@JS('Object.keys')
external JSArray _objectKeys(JSObject obj);

Object? _jsToValue(JSAny? value) {
  if (value == null) return null;
  if (value.isA<JSString>()) return (value as JSString).toDart;
  if (value.isA<JSBoolean>()) return (value as JSBoolean).toDart;
  if (value.isA<JSNumber>()) return (value as JSNumber).toDartDouble;
  // Keep functions for event handlers
  if (value.isA<JSFunction>()) return value;
  // Keep objects for complex props
  if (value.isA<JSObject>()) return value;
  return value.dartify();
}

// =============================================================================
// User Interaction Helpers
// =============================================================================

/// Simulate typing into a TextInput.
Future<void> userType(TestNode input, String text) async {
  if (input.type != 'TextInput') {
    throw TestingException('userType requires a TextInput node');
  }

  // Type character by character
  final buffer = StringBuffer(input.value ?? '');
  for (final char in text.split('')) {
    buffer.write(char);
    input.fireChangeText(buffer.toString());
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Simulate pressing a touchable element
void userPress(TestNode node) {
  node.firePress();
}

/// Clear a text input
void userClear(TestNode input) {
  input.fireChangeText('');
}
