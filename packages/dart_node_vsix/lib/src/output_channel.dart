import 'dart:js_interop';

/// An output channel for displaying text output in VSCode.
extension type OutputChannel._(JSObject _) implements JSObject {
  /// The name of this output channel.
  external String get name;

  /// Appends text to the channel.
  external void append(String value);

  /// Appends a line to the channel.
  external void appendLine(String value);

  /// Clears the output channel.
  external void clear();

  /// Shows this channel in the UI.
  ///
  /// [preserveFocus] - If true, the channel will not take focus.
  external void show([bool preserveFocus]);

  /// Hides this channel from the UI.
  external void hide();

  /// Disposes of this output channel.
  external void dispose();
}
