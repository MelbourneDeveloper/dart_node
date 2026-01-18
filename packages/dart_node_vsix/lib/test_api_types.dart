/// Test API types for dart_node_vsix package tests.
///
/// These types are used by both the extension and the tests to ensure
/// type-safe communication.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

/// Test API exposed by the extension to tests.
extension type TestAPI._(JSObject _) implements JSObject {
  /// Creates a TestAPI from a JSObject.
  factory TestAPI(JSObject obj) => TestAPI._(obj);
  /// Gets the list of log messages.
  external JSArray<JSString> getLogMessages();

  /// Gets the status bar item text.
  external String getStatusBarText();

  /// Gets the output channel name.
  external String getOutputChannelName();

  /// Gets the tree item count.
  external int getTreeItemCount();

  /// Fires a tree change event.
  external void fireTreeChange();

  /// Creates a test tree item.
  external TreeItem createTestTreeItem(String label);

  /// Gets whether a disposable was disposed.
  external bool wasDisposed(String name);

  /// Registers a test disposable.
  external void registerDisposable(String name);

  /// Disposes a test disposable by name.
  external void disposeByName(String name);
}
