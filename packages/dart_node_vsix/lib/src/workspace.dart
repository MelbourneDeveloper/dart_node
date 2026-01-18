import 'dart:js_interop';

import 'package:dart_node_vsix/src/disposable.dart';

/// VSCode workspace namespace.
extension type Workspace._(JSObject _) implements JSObject {
  /// Gets the workspace configuration.
  external WorkspaceConfiguration getConfiguration([String? section]);

  /// Registers a listener for configuration changes.
  external Disposable onDidChangeConfiguration(JSFunction listener);
}

/// Workspace configuration.
extension type WorkspaceConfiguration._(JSObject _) implements JSObject {
  /// Gets a configuration value.
  T? get<T extends JSAny?>(String section) => _get<T>(section);

  @JS('get')
  external T? _get<T extends JSAny?>(String section);

  /// Updates a configuration value.
  external JSPromise<JSAny?> update(
    String section,
    JSAny? value, [
    int? configurationTarget,
  ]);
}
