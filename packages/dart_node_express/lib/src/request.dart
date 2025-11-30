import 'dart:js_interop';

/// Express Request object
extension type Request._(JSObject _) implements JSObject {
  external JSObject get params;
  external JSObject get query;
  external JSAny? get body;
  external String get method;
  external String get path;
  external String get url;
  external JSObject get headers;
}
