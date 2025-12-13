/// React Native package tests - factory tests and type tests.
/// Actual React Native runtime requires Expo/RN environment.
library;

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('component element types', () {
    test('RNViewElement type exists', () {
      RNViewElement? element;
      expect(element, isNull);
    });

    test('RNTextElement type exists', () {
      RNTextElement? element;
      expect(element, isNull);
    });

    test('RNTextInputElement type exists', () {
      RNTextInputElement? element;
      expect(element, isNull);
    });

    test('RNTouchableOpacityElement type exists', () {
      RNTouchableOpacityElement? element;
      expect(element, isNull);
    });

    test('RNButtonElement type exists', () {
      RNButtonElement? element;
      expect(element, isNull);
    });

    test('RNScrollViewElement type exists', () {
      RNScrollViewElement? element;
      expect(element, isNull);
    });

    test('RNSafeAreaViewElement type exists', () {
      RNSafeAreaViewElement? element;
      expect(element, isNull);
    });

    test('RNActivityIndicatorElement type exists', () {
      RNActivityIndicatorElement? element;
      expect(element, isNull);
    });

    test('RNFlatListElement type exists', () {
      RNFlatListElement? element;
      expect(element, isNull);
    });

    test('RNImageElement type exists', () {
      RNImageElement? element;
      expect(element, isNull);
    });

    test('RNSwitchElement type exists', () {
      RNSwitchElement? element;
      expect(element, isNull);
    });
  });

  group('component builder functions', () {
    test('view function exists', () {
      expect(view, isA<Function>());
    });

    test('text function exists', () {
      expect(text, isA<Function>());
    });

    test('textInput function exists', () {
      expect(textInput, isA<Function>());
    });

    test('touchableOpacity function exists', () {
      expect(touchableOpacity, isA<Function>());
    });

    test('rnButton function exists', () {
      expect(rnButton, isA<Function>());
    });

    test('scrollView function exists', () {
      expect(scrollView, isA<Function>());
    });

    test('safeAreaView function exists', () {
      expect(safeAreaView, isA<Function>());
    });

    test('activityIndicator function exists', () {
      expect(activityIndicator, isA<Function>());
    });

    test('flatList function exists', () {
      expect(flatList, isA<Function>());
    });

    test('rnImage function exists', () {
      expect(rnImage, isA<Function>());
    });

    test('rnSwitch function exists', () {
      expect(rnSwitch, isA<Function>());
    });
  });

  group('core functions', () {
    test('rnElement function exists', () {
      expect(rnElement, isA<Function>());
    });

    test('createFunctionalComponent function exists', () {
      expect(createFunctionalComponent, isA<Function>());
    });

    test('functionalComponent function exists', () {
      expect(functionalComponent, isA<Function>());
    });

    test('registerApp function exists', () {
      expect(registerApp, isA<Function>());
    });
  });

  group('testing library', () {
    test('TestNode type exists', () {
      TestNode? node;
      expect(node, isNull);
    });

    test('TestRenderResult type exists', () {
      TestRenderResult? result;
      expect(result, isNull);
    });

    test('TestingException type exists', () {
      expect(
        () => throw TestingException('test'),
        throwsA(isA<TestingException>()),
      );
    });

    test('setupTestEnvironment function exists', () {
      expect(setupTestEnvironment, isA<Function>());
    });

    test('renderForTest function exists', () {
      expect(renderForTest, isA<Function>());
    });

    test('userType function exists', () {
      expect(userType, isA<Function>());
    });

    test('userPress function exists', () {
      expect(userPress, isA<Function>());
    });

    test('userClear function exists', () {
      expect(userClear, isA<Function>());
    });
  });

  group('core types', () {
    test('ReactNative type exists', () {
      ReactNative? rn;
      expect(rn, isNull);
    });

    test('AppRegistry type exists', () {
      AppRegistry? reg;
      expect(reg, isNull);
    });
  });
}
