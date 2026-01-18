import 'dart:js_interop';

/// Extension to convert `JSPromise<JSString?>` to `Future<String?>`.
extension JSPromiseStringToFuture on JSPromise<JSString?> {
  /// Converts this JSPromise to a Dart `Future<String?>`.
  Future<String?> get toDartString async {
    final jsResult = await toDart;
    return jsResult?.toDart;
  }
}

/// Extension to convert `JSPromise<JSAny?>` to Future.
extension JSPromiseToFuture<T extends JSAny?> on JSPromise<T> {
  /// Converts this JSPromise to a Dart Future.
  Future<T> get asFuture => toDart;
}
