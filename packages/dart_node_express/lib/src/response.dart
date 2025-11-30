import 'dart:js_interop';

/// Express Response object
extension type Response._(JSObject _) implements JSObject {
  external void send(String body);
  external void json(JSAny? obj);
  external void status(int code);
  external void set(String field, String value);
  external void redirect(String url);
  external void end();
}

/// Extension for convenient methods
extension ResponseExtensions on Response {
  /// Send a JSON response from a Dart Map
  void jsonMap(Map<String, dynamic> data) {
    json(data.jsify());
  }
}
