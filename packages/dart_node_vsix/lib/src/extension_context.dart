import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_vsix/src/disposable.dart';
import 'package:dart_node_vsix/src/uri.dart';

/// The context for a VSCode extension.
extension type ExtensionContext._(JSObject _) implements JSObject {
  /// Subscriptions that will be disposed when the extension is deactivated.
  List<Disposable> get subscriptions => _getSubscriptions(_);

  /// Adds a disposable to the subscriptions.
  void addSubscription(Disposable disposable) =>
      _pushSubscription(_, disposable);

  /// The URI of the extension's install directory.
  external VsUri get extensionUri;

  /// The absolute file path of the extension's install directory.
  external String get extensionPath;

  /// The storage URI for global state.
  external VsUri? get globalStorageUri;

  /// The storage URI for workspace state.
  external VsUri? get storageUri;

  /// A memento for storing global state.
  external Memento get globalState;

  /// A memento for storing workspace state.
  external Memento get workspaceState;
}

/// A memento for storing extension state.
extension type Memento._(JSObject _) implements JSObject {
  /// Gets a value from the memento.
  T? get<T extends JSAny?>(String key) => _mementoGet<T>(_, key.toJS);

  /// Updates a value in the memento.
  Future<void> update(String key, Object? value) =>
      _mementoUpdate(_, key.toJS, value.jsify()).toDart;

  /// Gets all keys in the memento.
  List<String> keys() => _mementoKeys(_).toDart.cast<String>();
}

List<Disposable> _getSubscriptions(JSObject context) {
  final arr = context['subscriptions']! as JSArray<Disposable>;
  return [for (var i = 0; i < arr.length; i++) arr[i]];
}

void _pushSubscription(JSObject context, Disposable disposable) {
  final subs = context['subscriptions']! as JSObject;
  (subs['push']! as JSFunction).callAsFunction(subs, disposable);
}

@JS()
external T? _mementoGet<T extends JSAny?>(JSObject memento, JSString key);

@JS()
external JSPromise<JSAny?> _mementoUpdate(
  JSObject memento,
  JSString key,
  JSAny? value,
);

@JS()
external JSArray<JSString> _mementoKeys(JSObject memento);
