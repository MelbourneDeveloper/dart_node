/// Navigation types for React Navigation interop.
///
/// These are basic extension types for working with React Navigation
/// props passed to screen components. Use with npmComponent() for
/// direct navigation package usage.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Navigation prop type (passed to screen components)
extension type NavigationProp._(JSObject _) implements JSObject {
  /// Navigate to a route
  void navigate(String routeName, [Map<String, dynamic>? params]) {
    if (params != null) {
      _.callMethod('navigate'.toJS, routeName.toJS, params.jsify());
    } else {
      _.callMethod('navigate'.toJS, routeName.toJS);
    }
  }

  /// Go back to the previous screen
  void goBack() => _.callMethod('goBack'.toJS);

  /// Push a new screen onto the stack
  void push(String routeName, [Map<String, dynamic>? params]) {
    if (params != null) {
      _.callMethod('push'.toJS, routeName.toJS, params.jsify());
    } else {
      _.callMethod('push'.toJS, routeName.toJS);
    }
  }

  /// Pop the current screen from the stack
  void pop([int? count]) {
    if (count != null) {
      _.callMethod('pop'.toJS, count.toJS);
    } else {
      _.callMethod('pop'.toJS);
    }
  }

  /// Pop to the top of the stack
  void popToTop() => _.callMethod('popToTop'.toJS);

  /// Replace the current screen
  void replace(String routeName, [Map<String, dynamic>? params]) {
    if (params != null) {
      _.callMethod('replace'.toJS, routeName.toJS, params.jsify());
    } else {
      _.callMethod('replace'.toJS, routeName.toJS);
    }
  }

  /// Check if can go back
  bool canGoBack() {
    final result = _.callMethod<JSBoolean?>('canGoBack'.toJS);
    return result?.toDart ?? false;
  }

  /// Set navigation options
  void setOptions(Map<String, dynamic> options) =>
      _.callMethod('setOptions'.toJS, options.jsify());
}

/// Route prop type (passed to screen components)
extension type RouteProp._(JSObject _) implements JSObject {
  /// Route key
  String get key => switch (_['key']) {
    final JSString s => s.toDart,
    _ => '',
  };

  /// Route name
  String get name => switch (_['name']) {
    final JSString s => s.toDart,
    _ => '',
  };

  /// Route params as JSObject
  JSObject? get params => switch (_['params']) {
    final JSObject o => o,
    _ => null,
  };

  /// Get a typed parameter
  T? getParam<T>(String paramKey) {
    final p = params;
    if (p == null) return null;
    final value = p[paramKey];
    if (value == null) return null;
    return value.dartify() as T?;
  }
}

/// Screen component props (navigation + route)
typedef ScreenProps = ({NavigationProp navigation, RouteProp route});

/// Extract ScreenProps from JSObject props passed to screen components.
///
/// Returns null if props don't contain valid navigation/route objects.
ScreenProps? extractScreenProps(JSObject props) {
  final nav = props['navigation'];
  final route = props['route'];
  return switch ((nav, route)) {
    (final JSObject n, final JSObject r) => (
      navigation: NavigationProp._(n),
      route: RouteProp._(r),
    ),
    _ => null,
  };
}
