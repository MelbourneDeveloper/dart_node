import 'dart:js_interop';

import 'package:dart_node_vsix/src/theme.dart';

/// Status bar alignment.
enum StatusBarAlignment {
  /// Left side of the status bar.
  left(1),

  /// Right side of the status bar.
  right(2);

  const StatusBarAlignment(this.value);

  /// The numeric value for the VSCode API.
  final int value;
}

/// A status bar item in VSCode.
extension type StatusBarItem._(JSObject _) implements JSObject {
  /// The alignment of this item.
  int get alignment => _getAlignment(_);

  /// The priority (higher = more to the left/right).
  external int get priority;

  /// The text shown in the status bar.
  external String get text;
  external set text(String value);

  /// The tooltip shown on hover.
  external String? get tooltip;
  external set tooltip(String? value);

  /// The foreground color.
  external ThemeColor? get color;
  external set color(ThemeColor? value);

  /// The background color.
  external ThemeColor? get backgroundColor;
  external set backgroundColor(ThemeColor? value);

  /// The command to execute on click.
  external String? get command;
  external set command(String? value);

  /// Shows this item in the status bar.
  external void show();

  /// Hides this item from the status bar.
  external void hide();

  /// Disposes of this item.
  external void dispose();
}

@JS()
external int _getAlignment(JSObject item);
