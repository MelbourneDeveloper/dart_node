import 'dart:js_interop';

/// A disposable resource that can be cleaned up.
extension type Disposable._(JSObject _) implements JSObject {
  /// Creates a disposable from a dispose function.
  factory Disposable.fromFunction(void Function() disposeFunc) =>
      _createDisposable(disposeFunc.toJS);

  /// Disposes of this resource.
  external void dispose();
}

@JS('Object')
external Disposable _createDisposable(JSFunction disposeFunc);

/// Creates a Disposable that wraps a dispose callback.
Disposable createDisposable(void Function() onDispose) {
  final obj = _createJSObject();
  _setProperty(obj, 'dispose', onDispose.toJS);
  return Disposable._(obj);
}

@JS('Object')
external JSObject _createJSObject();

@JS('Object.defineProperty')
external void _setProperty(JSObject obj, String key, JSAny? value);
