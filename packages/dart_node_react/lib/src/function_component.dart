/// Function component registration for React.
///
/// Provides typed wrappers for creating React function components with Dart.
library;

import 'dart:js_interop';

import 'package:dart_node_react/src/react.dart';

/// A Dart function component that takes a props Map and returns a ReactElement.
typedef DartFunctionComponent = ReactElement Function(
  Map<String, Object?> props,
);

/// Creates a React function component from a Dart function.
///
/// This wraps a Dart function that takes a `Map<String, Object?>` of props
/// and returns a `ReactElement`. The wrapper handles converting between
/// JS and Dart types automatically.
///
/// Example:
/// ```dart
/// final Counter = registerFunctionComponent((props) {
///   final count = useState(props['initialCount'] as int? ?? 0);
///
///   return div(children: [
///     pEl('Count: ${count.value}'),
///     button(
///       text: 'Increment',
///       onClick: () => count.setWithUpdater((prev) => prev + 1),
///     ),
///   ]);
/// });
///
/// // Use in render:
/// createElement(Counter, createProps({'initialCount': 5}));
/// ```
///
/// You can optionally provide a [displayName] for better debugging in React
/// DevTools.
JSAny registerFunctionComponent(
  DartFunctionComponent dartComponent, {
  String? displayName,
}) {
  ReactElement jsComponent(JSObject jsProps) {
    final dartified = jsProps.dartify();
    final props = (dartified is Map<Object?, Object?>)
        ? dartified.cast<String, Object?>()
        : <String, Object?>{};
    return dartComponent(props);
  }

  final component = jsComponent.toJS;
  return component;
}

/// Creates a ReactElement from a registered function component.
///
/// This is a convenience function that combines creating props and the element.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   return pEl('Hello ${props['name']}!');
/// });
///
/// // Usage:
/// fc(MyComponent, {'name': 'World'});
/// ```
ReactElement fc(
  JSAny component, [
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) =>
    (children != null && children.isNotEmpty)
        ? createElementWithChildren(
            component,
            props != null ? createProps(props) : null,
            children,
          )
        : createElement(
            component,
            props != null ? createProps(props) : null,
          );
