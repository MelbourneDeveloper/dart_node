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
  /// GET with middleware chain
  void getWithMiddleware(String path, List<JSFunction> handlers) {
    final jsHandlers = handlers.toJS;
    final getFn = (this as JSObject)['get'] as JSFunction;
    getFn.callAsFunction(this, path.toJS, jsHandlers);
  }

  /// POST with middleware chain
  void postWithMiddleware(String path, List<JSFunction> handlers) {
    final jsHandlers = handlers.toJS;
    final postFn = (this as JSObject)['post'] as JSFunction;
    postFn.callAsFunction(this, path.toJS, jsHandlers);
  }

  /// PUT with middleware chain
  void putWithMiddleware(String path, List<JSFunction> handlers) {
    final jsHandlers = handlers.toJS;
    final putFn = (this as JSObject)['put'] as JSFunction;
    putFn.callAsFunction(this, path.toJS, jsHandlers);
  }

  /// DELETE with middleware chain
  void deleteWithMiddleware(String path, List<JSFunction> handlers) {
    final jsHandlers = handlers.toJS;
    final deleteFn = (this as JSObject)['delete'] as JSFunction;
    deleteFn.callAsFunction(this, path.toJS, jsHandlers);
  }
}

/// Handler function type
typedef RequestHandler = void Function(Request req, Response res);

/// Create an Express application
ExpressApp express() {
  final expressFactory = requireModule('express') as JSFunction;
  return expressFactory.callAsFunction(null) as ExpressApp;
}

/// Convert a Dart handler to a JS function
JSFunction handler(RequestHandler fn) {
  return ((Request req, Response res) {
    fn(req, res);
  }).toJS;
}
