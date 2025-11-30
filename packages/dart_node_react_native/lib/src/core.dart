@JS()
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_react/dart_node_react.dart';

// Re-export React core and hooks from dart_node_react
export 'package:dart_node_react/src/hooks.dart';
export 'package:dart_node_react/src/react.dart'
    show createElement, createElementWithChildren, createProps;

/// React Native core - accessed via require('react-native')
@JS()
extension type ReactNative._(JSObject _) implements JSObject {}

ReactNative get reactNative => ReactNative._(_resolveReactNative());

JSObject _resolveReactNative() {
  final globalModule = getGlobal('reactNative');
  if (globalModule case final JSObject module) {
    return module;
  }

  final required = requireModule('react-native');
  return switch (required) {
    final JSObject module => module,
    _ => throw StateError('react-native module not found'),
  };
}

/// AppRegistry for registering the root component
extension type AppRegistry._(JSObject _) implements JSObject {
  external static void registerComponent(
    JSString appName,
    JSFunction componentProvider,
  );
}

/// Get AppRegistry from react-native
AppRegistry get appRegistry {
  final reg = reactNative['AppRegistry'];
  return switch (reg) {
    final JSObject r => AppRegistry._(r),
    _ => throw StateError('AppRegistry not found'),
  };
}

/// Register the main app component
void registerApp(String appName, JSFunction component) {
  final provider = (() => component).toJS;
  appRegistry.callMethod('registerComponent'.toJS, appName.toJS, provider);
}

/// Create a React Native element
/// Note: child accepts JSAny? to support both ReactElement and text strings
ReactElement rnElement(
  String componentName, {
  Map<String, dynamic>? props,
  List<ReactElement>? children,
  JSAny? child,
}) {
  final component = reactNative[componentName];
  final jsProps = (props != null) ? createProps(props) : null;

  return switch (component) {
    final JSAny c => (children != null && children.isNotEmpty)
        ? createElementWithChildren(c, jsProps, children)
        : (child != null)
            ? createElement(c, jsProps, child)
            : createElement(c, jsProps),
    _ => throw StateError('Component $componentName not found'),
  };
}

/// Create a functional component - returns the component function itself
JSFunction createFunctionalComponent(
  ReactElement Function(JSObject props) render,
) =>
    ((JSAny props) => render(props as JSObject)).toJS;

/// Create a React element with an inline functional component
ReactElement functionalComponent(
  String name,
  ReactElement Function(JSObject props) render,
) =>
    createElement(createFunctionalComponent(render));
