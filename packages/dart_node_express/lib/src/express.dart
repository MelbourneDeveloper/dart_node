import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';

import 'request.dart';
import 'response.dart';

/// Express application
extension type ExpressApp._(JSObject _) implements JSObject {
  external void get(String path, JSFunction handler);
  external void post(String path, JSFunction handler);
  external void put(String path, JSFunction handler);
  external void delete(String path, JSFunction handler);
  external void use(JSAny? pathOrMiddleware, [JSFunction? middleware]);
  external void listen(int port, [JSFunction? callback]);
}

/// Extension for routes with multiple handlers (middleware + handler)
extension ExpressAppMultiHandler on ExpressApp {
  JSFunction _getMethod(String name) => switch (_[name]) {
    final JSFunction f => f,
    _ => throw StateError('Method $name not found'),
  };

  /// GET with middleware chain
  void getWithMiddleware(String path, List<JSFunction> handlers) =>
      _getMethod('get').callAsFunction(this, path.toJS, handlers.toJS);

  /// POST with middleware chain
  void postWithMiddleware(String path, List<JSFunction> handlers) =>
      _getMethod('post').callAsFunction(this, path.toJS, handlers.toJS);

  /// PUT with middleware chain
  void putWithMiddleware(String path, List<JSFunction> handlers) =>
      _getMethod('put').callAsFunction(this, path.toJS, handlers.toJS);

  /// DELETE with middleware chain
  void deleteWithMiddleware(String path, List<JSFunction> handlers) =>
      _getMethod('delete').callAsFunction(this, path.toJS, handlers.toJS);
}

/// Handler function type
typedef RequestHandler = void Function(Request req, Response res);

/// Create an Express application
ExpressApp express() {
  final expressFactory = switch (requireModule('express')) {
    final JSFunction f => f,
    _ => throw StateError('Express module not found'),
  };
  return switch (expressFactory.callAsFunction(null)) {
    final ExpressApp app => app,
    _ => throw StateError('Express app creation failed'),
  };
}

/// Convert a Dart handler to a JS function
JSFunction handler(RequestHandler fn) {
  return ((Request req, Response res) {
    fn(req, res);
  }).toJS;
}
