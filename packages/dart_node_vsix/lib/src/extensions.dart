import 'dart:js_interop';

/// VSCode extensions namespace for accessing installed extensions.
extension type Extensions._(JSObject _) implements JSObject {
  /// Gets an extension by its full identifier (publisher.name).
  external Extension? getExtension(String extensionId);

  /// Gets all installed extensions.
  external JSArray<Extension> get all;
}

/// Represents a VSCode extension.
extension type Extension._(JSObject _) implements JSObject {
  /// The extension's unique identifier (publisher.name).
  external String get id;

  /// The extension's exports (set by the extension's activate function).
  external JSAny? get exports;

  /// Whether the extension is currently active.
  external bool get isActive;

  /// The absolute path to the extension's directory.
  external String get extensionPath;

  /// Activates the extension if not already active.
  /// Returns a promise that resolves to the extension's exports.
  external JSPromise<JSAny?> activate();
}
