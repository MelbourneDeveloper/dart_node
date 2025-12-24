import 'dart:js_interop';

/// A theme icon in VSCode (e.g., 'person', 'lock', 'mail').
extension type ThemeIcon._(JSObject _) implements JSObject {
  /// Creates a theme icon with the given ID.
  factory ThemeIcon(String id) => _themeIconConstructor(id.toJS);

  /// Creates a theme icon with a color.
  factory ThemeIcon.withColor(String id, ThemeColor color) =>
      _themeIconConstructorWithColor(id.toJS, color);

  /// The icon ID.
  external String get id;

  /// The icon color.
  external ThemeColor? get color;
}

@JS('vscode.ThemeIcon')
external ThemeIcon _themeIconConstructor(JSString id);

@JS('vscode.ThemeIcon')
external ThemeIcon _themeIconConstructorWithColor(
  JSString id,
  ThemeColor color,
);

/// A theme color reference.
extension type ThemeColor._(JSObject _) implements JSObject {
  /// Creates a theme color reference.
  factory ThemeColor(String id) => _themeColorConstructor(id.toJS);

  /// The color ID.
  external String get id;
}

@JS('vscode.ThemeColor')
external ThemeColor _themeColorConstructor(JSString id);
