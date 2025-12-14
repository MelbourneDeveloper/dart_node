/// Tests for the React Native testing library.
library;

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  test('TestNode findByType returns matching nodes', () {
    final root = _createTestTree();
    final views = root.findByType('View');
    expect(views.length, equals(2));
  });

  test('TestNode findByType returns empty list when no match', () {
    final root = _createTestTree();
    final buttons = root.findByType('NonExistent');
    expect(buttons, isEmpty);
  });

  test('TestNode findByText with exact match', () {
    final root = _createTestTree();
    final nodes = root.findByText('Hello', exact: true);
    // Returns multiple nodes because parent textContent includes children
    expect(nodes, isNotEmpty);
    expect(nodes.any((n) => n.type == 'Text'), isTrue);
  });

  test('TestNode findByText with partial match', () {
    final root = _createTestTree();
    final nodes = root.findByText('ello');
    // Returns nodes where textContent contains 'ello'
    expect(nodes, isNotEmpty);
  });

  test('TestNode findByText returns empty when no match', () {
    final root = _createTestTree();
    final nodes = root.findByText('NotFound', exact: true);
    expect(nodes, isEmpty);
  });

  test('TestNode findByProp finds nodes with matching prop', () {
    final root = _createTestTree();
    final nodes = root.findByProp('disabled', true);
    expect(nodes.length, equals(1));
  });

  test('TestNode findByTestId finds nodes with testID', () {
    final root = _createTestTree();
    final nodes = root.findByTestId('my-button');
    expect(nodes.length, equals(1));
    expect(nodes.first.type, equals('Button'));
  });

  test('TestNode findAll with custom predicate', () {
    final root = _createTestTree();
    final nodes = root.findAll((node) => node.props.containsKey('style'));
    expect(nodes.length, equals(1));
  });

  test('TestNode textContent collects all text', () {
    final root = _createTestTreeWithText();
    expect(root.textContent, contains('First'));
    expect(root.textContent, contains('Second'));
  });

  test('TestNode firePress calls onPress handler', () {
    var pressed = false;
    _createNodeWithHandler(onPress: () => pressed = true).firePress();
    expect(pressed, isTrue);
  });

  test('TestNode firePress throws when no handler', () {
    final node = _createNodeWithoutHandlers();
    expect(node.firePress, throwsA(isA<TestingException>()));
  });

  test('TestNode fireChangeText calls onChangeText handler', () {
    String? receivedText;
    _createNodeWithHandler(
      onChangeText: (text) => receivedText = text,
    ).fireChangeText('test value');
    expect(receivedText, equals('test value'));
  });

  test('TestNode fireChangeText throws when no handler', () {
    final node = _createNodeWithoutHandlers();
    expect(() => node.fireChangeText('test'), throwsA(isA<TestingException>()));
  });

  test('TestNode fireValueChange calls onValueChange handler', () {
    bool? receivedValue;
    _createNodeWithHandler(
      onValueChange: (value) => receivedValue = value,
    ).fireValueChange(true);
    expect(receivedValue, isTrue);
  });

  test('TestNode fireValueChange throws when no handler', () {
    final node = _createNodeWithoutHandlers();
    expect(() => node.fireValueChange(true), throwsA(isA<TestingException>()));
  });

  test('TestNode value getter returns value prop', () {
    final node = _createTextInputNode(value: 'current value');
    expect(node.value, equals('current value'));
  });

  test('TestNode value getter returns null when no value', () {
    final node = _createTextInputNode();
    expect(node.value, isNull);
  });

  test('TestNode placeholder getter returns placeholder prop', () {
    final node = _createTextInputNode(placeholder: 'Enter text');
    expect(node.placeholder, equals('Enter text'));
  });

  test('TestNode placeholder getter returns null when no placeholder', () {
    final node = _createTextInputNode();
    expect(node.placeholder, isNull);
  });

  test('TestNode toString returns type and child count', () {
    final node = _createTestTree();
    expect(node.toString(), contains('View'));
    expect(node.toString(), contains('children:'));
  });

  test('TestNode children is accessible', () {
    final root = _createTestTree();
    expect(root.children, isNotEmpty);
    expect(root.children.first.type, equals('View'));
  });

  test('TestNode type is accessible', () {
    final root = _createTestTree();
    expect(root.type, equals('View'));
  });

  test('TestNode props is accessible', () {
    final node = _createNodeWithProps({'testID': 'test', 'disabled': true});
    expect(node.props['testID'], equals('test'));
    expect(node.props['disabled'], isTrue);
  });

  test('TestingException message is accessible', () {
    final exception = TestingException('Test error message');
    expect(exception.toString(), contains('Test error message'));
  });

  test('findByType traverses nested children', () {
    final deepTree = _createDeepTree();
    final textNodes = deepTree.findByType('Text');
    expect(textNodes.length, equals(3));
  });

  test('findByText traverses nested children', () {
    final deepTree = _createDeepTreeWithText();
    final nodes = deepTree.findByText('Deep text');
    // All ancestors and the Text node itself match since textContent bubbles up
    expect(nodes, isNotEmpty);
    expect(nodes.any((n) => n.type == 'Text'), isTrue);
  });

  test('empty children list is handled', () {
    final emptyNode = _createEmptyNode();
    expect(emptyNode.children, isEmpty);
    // findByType includes the node itself if it matches
    expect(emptyNode.findByType('Button'), isEmpty);
  });

  test('textContent on node without text returns empty string', () {
    final emptyNode = _createEmptyNode();
    expect(emptyNode.textContent, isEmpty);
  });

  // TestRenderResult tests
  test('TestRenderResult.root returns the root node', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    expect(result.root, equals(root));
  });

  test('TestRenderResult.textContent returns all text', () {
    final root = _createTestTreeWithText();
    final result = TestRenderResult.create(root);
    expect(result.textContent, contains('First'));
    expect(result.textContent, contains('Second'));
  });

  test('TestRenderResult.findByType delegates to root', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    final views = result.findByType('View');
    expect(views.length, equals(2));
  });

  test('TestRenderResult.findByText delegates to root', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    final nodes = result.findByText('Hello');
    expect(nodes, isNotEmpty);
  });

  test('TestRenderResult.findByTestId delegates to root', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    final nodes = result.findByTestId('my-button');
    expect(nodes.length, equals(1));
  });

  test('TestRenderResult.findByProp delegates to root', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    final nodes = result.findByProp('disabled', true);
    expect(nodes.length, equals(1));
  });

  test('TestRenderResult.getByType returns single matching node', () {
    final root = _createSingleButtonTree();
    final result = TestRenderResult.create(root);
    final button = result.getByType('Button');
    expect(button.type, equals('Button'));
  });

  test('TestRenderResult.getByType throws when not found', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    expect(
      () => result.getByType('NonExistent'),
      throwsA(isA<TestingException>()),
    );
  });

  test('TestRenderResult.getByType throws when multiple found', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    expect(() => result.getByType('View'), throwsA(isA<TestingException>()));
  });

  test('TestRenderResult.getByText returns single matching node', () {
    final root = _createSingleTextTree();
    final result = TestRenderResult.create(root);
    final text = result.getByText('OnlyText', exact: true);
    expect(text.type, equals('Text'));
  });

  test('TestRenderResult.getByText throws when not found', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    expect(
      () => result.getByText('NonExistent', exact: true),
      throwsA(isA<TestingException>()),
    );
  });

  test('TestRenderResult.getByTestId returns single matching node', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    final button = result.getByTestId('my-button');
    expect(button.type, equals('Button'));
  });

  test('TestRenderResult.getByTestId throws when not found', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    expect(
      () => result.getByTestId('nonexistent-id'),
      throwsA(isA<TestingException>()),
    );
  });

  test('TestRenderResult.queryByType returns node or null', () {
    final root = _createSingleButtonTree();
    final result = TestRenderResult.create(root);
    expect(result.queryByType('Button'), isNotNull);
    expect(result.queryByType('NonExistent'), isNull);
  });

  test('TestRenderResult.queryByText returns node or null', () {
    final root = _createSingleTextTree();
    final result = TestRenderResult.create(root);
    expect(result.queryByText('OnlyText', exact: true), isNotNull);
    expect(result.queryByText('NonExistent', exact: true), isNull);
  });

  test('TestRenderResult.queryByTestId returns node or null', () {
    final root = _createTestTree();
    final result = TestRenderResult.create(root);
    expect(result.queryByTestId('my-button'), isNotNull);
    expect(result.queryByTestId('nonexistent-id'), isNull);
  });

  // User interaction helper tests
  test('userPress calls firePress on node', () {
    var pressed = false;
    final node = _createNodeWithHandler(onPress: () => pressed = true);
    userPress(node);
    expect(pressed, isTrue);
  });

  test('userClear calls fireChangeText with empty string', () {
    String? lastText;
    final node = _createNodeWithHandler(onChangeText: (t) => lastText = t);
    userClear(node);
    expect(lastText, equals(''));
  });

  test('TestRenderResult.getByText throws when multiple nodes match', () {
    // Create tree where multiple nodes have same textContent due to bubbling
    final root = _createDuplicateTextTree();
    final result = TestRenderResult.create(root);
    expect(
      () => result.getByText('SameText', exact: true),
      throwsA(isA<TestingException>()),
    );
  });

  test('TestRenderResult.getByTestId throws when multiple found', () {
    final root = _createDuplicateTestIdTree();
    final result = TestRenderResult.create(root);
    expect(
      () => result.getByTestId('duplicate-id'),
      throwsA(isA<TestingException>()),
    );
  });

  test('TestNode findAll returns root if predicate matches', () {
    final root = _node('MatchThis', {}, []);
    final results = root.findAll((n) => n.type == 'MatchThis');
    expect(results.length, equals(1));
    expect(results.first, equals(root));
  });

  test('userType throws for non-TextInput node', () {
    final node = _node('Button', {}, []);
    expect(() => userType(node, 'text'), throwsA(isA<TestingException>()));
  });
}

// Helper functions to create test nodes

TestNode _createSingleButtonTree() => _node('View', {}, [
  _node('Button', {'testID': 'btn'}, []),
]);

TestNode _createSingleTextTree() => _node('Text', {'__text__': 'OnlyText'}, []);

TestNode _createTestTree() => _node('View', {}, [
  _node('View', {
    'style': {'flex': 1},
  }, []),
  _node('Button', {'testID': 'my-button', 'disabled': true}, []),
  _node('Text', {'__text__': 'Hello'}, []),
]);

TestNode _createTestTreeWithText() => _node('View', {}, [
  _node('Text', {'__text__': 'First'}, []),
  _node('View', {}, [
    _node('Text', {'__text__': 'Second'}, []),
  ]),
]);

TestNode _createNodeWithHandler({
  void Function()? onPress,
  void Function(String)? onChangeText,
  void Function(bool)? onValueChange,
}) => _node('Button', {
  'onPress': ?onPress,
  'onChangeText': ?onChangeText,
  'onValueChange': ?onValueChange,
}, []);

TestNode _createNodeWithoutHandlers() => _node('Button', {}, []);

TestNode _createTextInputNode({String? value, String? placeholder}) =>
    _node('TextInput', {'value': ?value, 'placeholder': ?placeholder}, []);

TestNode _createNodeWithProps(Map<String, Object?> props) =>
    _node('View', props, []);

TestNode _createDeepTree() => _node('View', {}, [
  _node('View', {}, [
    _node('Text', {}, []),
    _node('View', {}, [_node('Text', {}, []), _node('Text', {}, [])]),
  ]),
]);

TestNode _createDeepTreeWithText() => _node('View', {}, [
  _node('View', {}, [
    _node('View', {}, [
      _node('Text', {'__text__': 'Deep text'}, []),
    ]),
  ]),
]);

TestNode _createEmptyNode() => _node('View', {}, []);

TestNode _createDuplicateTextTree() => _node('View', {}, [
  _node('Text', {'__text__': 'SameText'}, []),
  _node('Text', {'__text__': 'SameText'}, []),
]);

TestNode _createDuplicateTestIdTree() => _node('View', {}, [
  _node('Button', {'testID': 'duplicate-id'}, []),
  _node('Button', {'testID': 'duplicate-id'}, []),
]);

// Expose TestNode constructor through a helper since it's private
TestNode _node(
  String type,
  Map<String, Object?> props,
  List<TestNode> children,
) => TestNode.create(type: type, props: props, children: children);
