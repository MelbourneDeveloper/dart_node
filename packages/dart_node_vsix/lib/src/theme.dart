import 'dart:js_interop';

import 'package:dart_node_vsix/src/vscode.dart';

/// A theme icon in VSCode (e.g., 'person', 'lock', 'mail').
extension type ThemeIcon._(JSObject _) implements JSObject {
  /// Creates a theme icon with the given ID.
  factory ThemeIcon(String id) {
    final ctor = _reflectGet(vscode, 'ThemeIcon'.toJS);
    return ThemeIcon._(_reflectConstruct(ctor, [id.toJS].toJS));
  }

  /// Creates a theme icon with a color.
  factory ThemeIcon.withColor(String id, ThemeColor color) {
    final ctor = _reflectGet(vscode, 'ThemeIcon'.toJS);
    return ThemeIcon._(_reflectConstruct(ctor, [id.toJS, color].toJS));
  }

  /// The icon ID.
  external String get id;

  /// The icon color.
  external ThemeColor? get color;
}

/// A theme color reference.
extension type ThemeColor._(JSObject _) implements JSObject {
  /// Creates a theme color reference.
  factory ThemeColor(String id) {
    final ctor = _reflectGet(vscode, 'ThemeColor'.toJS);
    return ThemeColor._(_reflectConstruct(ctor, [id.toJS].toJS));
  }

  /// The color ID.
  external String get id;
}

@JS('Reflect.get')
external JSFunction _reflectGet(JSObject target, JSString key);

@JS('Reflect.construct')
external JSObject _reflectConstruct(JSFunction target, JSArray args);
