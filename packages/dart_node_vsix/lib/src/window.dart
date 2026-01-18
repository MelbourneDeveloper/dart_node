import 'dart:js_interop';

import 'package:dart_node_vsix/src/output_channel.dart';
import 'package:dart_node_vsix/src/status_bar.dart';
import 'package:dart_node_vsix/src/tree_view.dart';
import 'package:dart_node_vsix/src/webview.dart';

/// VSCode window namespace.
extension type Window._(JSObject _) implements JSObject {
  /// Shows an information message.
  external JSPromise<JSString?> showInformationMessage(String message);

  /// Shows an error message.
  external JSPromise<JSString?> showErrorMessage(String message);

  /// Shows a warning message with optional items.
  JSPromise<JSString?> showWarningMessage(
    String message, [
    MessageOptions? options,
    String? item1,
    String? item2,
  ]) {
    if (options != null && item1 != null) {
      return _showWarningMessageWithOptions(
        message,
        options,
        item1,
        item2 ?? '',
      );
    }
    return _showWarningMessage(message);
  }

  @JS('showWarningMessage')
  external JSPromise<JSString?> _showWarningMessage(String message);

  @JS('showWarningMessage')
  external JSPromise<JSString?> _showWarningMessageWithOptions(
    String message,
    MessageOptions options,
    String item1,
    String item2,
  );

  /// Shows an input box.
  external JSPromise<JSString?> showInputBox([InputBoxOptions? options]);

  /// Shows a quick pick.
  external JSPromise<JSString?> showQuickPick(
    JSArray<JSString> items, [
    QuickPickOptions? options,
  ]);

  /// Creates an output channel.
  external OutputChannel createOutputChannel(String name);

  /// Creates a status bar item.
  external StatusBarItem createStatusBarItem([int? alignment, int? priority]);

  /// Creates a tree view.
  external TreeView<T> createTreeView<T extends TreeItem>(
    String viewId,
    TreeViewOptions<T> options,
  );

  /// Creates a webview panel.
  external WebviewPanel createWebviewPanel(
    String viewType,
    String title,
    int showOptions,
    WebviewOptions? options,
  );

  /// The currently active text editor.
  external TextEditor? get activeTextEditor;
}

/// Message options for dialogs.
extension type MessageOptions._(JSObject _) implements JSObject {
  /// Creates message options.
  factory MessageOptions({bool modal = false}) {
    final obj = _createJSObject();
    _setProperty(obj, 'modal', modal.toJS);
    return MessageOptions._(obj);
  }
}

/// Input box options.
extension type InputBoxOptions._(JSObject _) implements JSObject {
  /// Creates input box options.
  factory InputBoxOptions({
    String? prompt,
    String? placeHolder,
    String? value,
  }) {
    final obj = _createJSObject();
    if (prompt != null) _setProperty(obj, 'prompt', prompt.toJS);
    if (placeHolder != null) _setProperty(obj, 'placeHolder', placeHolder.toJS);
    if (value != null) _setProperty(obj, 'value', value.toJS);
    return InputBoxOptions._(obj);
  }
}

/// Quick pick options.
extension type QuickPickOptions._(JSObject _) implements JSObject {
  /// Creates quick pick options.
  factory QuickPickOptions({String? placeHolder}) {
    final obj = _createJSObject();
    if (placeHolder != null) _setProperty(obj, 'placeHolder', placeHolder.toJS);
    return QuickPickOptions._(obj);
  }
}

/// A text editor.
extension type TextEditor._(JSObject _) implements JSObject {
  /// The column in which this editor is shown.
  external int? get viewColumn;
}

@JS('Object.create')
external JSObject _createJSObjectFromProto(JSAny? proto);

JSObject _createJSObject() => _createJSObjectFromProto(null);

@JS('Reflect.set')
external void _setPropertyRaw(JSObject obj, JSString key, JSAny? value);

void _setProperty(JSObject obj, String key, JSAny? value) =>
    _setPropertyRaw(obj, key.toJS, value);
