import 'dart:js_interop';

import 'package:dart_node_vsix/src/disposable.dart';

/// VSCode commands namespace.
extension type Commands._(JSObject _) implements JSObject {
  /// Registers a command that can be invoked via a keyboard shortcut,
  /// a menu item, an action, or directly.
  Disposable registerCommand(
    String command,
    void Function() callback,
  ) =>
      _registerCommand(command, callback.toJS);

  @JS('registerCommand')
  external Disposable _registerCommand(String command, JSFunction callback);

  /// Registers a command with arguments.
  Disposable registerCommandWithArgs<T extends JSAny?>(
    String command,
    void Function(T) callback,
  ) =>
      _registerCommand(command, ((T arg) => callback(arg)).toJS);

  /// Executes a command with optional arguments.
  external JSPromise<T?> executeCommand<T extends JSAny?>(
    String command, [
    JSAny? args,
  ]);
}
