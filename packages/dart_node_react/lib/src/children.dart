/// React.Children utilities for manipulating children props.
///
/// Provides type-safe wrappers around React.Children API methods.
library;

import 'dart:js_interop';

import 'package:dart_node_react/src/react.dart';

// =============================================================================
// React.Children JS Bindings
// =============================================================================

@JS('React.Children.map')
external JSArray? _childrenMap(JSAny? children, JSFunction fn);

@JS('React.Children.forEach')
external void _childrenForEach(JSAny? children, JSFunction fn);

@JS('React.Children.count')
external int _childrenCount(JSAny? children);

@JS('React.Children.only')
external JSObject _childrenOnly(JSAny? children);

@JS('React.Children.toArray')
external JSArray _childrenToArray(JSAny? children);

// =============================================================================
// Children Utilities
// =============================================================================

/// Utilities for dealing with the children prop.
///
/// React.Children provides utilities for dealing with the opaque data structure
/// of props.children.
///
/// Example:
/// ```dart
/// final MyComponent = registerFunctionComponent((props) {
///   final children = props['children'];
///   final count = Children.count(children);
///   return div(children: [
///     pEl('This component has $count children'),
///     ...Children.toArray(children),
///   ]);
/// });
/// ```
///
/// See: https://react.dev/reference/react/Children

// This class mirrors React's Children API which is a namespace with static
// methods, so the lint is intentionally ignored.
// ignore_for_file: avoid_classes_with_only_static_members
abstract final class Children {
  /// Calls a function for each child in children.
  ///
  /// If children is null or undefined, returns null. Otherwise, returns a new
  /// array with the results of calling fn on each child.
  ///
  /// Example:
  /// ```dart
  /// final items = Children.map(props['children'], (child, index) {
  ///   return cloneElement(child, {'key': 'item-$index'});
  /// });
  /// ```
  ///
  /// See: https://react.dev/reference/react/Children#children-map
  static List<ReactElement>? map(
    JSAny? children,
    ReactElement Function(ReactElement child, int index) fn,
  ) {
    ReactElement jsMapper(JSObject child, JSNumber index) =>
        fn(ReactElement.fromJS(child), index.toDartInt);

    final result = _childrenMap(children, jsMapper.toJS);
    return result?.toDart
        .map((e) => switch (e) {
          final JSObject o => ReactElement.fromJS(o),
          _ => throw StateError('Invalid child element'),
        })
        .toList();
  }

  /// Iterates over children, calling fn for each child.
  ///
  /// Unlike map, forEach does not return anything.
  ///
  /// Example:
  /// ```dart
  /// Children.forEach(props['children'], (child, index) {
  ///   print('Child $index: ${child.type}');
  /// });
  /// ```
  ///
  /// See: https://react.dev/reference/react/Children#children-foreach
  static void forEach(
    JSAny? children,
    void Function(ReactElement child, int index) fn,
  ) {
    void jsIterator(JSObject child, JSNumber index) =>
        fn(ReactElement.fromJS(child), index.toDartInt);

    _childrenForEach(children, jsIterator.toJS);
  }

  /// Returns the total number of children.
  ///
  /// Empty nodes (null, undefined, and Booleans), strings, numbers, and React
  /// elements count as individual nodes. Arrays don't count as individual
  /// nodes, but their children do.
  ///
  /// Example:
  /// ```dart
  /// final childCount = Children.count(props['children']);
  /// ```
  ///
  /// See: https://react.dev/reference/react/Children#children-count
  static int count(JSAny? children) => _childrenCount(children);

  /// Verifies that children has only one child and returns it.
  ///
  /// Throws if children has zero or more than one child.
  ///
  /// Example:
  /// ```dart
  /// final onlyChild = Children.only(props['children']);
  /// ```
  ///
  /// See: https://react.dev/reference/react/Children#children-only
  static ReactElement only(JSAny? children) =>
      ReactElement.fromJS(_childrenOnly(children));

  /// Returns children as a flat array.
  ///
  /// Useful when you need to manipulate the children with standard array
  /// methods like filter, sort, or reverse.
  ///
  /// Example:
  /// ```dart
  /// final childArray = Children.toArray(props['children']);
  /// final reversed = childArray.reversed.toList();
  /// ```
  ///
  /// See: https://react.dev/reference/react/Children#children-toarray
  static List<ReactElement> toArray(JSAny? children) => _childrenToArray(
    children,
  )
      .toDart
      .map((e) => switch (e) {
        final JSObject o => ReactElement.fromJS(o),
        _ => throw StateError('Invalid child element'),
      })
      .toList();
}
