import 'dart:js_interop';

import 'package:dart_node_vsix/src/disposable.dart';

/// View column positions.
abstract final class ViewColumn {
  /// The first column.
  static const int one = 1;

  /// The second column.
  static const int two = 2;

  /// The third column.
  static const int three = 3;
}

/// Webview options.
extension type WebviewOptions._(JSObject _) implements JSObject {
  /// Creates webview options.
  factory WebviewOptions({
    bool enableScripts = false,
    bool retainContextWhenHidden = false,
  }) {
    final obj = _createJSObject();
    _setProperty(obj, 'enableScripts', enableScripts.toJS);
    _setProperty(obj, 'retainContextWhenHidden', retainContextWhenHidden.toJS);
    return WebviewOptions._(obj);
  }
}

/// A webview panel.
extension type WebviewPanel._(JSObject _) implements JSObject {
  /// The webview belonging to this panel.
  external Webview get webview;

  /// Whether this panel is visible.
  external bool get visible;

  /// The view column in which this panel is shown.
  external int? get viewColumn;

  /// Reveals the panel in the given column.
  external void reveal([int? viewColumn, bool? preserveFocus]);

  /// Event fired when the panel is disposed.
  external Disposable onDidDispose(JSFunction listener);

  /// Disposes of this panel.
  external void dispose();
}

/// A webview that displays HTML content.
extension type Webview._(JSObject _) implements JSObject {
  /// The HTML content of this webview.
  external String get html;
  external set html(String value);

  /// Posts a message to the webview.
  external JSPromise<JSBoolean> postMessage(JSAny? message);

  /// Event fired when the webview receives a message.
  external Disposable onDidReceiveMessage(JSFunction listener);
}

@JS('Object.create')
external JSObject _createJSObjectFromProto(JSAny? proto);

JSObject _createJSObject() => _createJSObjectFromProto(null);

@JS('Reflect.set')
external void _setPropertyRaw(JSObject obj, JSString key, JSAny? value);

void _setProperty(JSObject obj, String key, JSAny? value) {
  _setPropertyRaw(obj, key.toJS, value);
}
