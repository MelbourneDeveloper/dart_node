/// Tests for navigation_types.dart to improve code coverage.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('NavigationProp via extractScreenProps', () {
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
      String? navigatedTo;
      JSAny? receivedParams;

      final mockNav = JSObject();
      mockNav['navigate'] = ((JSString route, [JSAny? params]) {
        navigateCalled = true;
        navigatedTo = route.toDart;
        receivedParams = params;
      }).toJS;

      final props = _createScreenProps(mockNav, JSObject());
      props?.navigation.navigate('Details', {'id': 123});

      expect(navigateCalled, isTrue);
      expect(navigatedTo, equals('Details'));
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

  group('RouteProp via extractScreenProps', () {
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

/// Helper to create ScreenProps from mock objects
ScreenProps? _createScreenProps(JSObject mockNav, JSObject mockRoute) {
  final mockProps = JSObject();
  mockProps['navigation'] = mockNav;
  mockProps['route'] = mockRoute;
  return extractScreenProps(mockProps);
}
