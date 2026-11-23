import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_express/src/request.dart';
import 'package:dart_node_express/src/response.dart';

/// Type for Express next function
typedef NextFunction = void Function();

/// Type for synchronous middleware
typedef MiddlewareHandler =
    void Function(Request req, Response res, NextFunction next);

/// Converts a Dart middleware to JS function.
JSFunction middleware(MiddlewareHandler handler) =>
    ((Request req, Response res, JSFunction next) {
      handler(req, res, () => next.callAsFunction(null));
    }).toJS;

/// Chains multiple middleware functions into a single handler.
///
/// Each middleware must call `next()` to continue the chain.
/// If any middleware doesn't call `next()`, the chain stops.
JSFunction chain(List<JSFunction> middlewares) =>
    ((Request req, Response res, JSFunction next) {
      var index = 0;

      void runNext() {
        if (index < middlewares.length) {
          final current = middlewares[index++];
          current.callAsFunction(
            null,
            req,
            res,
            ((JSAny? err) {
              if (err != null) {
                // Error occurred, skip to error handler
                next.callAsFunction(null, err);
              } else {
                runNext();
              }
            }).toJS,
          );
        } else {
          // All middleware executed, call final next
          next.callAsFunction(null);
        }
      }

      runNext();
    }).toJS;

/// Request context storage key
const _contextKey = '__dart_context__';

/// Sets a value in the request context.
void setContext<T>(Request req, String key, T value) {
  var ctx = (req as JSObject)[_contextKey];
  if (ctx == null) {
    ctx = JSObject();
    (req as JSObject)[_contextKey] = ctx;
  }
  (ctx as JSObject)[key] = value.jsify();
}

/// Gets a value from the request context.
T? getContext<T>(Request req, String key) {
  final ctx = (req as JSObject)[_contextKey];
  if (ctx == null) return null;
  final value = (ctx as JSObject)[key];
  return value?.dartify() as T?;
}
