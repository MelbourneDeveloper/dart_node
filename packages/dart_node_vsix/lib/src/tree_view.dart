import 'dart:js_interop';

import 'package:dart_node_vsix/src/event_emitter.dart';

/// Tree item collapsible state.
abstract final class TreeItemCollapsibleState {
  /// The item cannot be expanded.
  static const int none = 0;

  /// The item is collapsed.
  static const int collapsed = 1;

  /// The item is expanded.
  static const int expanded = 2;
}

/// A tree item in a tree view.
extension type TreeItem._(JSObject _) implements JSObject {
  /// Creates a tree item.
  factory TreeItem(
    String label, [
    int collapsibleState = TreeItemCollapsibleState.none,
  ]) => _createTreeItem(label, collapsibleState);

  /// The label of this item.
  external String get label;
  external set label(String value);

  /// The description of this item.
  external String? get description;
  external set description(String? value);

  /// The tooltip of this item.
  external JSAny? get tooltip;
  external set tooltip(JSAny? value);

  /// The icon path or theme icon of this item.
  external JSAny? get iconPath;
  external set iconPath(JSAny? value);

  /// The context value of this item.
  external String? get contextValue;
  external set contextValue(String? value);

  /// The collapsible state of this item.
  external int get collapsibleState;
  external set collapsibleState(int value);

  /// The command to execute when the item is clicked.
  external Command? get command;
  external set command(Command? value);
}

@JS('vscode.TreeItem')
external TreeItem _createTreeItem(String label, int collapsibleState);

/// A command that can be executed.
extension type Command._(JSObject _) implements JSObject {
  /// Creates a command.
  factory Command({
    required String command,
    required String title,
    JSArray<JSAny?>? arguments,
  }) {
    final obj = _createJSObject();
    _setProperty(obj, 'command', command.toJS);
    _setProperty(obj, 'title', title.toJS);
    if (arguments != null) _setProperty(obj, 'arguments', arguments);
    return Command._(obj);
  }

  /// The command identifier.
  external String get command;

  /// The title of the command.
  external String get title;

  /// Arguments for the command.
  external JSArray<JSAny?>? get arguments;
}

/// A markdown string for rich tooltips.
extension type MarkdownString._(JSObject _) implements JSObject {
  /// Creates an empty markdown string.
  factory MarkdownString([String? value]) => value != null
      ? _createMarkdownString(value)
      : _createMarkdownStringEmpty();

  /// Whether this string is trusted (can run commands).
  external bool get isTrusted;
  external set isTrusted(bool value);

  /// Appends markdown text.
  external MarkdownString appendMarkdown(String value);
}

@JS('vscode.MarkdownString')
external MarkdownString _createMarkdownString(String value);

@JS('vscode.MarkdownString')
external MarkdownString _createMarkdownStringEmpty();

/// A tree data provider.
abstract class TreeDataProvider<T extends TreeItem> {
  /// Event fired when tree data changes.
  Event<T?> get onDidChangeTreeData;

  /// Gets the tree item for an element.
  TreeItem getTreeItem(T element);

  /// Gets the children of an element.
  JSArray<T>? getChildren([T? element]);
}

/// Wrapper to create a JS-compatible tree data provider.
extension type JSTreeDataProvider<T extends TreeItem>._(JSObject _)
    implements JSObject {
  /// Creates a JS tree data provider from a Dart implementation.
  factory JSTreeDataProvider(TreeDataProvider<T> provider) {
    final obj = _createJSObject();
    _setProperty(obj, 'onDidChangeTreeData', provider.onDidChangeTreeData);
    _setProperty(
      obj,
      'getTreeItem',
      ((T element) => provider.getTreeItem(element)).toJS,
    );
    _setProperty(
      obj,
      'getChildren',
      ((T? element) => provider.getChildren(element)).toJS,
    );
    return JSTreeDataProvider<T>._(obj);
  }
}

/// Tree view options.
extension type TreeViewOptions<T extends TreeItem>._(JSObject _)
    implements JSObject {
  /// Creates tree view options.
  factory TreeViewOptions({
    required JSTreeDataProvider<T> treeDataProvider,
    bool showCollapseAll = false,
  }) {
    final obj = _createJSObject();
    _setProperty(obj, 'treeDataProvider', treeDataProvider);
    _setProperty(obj, 'showCollapseAll', showCollapseAll.toJS);
    return TreeViewOptions<T>._(obj);
  }
}

/// A tree view.
extension type TreeView<T extends TreeItem>._(JSObject _) implements JSObject {
  /// Reveals an element in the tree.
  external JSPromise<JSAny?> reveal(T element, [JSObject? options]);

  /// Disposes of this tree view.
  external void dispose();
}

@JS('Object')
external JSObject _createJSObject();

@JS('Object.defineProperty')
external void _setProperty(JSObject obj, String key, JSAny? value);
