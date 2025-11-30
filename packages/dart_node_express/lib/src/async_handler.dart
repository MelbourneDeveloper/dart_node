import 'dart:js_interop';

import 'package:dart_node_express/src/request.dart';
import 'package:dart_node_express/src/response.dart';

/// Type definition for async request handlers
typedef AsyncRequestHandler = Future<void> Function(Request req, Response res);

/// Wraps an async handler for Express.js compatibility.
///
/// Express expects synchronous handlers, so this wrapper catches
/// any errors and passes them to Express's error handling.
JSFunction asyncHandler(AsyncRequestHandler handler) =>
    ((Request req, Response res, JSNextFunction next) {
      handler(req, res).catchError((Object error, StackTrace stack) {
        // Pass error to Express error handler
        next.callAsFunction(null, error.jsify());
      });
    }).toJS;

/// Type for Express next function with error support
extension type JSNextFunction._(JSFunction _) implements JSFunction {
  /// Call next() to continue to next middleware
  void call() => callAsFunction(null);

  /// Call next(error) to trigger error handling
  void callWithError(JSAny? error) => callAsFunction(null, error);
}
