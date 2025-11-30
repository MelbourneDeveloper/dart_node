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
    final express = requireModule('express') as JSObject;
    final routerFn = express['Router']! as JSFunction;
    return Router._(routerFn.callAsFunction(null)! as JSObject);
  }

  /// Register GET route
  void get(String path, JSFunction handler) {
    final getFn = this['get']! as JSFunction;
    getFn.callAsFunction(this, path.toJS, handler);
  }

  /// Register POST route
  void post(String path, JSFunction handler) {
    final postFn = this['post']! as JSFunction;
    postFn.callAsFunction(this, path.toJS, handler);
  }

  /// Register PUT route
  void put(String path, JSFunction handler) {
    final putFn = this['put']! as JSFunction;
    putFn.callAsFunction(this, path.toJS, handler);
  }

  /// Register DELETE route
  void delete(String path, JSFunction handler) {
    final deleteFn = this['delete']! as JSFunction;
    deleteFn.callAsFunction(this, path.toJS, handler);
  }

  /// Register PATCH route
  void patch(String path, JSFunction handler) {
    final patchFn = this['patch']! as JSFunction;
    patchFn.callAsFunction(this, path.toJS, handler);
  }

  /// Use middleware
  void use(JSFunction middleware) {
    final useFn = this['use']! as JSFunction;
    useFn.callAsFunction(this, middleware);
  }

  /// Use middleware at specific path
  void useAt(String path, JSFunction middleware) {
    final useFn = this['use']! as JSFunction;
    useFn.callAsFunction(this, path.toJS, middleware);
  }
}
