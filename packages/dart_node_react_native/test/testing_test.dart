/// Tests for the React Native Testing Library.
///
/// These tests cover the TestNode and TestRenderResult classes
/// which contain pure Dart logic that can be tested without a JS runtime.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_react/dart_node_react.dart' hide userClear, userType;
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:test/test.dart';

/// Create a mock React element for testing
ReactElement _mockElement(String type, {Map<String, JSAny?>? props}) {
  final jsProps = JSObject();
  if (props != null) {
    for (final entry in props.entries) {
      final value = entry.value;
      if (value != null) {
        jsProps.setProperty(entry.key.toJS, value);
      }
    }
  }

  final mockElement = JSObject()
    ..setProperty('type'.toJS, type.toJS)
    ..setProperty('props'.toJS, jsProps);
  return ReactElement.fromJS(mockElement);
}

void main() {
  setUpAll(setupTestEnvironment);
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('TestingException', () {
    test('stores message', () {
      final exception = TestingException('test message');
      expect(exception.message, equals('test message'));
    });

    test('toString includes message', () {
      final exception = TestingException('error occurred');
      expect(exception.toString(), contains('error occurred'));
      expect(exception.toString(), contains('TestingException'));
    });
  });

  group('TestNode', () {
    test('textContent returns empty for node without text', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.textContent, isEmpty);
    });

    test('findByType returns matching nodes', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.findByType('View'), hasLength(1));
    });

    test('findByType returns empty list when no matches', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.findByType('NonExistent'), isEmpty);
    });

    test('findByText returns empty list when no matches', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.findByText('not found'), isEmpty);
    });

    test('findByTestId returns empty list when no matches', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.findByTestId('missing-id'), isEmpty);
    });

    test('findByTestId finds matching node', () {
      final result = renderForTest(
        _mockElement('View', props: {'testID': 'my-id'.toJS}),
      );
      expect(result.findByTestId('my-id'), hasLength(1));
    });

    test('findByProp returns empty list when no matches', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.findByProp('nonexistent', 'value'), isEmpty);
    });

    test('findByProp finds matching node', () {
      final result = renderForTest(
        _mockElement('View', props: {'customProp': 'myValue'.toJS}),
      );
      expect(result.findByProp('customProp', 'myValue'), hasLength(1));
    });

    test('getByType throws when not found', () {
      final result = renderForTest(_mockElement('View'));
      expect(
        () => result.getByType('Missing'),
        throwsA(isA<TestingException>()),
      );
    });

    test('getByType returns node when found', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.getByType('View').type, equals('View'));
    });

    test('getByText throws when not found', () {
      final result = renderForTest(_mockElement('View'));
      expect(
        () => result.getByText('missing text'),
        throwsA(isA<TestingException>()),
      );
    });

    test('getByTestId throws when not found', () {
      final result = renderForTest(_mockElement('View'));
      expect(
        () => result.getByTestId('missing-id'),
        throwsA(isA<TestingException>()),
      );
    });

    test('getByTestId returns node when found', () {
      final result = renderForTest(
        _mockElement('View', props: {'testID': 'test-id'.toJS}),
      );
      expect(result.getByTestId('test-id').type, equals('View'));
    });

    test('queryByType returns null when not found', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.queryByType('Missing'), isNull);
    });

    test('queryByType returns node when found', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.queryByType('View'), isNotNull);
    });

    test('queryByText returns null when not found', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.queryByText('missing'), isNull);
    });

    test('queryByTestId returns null when not found', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.queryByTestId('missing'), isNull);
    });

    test('queryByTestId returns node when found', () {
      final result = renderForTest(
        _mockElement('View', props: {'testID': 'found-id'.toJS}),
      );
      expect(result.queryByTestId('found-id'), isNotNull);
    });

    test('firePress throws when no onPress handler', () {
      final result = renderForTest(_mockElement('View'));
      expect(() => result.root.firePress(), throwsA(isA<TestingException>()));
    });

    test('firePress calls JSFunction handler', () {
      var pressed = false;
      final handler = (() => pressed = true).toJS;
      final result = renderForTest(
        _mockElement('TouchableOpacity', props: {'onPress': handler}),
      );
      result.root.firePress();
      expect(pressed, isTrue);
    });

    test('fireChangeText throws when no onChangeText handler', () {
      final result = renderForTest(_mockElement('TextInput'));
      expect(
        () => result.root.fireChangeText('text'),
        throwsA(isA<TestingException>()),
      );
    });

    test('fireChangeText calls JSFunction handler', () {
      String? receivedText;
      final handler = ((JSString text) {
        receivedText = text.toDart;
      }).toJS;
      final result = renderForTest(
        _mockElement('TextInput', props: {'onChangeText': handler}),
      );
      result.root.fireChangeText('hello');
      expect(receivedText, equals('hello'));
    });

    test('fireValueChange throws when no onValueChange handler', () {
      final result = renderForTest(_mockElement('Switch'));
      expect(
        () => result.root.fireValueChange(true),
        throwsA(isA<TestingException>()),
      );
    });

    test('fireValueChange calls JSFunction handler', () {
      bool? receivedValue;
      final handler = ((JSBoolean value) {
        receivedValue = value.toDart;
      }).toJS;
      final result = renderForTest(
        _mockElement('Switch', props: {'onValueChange': handler}),
      );
      result.root.fireValueChange(true);
      expect(receivedValue, isTrue);
    });

    test('value returns null when not set', () {
      final result = renderForTest(_mockElement('TextInput'));
      expect(result.root.value, isNull);
    });

    test('value returns string when set', () {
      final result = renderForTest(
        _mockElement('TextInput', props: {'value': 'test value'.toJS}),
      );
      expect(result.root.value, equals('test value'));
    });

    test('placeholder returns null when not set', () {
      final result = renderForTest(_mockElement('TextInput'));
      expect(result.root.placeholder, isNull);
    });

    test('placeholder returns string when set', () {
      final result = renderForTest(
        _mockElement('TextInput', props: {'placeholder': 'Enter text'.toJS}),
      );
      expect(result.root.placeholder, equals('Enter text'));
    });

    test('toString includes type and children count', () {
      final result = renderForTest(_mockElement('View'));
      final str = result.root.toString();
      expect(str, contains('TestNode'));
      expect(str, contains('View'));
    });
  });

  group('user interaction helpers', () {
    test('userPress calls firePress', () {
      var pressed = false;
      final handler = (() => pressed = true).toJS;
      final result = renderForTest(
        _mockElement('TouchableOpacity', props: {'onPress': handler}),
      );
      userPress(result.root);
      expect(pressed, isTrue);
    });

    test('userClear fires empty string', () {
      String? lastValue;
      final handler = ((JSString text) {
        lastValue = text.toDart;
      }).toJS;
      final result = renderForTest(
        _mockElement('TextInput', props: {'onChangeText': handler}),
      );
      userClear(result.root);
      expect(lastValue, equals(''));
    });

    test('userType throws for non-TextInput', () async {
      final result = renderForTest(_mockElement('View'));
      await expectLater(
        userType(result.root, 'hello'),
        throwsA(isA<TestingException>()),
      );
    });

    test('userType types text character by character', () async {
      final values = <String>[];
      final handler = ((JSString text) {
        values.add(text.toDart);
      }).toJS;
      final result = renderForTest(
        _mockElement('TextInput', props: {'onChangeText': handler}),
      );
      await userType(result.root, 'abc');
      expect(values, equals(['a', 'ab', 'abc']));
    });
  });

  group('TestRenderResult', () {
    test('root returns the root node', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.root, isNotNull);
      expect(result.root.type, equals('View'));
    });

    test('textContent delegates to root', () {
      final result = renderForTest(_mockElement('View'));
      expect(result.textContent, equals(result.root.textContent));
    });

    test('debug does not throw', () {
      final result = renderForTest(_mockElement('View'))..debug();
      expect(result, isNotNull);
    });

    test('waitForText times out when text not found', () async {
      final result = renderForTest(_mockElement('View'));
      await expectLater(
        result.waitForText(
          'missing',
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<TestingException>()),
      );
    });
  });

  group('setupTestEnvironment', () {
    test('can be called multiple times', () {
      // Should not throw
      setupTestEnvironment();
      setupTestEnvironment();
    });
  });
}
