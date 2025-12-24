/// VSCode extension API bindings for Dart.
///
/// Provides typed Dart wrappers over the VSCode extension API using
/// `dart:js_interop`. All public APIs are fully typed - no JSObject,
/// JSAny, or dynamic exposure.
///
/// ## Example
///
/// ```dart
/// import 'package:dart_node_vsix/dart_node_vsix.dart';
///
/// Future<void> activate(ExtensionContext context) async {
///   final outputChannel = vscode.window.createOutputChannel('My Extension');
///   outputChannel.appendLine('Hello from Dart!');
///
///   final cmd = vscode.commands.registerCommand(
///     'myExtension.hello',
///     () => vscode.window.showInformationMessage('Hello!'),
///   );
///   context.subscriptions.add(cmd);
/// }
/// ```
library;

export 'src/commands.dart';
export 'src/disposable.dart';
export 'src/event_emitter.dart';
export 'src/extension_context.dart';
export 'src/output_channel.dart';
export 'src/promise.dart';
export 'src/status_bar.dart';
export 'src/theme.dart';
export 'src/tree_view.dart';
export 'src/uri.dart';
export 'src/vscode.dart';
export 'src/webview.dart';
export 'src/window.dart';
export 'src/workspace.dart';
