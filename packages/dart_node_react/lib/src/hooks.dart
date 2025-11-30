import 'dart:js_interop';

import 'package:dart_node_react/src/react.dart';

/// useState hook - returns (value, setter)
(JSAny?, JSFunction) useState(JSAny? initialValue) {
  final result = React.useState(initialValue);
  final setter = result[1];
  return switch (setter) {
    final JSFunction fn => (result[0], fn),
    _ => throw StateError('useState setter is null'),
  };
}

/// useEffect hook
void useEffect(JSFunction effect, [JSArray? deps]) {
  React.useEffect(effect, deps);
}

/// useRef hook
JSObject useRef(JSAny? initialValue) => React.useRef(initialValue);

/// useMemo hook
JSAny? useMemo(JSFunction factory, JSArray deps) =>
    React.useMemo(factory, deps);

/// useCallback hook
JSFunction useCallback(JSFunction callback, JSArray deps) =>
    React.useCallback(callback, deps);
