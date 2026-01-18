import 'dart:js_interop';

import 'package:dart_node_vsix/src/commands.dart';
import 'package:dart_node_vsix/src/extensions.dart';
import 'package:dart_node_vsix/src/window.dart';
import 'package:dart_node_vsix/src/workspace.dart';

/// The VSCode API namespace.
extension type VSCode._(JSObject _) implements JSObject {
  /// Gets the vscode module.
  factory VSCode() => _requireVscode('vscode');

  /// The commands namespace.
  external Commands get commands;

  /// The extensions namespace.
  external Extensions get extensions;

  /// The window namespace.
  external Window get window;

  /// The workspace namespace.
  external Workspace get workspace;
}

@JS('require')
external VSCode _requireVscode(String module);

/// Global vscode instance.
VSCode get vscode => VSCode();
