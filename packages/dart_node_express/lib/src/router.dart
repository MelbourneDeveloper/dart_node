import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';

/// Express Router for modular route handling.
///
/// Usage:
/// ```dart
/// final router = Router();
/// router.get('/users', handler((req, res) => ...));
/// app.use('/api', router);
/// ```
extension type Router._(JSObject _) implements JSObject {
  /// Creates a new Express router.
  factory Router() {
    final express = switch (requireModule('express')) {
      final JSObject o => o,
      _ => throw StateError('Express module not found'),
    };
    final routerFn = switch (express['Router']) {
      final JSFunction f => f,
      _ => throw StateError('Express Router not found'),
    };
    final result = switch (routerFn.callAsFunction(null)) {
      final JSObject o => o,
      _ => throw StateError('Router creation failed'),
    };
    return Router._(result);
  }

  JSFunction _getMethod(String name) => switch (this[name]) {
    final JSFunction f => f,
    _ => throw StateError('Method $name not found'),
  };

  /// Register GET route
  void get(String path, JSFunction handler) =>
      _getMethod('get').callAsFunction(this, path.toJS, handler);

  /// Register POST route
  void post(String path, JSFunction handler) =>
      _getMethod('post').callAsFunction(this, path.toJS, handler);

  /// Register PUT route
  void put(String path, JSFunction handler) =>
      _getMethod('put').callAsFunction(this, path.toJS, handler);

  /// Register DELETE route
  void delete(String path, JSFunction handler) =>
      _getMethod('delete').callAsFunction(this, path.toJS, handler);

  /// Register PATCH route
  void patch(String path, JSFunction handler) =>
      _getMethod('patch').callAsFunction(this, path.toJS, handler);

  /// Use middleware
  void use(JSFunction middleware) =>
      _getMethod('use').callAsFunction(this, middleware);

  /// Use middleware at specific path
  void useAt(String path, JSFunction middleware) =>
      _getMethod('use').callAsFunction(this, path.toJS, middleware);
}
