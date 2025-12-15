/// Consolidated test file for dart_node_react_native package.
///
/// This single file imports and runs all tests to ensure coverage is properly
/// aggregated. Each test file's coverage is written to the same coverage.json
/// because they all run in a single test process.
@TestOn('node')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_react/dart_node_react.dart'
    hide userClear, userType, view;
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

// =============================================================================
// MAIN - Single entry point for all tests
// =============================================================================
void main() {
  setUpAll(() {
    initCoverage();
    setupTestEnvironment();
  });
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  // Component type tests
  _componentElementTypeTests();

  // Component builder function tests
  _componentBuilderTests();

  // Core function tests
  _coreFunctionTests();

  // Testing library tests
  _testingLibraryTests();

  // Npm component tests
  _npmComponentTests();

  // Navigation types tests
  _navigationTypesTests();

  // User interaction tests
  _userInteractionTests();

  // Paper component tests
  _paperComponentTests();
}

// =============================================================================
// COMPONENT ELEMENT TYPES
// =============================================================================
void _componentElementTypeTests() {
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

    test('NpmComponentElement type exists', () {
      NpmComponentElement? element;
      expect(element, isNull);
    });
  });
}

// =============================================================================
// COMPONENT BUILDER FUNCTIONS
// =============================================================================
void _componentBuilderTests() {
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
}

// =============================================================================
// CORE FUNCTIONS
// =============================================================================
void _coreFunctionTests() {
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
}

// =============================================================================
// TESTING LIBRARY - TestNode, TestRenderResult, TestingException
// =============================================================================
void _testingLibraryTests() {
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
      setupTestEnvironment();
      setupTestEnvironment();
    });
  });
}

// =============================================================================
// NPM COMPONENT TESTS
// =============================================================================
void _npmComponentTests() {
  group('npm component loading', () {
    test('loadNpmModule loads react successfully', () {
      final result = loadNpmModule('react');
      expect(result.isSuccess, isTrue);
    });

    test('loadNpmModule caches modules', () {
      clearNpmModuleCache();
      expect(isModuleCached('react'), isFalse);

      loadNpmModule('react');
      expect(isModuleCached('react'), isTrue);

      final result2 = loadNpmModule('react');
      expect(result2.isSuccess, isTrue);
    });

    test('loadNpmModule returns error for nonexistent package', () {
      final result = loadNpmModule('nonexistent-package-xyz-123');
      expect(result.isSuccess, isFalse);
    });

    test('getComponentFromModule gets createElement from react', () {
      final moduleResult = loadNpmModule('react');
      expect(moduleResult.isSuccess, isTrue);

      final module = (moduleResult as Success<JSObject, String>).value;
      final result = getComponentFromModule(module, 'createElement');
      expect(result.isSuccess, isTrue);
    });

    test('getComponentFromModule returns error for nonexistent component', () {
      final moduleResult = loadNpmModule('react');
      expect(moduleResult.isSuccess, isTrue);

      final module = (moduleResult as Success<JSObject, String>).value;
      final result = getComponentFromModule(module, 'NonExistentComponent');
      expect(result.isSuccess, isFalse);
    });

    test('npmComponentSafe returns Error for invalid package', () {
      final result = npmComponentSafe('nonexistent-package-xyz', 'Component');
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
  });
}

// =============================================================================
// NAVIGATION TYPES TESTS
// =============================================================================
void _navigationTypesTests() {
  group('NavigationProp', () {
    test('navigate calls navigate method without params', () {
      var navigateCalled = false;
      String? navigatedTo;

      final mockNav = JSObject();
      mockNav['navigate'] = ((JSString route, [JSAny? params]) {
        navigateCalled = true;
        navigatedTo = route.toDart;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.navigate('Home');

      expect(navigateCalled, isTrue);
      expect(navigatedTo, equals('Home'));
    });

    test('navigate calls navigate method with params', () {
      var navigateCalled = false;
      JSAny? receivedParams;

      final mockNav = JSObject();
      mockNav['navigate'] = ((JSString route, [JSAny? params]) {
        navigateCalled = true;
        receivedParams = params;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.navigate('Details', {'id': 123});

      expect(navigateCalled, isTrue);
      expect(receivedParams, isNotNull);
    });

    test('goBack calls goBack method', () {
      var goBackCalled = false;

      final mockNav = JSObject();
      mockNav['goBack'] = (() {
        goBackCalled = true;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.goBack();

      expect(goBackCalled, isTrue);
    });

    test('push calls push method without params', () {
      var pushCalled = false;
      String? pushedTo;

      final mockNav = JSObject();
      mockNav['push'] = ((JSString route, [JSAny? params]) {
        pushCalled = true;
        pushedTo = route.toDart;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.push('NewScreen');

      expect(pushCalled, isTrue);
      expect(pushedTo, equals('NewScreen'));
    });

    test('push calls push method with params', () {
      var pushCalled = false;
      JSAny? receivedParams;

      final mockNav = JSObject();
      mockNav['push'] = ((JSString route, [JSAny? params]) {
        pushCalled = true;
        receivedParams = params;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.push('NewScreen', {'data': 'value'});

      expect(pushCalled, isTrue);
      expect(receivedParams, isNotNull);
    });

    test('pop calls pop method without count', () {
      var popCalled = false;

      final mockNav = JSObject();
      mockNav['pop'] = (([JSAny? count]) {
        popCalled = true;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.pop();

      expect(popCalled, isTrue);
    });

    test('pop calls pop method with count', () {
      var popCalled = false;
      int? popCount;

      final mockNav = JSObject();
      mockNav['pop'] = (([JSNumber? count]) {
        popCalled = true;
        popCount = count?.toDartInt;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.pop(2);

      expect(popCalled, isTrue);
      expect(popCount, equals(2));
    });

    test('popToTop calls popToTop method', () {
      var popToTopCalled = false;

      final mockNav = JSObject();
      mockNav['popToTop'] = (() {
        popToTopCalled = true;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.popToTop();

      expect(popToTopCalled, isTrue);
    });

    test('replace calls replace method without params', () {
      var replaceCalled = false;
      String? replacedWith;

      final mockNav = JSObject();
      mockNav['replace'] = ((JSString route, [JSAny? params]) {
        replaceCalled = true;
        replacedWith = route.toDart;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.replace('NewRoute');

      expect(replaceCalled, isTrue);
      expect(replacedWith, equals('NewRoute'));
    });

    test('replace calls replace method with params', () {
      var replaceCalled = false;
      JSAny? receivedParams;

      final mockNav = JSObject();
      mockNav['replace'] = ((JSString route, [JSAny? params]) {
        replaceCalled = true;
        receivedParams = params;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.replace('NewRoute', {'key': 'value'});

      expect(replaceCalled, isTrue);
      expect(receivedParams, isNotNull);
    });

    test('canGoBack returns true when can go back', () {
      final mockNav = JSObject();
      mockNav['canGoBack'] = (() => true.toJS).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      expect(props?.navigation.canGoBack(), isTrue);
    });

    test('canGoBack returns false when cannot go back', () {
      final mockNav = JSObject();
      mockNav['canGoBack'] = (() => false.toJS).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      expect(props?.navigation.canGoBack(), isFalse);
    });

    test('canGoBack returns false when result is null', () {
      final mockNav = JSObject();
      mockNav['canGoBack'] = (() => null).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      expect(props?.navigation.canGoBack(), isFalse);
    });

    test('setOptions calls setOptions method', () {
      var setOptionsCalled = false;
      JSAny? receivedOptions;

      final mockNav = JSObject();
      mockNav['setOptions'] = ((JSAny options) {
        setOptionsCalled = true;
        receivedOptions = options;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.setOptions({'title': 'New Title'});

      expect(setOptionsCalled, isTrue);
      expect(receivedOptions, isNotNull);
    });
  });

  group('RouteProp', () {
    test('key returns route key', () {
      final mockRoute = JSObject();
      mockRoute['key'] = 'route-123'.toJS;

      final props = _createScreenProps(JSObject(), mockRoute);
      expect(props?.route.key, equals('route-123'));
    });

    test('key returns empty string when not a JSString', () {
      final mockRoute = JSObject();
      mockRoute['key'] = 123.toJS;

      final props = _createScreenProps(JSObject(), mockRoute);
      expect(props?.route.key, equals(''));
    });

    test('name returns route name', () {
      final mockRoute = JSObject();
      mockRoute['name'] = 'HomeScreen'.toJS;

      final props = _createScreenProps(JSObject(), mockRoute);
      expect(props?.route.name, equals('HomeScreen'));
    });

    test('name returns empty string when not a JSString', () {
      final mockRoute = JSObject();
      mockRoute['name'] = true.toJS;

      final props = _createScreenProps(JSObject(), mockRoute);
      expect(props?.route.name, equals(''));
    });

    test('params returns JSObject when present', () {
      final mockRoute = JSObject();
      final paramsObj = JSObject();
      paramsObj['id'] = '456'.toJS;
      mockRoute['params'] = paramsObj;

      final props = _createScreenProps(JSObject(), mockRoute);
      expect(props?.route.params, isNotNull);
    });

    test('params returns null when not a JSObject', () {
      final mockRoute = JSObject();
      mockRoute['params'] = 'not an object'.toJS;

      final props = _createScreenProps(JSObject(), mockRoute);
      expect(props?.route.params, isNull);
    });

    test('params returns null when not present', () {
      final mockRoute = JSObject();

      final props = _createScreenProps(JSObject(), mockRoute);
      expect(props?.route.params, isNull);
    });

    test('getParam returns typed parameter value', () {
      final mockRoute = JSObject();
      final paramsObj = JSObject();
      paramsObj['userId'] = 'user-123'.toJS;
      mockRoute['params'] = paramsObj;

      final props = _createScreenProps(JSObject(), mockRoute);
      final userId = props?.route.getParam<String>('userId');
      expect(userId, equals('user-123'));
    });

    test('getParam returns null when params is null', () {
      final mockRoute = JSObject();

      final props = _createScreenProps(JSObject(), mockRoute);
      expect(props?.route.getParam<String>('anything'), isNull);
    });

    test('getParam returns null when param key not found', () {
      final mockRoute = JSObject();
      final paramsObj = JSObject();
      paramsObj['existingKey'] = 'value'.toJS;
      mockRoute['params'] = paramsObj;

      final props = _createScreenProps(JSObject(), mockRoute);
      expect(props?.route.getParam<String>('nonExistentKey'), isNull);
    });
  });

  group('extractScreenProps', () {
    test('returns ScreenProps when navigation and route are present', () {
      final mockProps = JSObject();
      final mockNav = JSObject();
      final mockRoute = JSObject();
      mockRoute['name'] = 'TestScreen'.toJS;
      mockProps['navigation'] = mockNav;
      mockProps['route'] = mockRoute;

      final result = extractScreenProps(mockProps);
      expect(result, isNotNull);
      expect(result?.route.name, equals('TestScreen'));
    });

    test('returns null when navigation is missing', () {
      final mockProps = JSObject();
      final mockRoute = JSObject();
      mockProps['route'] = mockRoute;

      final result = extractScreenProps(mockProps);
      expect(result, isNull);
    });

    test('returns null when route is missing', () {
      final mockProps = JSObject();
      final mockNav = JSObject();
      mockProps['navigation'] = mockNav;

      final result = extractScreenProps(mockProps);
      expect(result, isNull);
    });

    test('returns null when navigation is not JSObject', () {
      final mockProps = JSObject();
      mockProps['navigation'] = 'not an object'.toJS;
      mockProps['route'] = JSObject();

      final result = extractScreenProps(mockProps);
      expect(result, isNull);
    });

    test('returns null when route is not JSObject', () {
      final mockProps = JSObject();
      mockProps['navigation'] = JSObject();
      mockProps['route'] = 'not an object'.toJS;

      final result = extractScreenProps(mockProps);
      expect(result, isNull);
    });
  });
}

// =============================================================================
// USER INTERACTION TESTS
// =============================================================================
void _userInteractionTests() {
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
}

// =============================================================================
// PAPER COMPONENT TESTS
// =============================================================================
void _paperComponentTests() {
  group('Paper typed extension types', () {
    test('PaperButton implements ReactElement', () {
      const PaperButton? element = null;
      const ReactElement? asReact = element;
      expect(asReact, isNull);
    });

    test('PaperFAB implements ReactElement', () {
      const PaperFAB? element = null;
      const ReactElement? asReact = element;
      expect(asReact, isNull);
    });

    test('PaperCard implements ReactElement', () {
      const PaperCard? element = null;
      const ReactElement? asReact = element;
      expect(asReact, isNull);
    });

    test('PaperTextInput implements ReactElement', () {
      const PaperTextInput? element = null;
      const ReactElement? asReact = element;
      expect(asReact, isNull);
    });

    test('paperButton factory function exists', () {
      expect(paperButton, isA<Function>());
    });

    test('paperFAB factory function exists', () {
      expect(paperFAB, isA<Function>());
    });

    test('paperCard factory function exists', () {
      expect(paperCard, isA<Function>());
    });

    test('paperTextInput factory function exists', () {
      expect(paperTextInput, isA<Function>());
    });
  });

  group('Paper props typedef records', () {
    test('PaperButtonProps has all fields', () {
      const PaperButtonProps props = (
        mode: 'contained',
        disabled: false,
        loading: true,
        buttonColor: '#6200EE',
        textColor: '#FFFFFF',
        style: null,
        contentStyle: null,
        labelStyle: null,
      );
      expect(props.mode, equals('contained'));
      expect(props.disabled, isFalse);
      expect(props.loading, isTrue);
      expect(props.buttonColor, equals('#6200EE'));
    });

    test('PaperFABProps has all fields', () {
      const PaperFABProps props = (
        icon: 'plus',
        label: 'Add',
        small: true,
        visible: true,
        loading: false,
        disabled: false,
        color: '#6200EE',
        customColor: null,
        style: null,
      );
      expect(props.icon, equals('plus'));
      expect(props.label, equals('Add'));
      expect(props.small, isTrue);
    });

    test('PaperCardProps has all fields', () {
      const PaperCardProps props = (
        mode: 'elevated',
        style: null,
        contentStyle: null,
      );
      expect(props.mode, equals('elevated'));
    });

    test('PaperTextInputProps has all fields', () {
      const PaperTextInputProps props = (
        label: 'Email',
        placeholder: 'Enter email',
        mode: 'outlined',
        disabled: false,
        editable: true,
        secureTextEntry: false,
        value: 'test@test.com',
        activeOutlineColor: '#6200EE',
        activeUnderlineColor: null,
        textColor: '#000000',
        style: null,
      );
      expect(props.label, equals('Email'));
      expect(props.placeholder, equals('Enter email'));
      expect(props.mode, equals('outlined'));
      expect(props.value, equals('test@test.com'));
    });
  });
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

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

/// Helper to create ScreenProps from mock objects
ScreenProps? _createScreenProps(JSObject mockNav, JSObject mockRoute) {
  final mockProps = JSObject();
  mockProps['navigation'] = mockNav;
  mockProps['route'] = mockRoute;
  return extractScreenProps(mockProps);
}
