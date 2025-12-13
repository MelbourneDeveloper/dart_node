/// Tests proving npmComponent() can use ANY npm package directly.
///
/// These tests demonstrate that we can drop npm packages right in
/// and use them exactly like TypeScript - no wrapper code needed!
@TestOn('js')
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  test('loadNpmModule loads react successfully', () {
    final result = loadNpmModule('react');
    expect(result.isSuccess, isTrue);
  });

  test('loadNpmModule loads react-native successfully', () {
    final result = loadNpmModule('react-native');
    expect(result.isSuccess, isTrue);
  });

  test('loadNpmModule caches modules', () {
    clearNpmModuleCache();
    expect(isModuleCached('react'), isFalse);

    loadNpmModule('react');
    expect(isModuleCached('react'), isTrue);

    // Second call uses cache
    final result2 = loadNpmModule('react');
    expect(result2.isSuccess, isTrue);
  });

  test('loadNpmModule returns error for nonexistent package', () {
    final result = loadNpmModule('nonexistent-package-xyz-123');
    expect(result.isSuccess, isFalse);
  });

  test('getComponentFromModule gets View from react-native', () {
    final moduleResult = loadNpmModule('react-native');
    final module = switch (moduleResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    final viewResult = getComponentFromModule(module, 'View');
    expect(viewResult.isSuccess, isTrue);
  });

  test('getComponentFromModule gets Text from react-native', () {
    final moduleResult = loadNpmModule('react-native');
    final module = switch (moduleResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    final textResult = getComponentFromModule(module, 'Text');
    expect(textResult.isSuccess, isTrue);
  });

  test('getComponentFromModule returns error for nonexistent component', () {
    final moduleResult = loadNpmModule('react-native');
    final module = switch (moduleResult) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };

    final result = getComponentFromModule(module, 'NonExistentComponent');
    expect(result.isSuccess, isFalse);
  });

  test('npmComponent creates View element from react-native', () {
    final element = npmComponent(
      'react-native',
      'View',
      props: {'style': {'flex': 1}},
    );
    expect(element, isNotNull);
  });

  test('npmComponent creates Text element with child', () {
    final element = npmComponent(
      'react-native',
      'Text',
      child: 'Hello World'.toJS,
    );
    expect(element, isNotNull);
  });

  test('npmComponent creates element with children list', () {
    final child1 = npmComponent('react-native', 'Text', child: 'One'.toJS);
    final child2 = npmComponent('react-native', 'Text', child: 'Two'.toJS);

    final parent = npmComponent(
      'react-native',
      'View',
      children: [child1, child2],
    );
    expect(parent, isNotNull);
  });

  test('npmComponentSafe returns Success for valid component', () {
    final result = npmComponentSafe(
      'react-native',
      'View',
      props: {'testID': 'test-view'},
    );
    expect(result.isSuccess, isTrue);
  });

  test('npmComponentSafe returns Error for invalid package', () {
    final result = npmComponentSafe(
      'nonexistent-package-xyz',
      'Component',
    );
    expect(result.isSuccess, isFalse);
  });

  test('npmFactory gets createElement from react', () {
    final result = npmFactory<JSFunction>('react', 'createElement');
    expect(result.isSuccess, isTrue);
  });

  test('clearNpmModuleCache clears all cached modules', () {
    loadNpmModule('react');
    expect(isModuleCached('react'), isTrue);

    clearNpmModuleCache();
    expect(isModuleCached('react'), isFalse);
  });

  test('npmComponent works with nested props', () {
    final element = npmComponent(
      'react-native',
      'View',
      props: {
        'style': {
          'flex': 1,
          'backgroundColor': '#FFFFFF',
          'padding': 16,
          'margin': {'top': 10, 'bottom': 10},
        },
        'testID': 'nested-props-view',
      },
    );
    expect(element, isNotNull);
  });

  test('npmComponent works with callback props', () {
    final element = npmComponent(
      'react-native',
      'TouchableOpacity',
      props: {'onPress': () {}},
      children: [npmComponent('react-native', 'Text', child: 'Press'.toJS)],
    );
    expect(element, isNotNull);
  });

  test('NpmComponentElement implements ReactElement', () {
    final element = npmComponent('react-native', 'View');
    // NpmComponentElement should be usable as ReactElement
    expect(element, isA<ReactElement>());
  });
}
