/// Configuration for Too Many Cooks MCP server.
library;

import 'dart:js_interop';

import 'package:too_many_cooks_data/too_many_cooks_data.dart';

// Re-export config type from shared package.
export 'package:too_many_cooks_data/too_many_cooks_data.dart'
    show TooManyCooksDataConfig;

/// Server configuration type alias for backwards compatibility.
typedef TooManyCooksConfig = TooManyCooksDataConfig;

@JS('process')
external _Process get _process;

extension type _Process(JSObject _) implements JSObject {
  external _Env get env;
  external String cwd();
}

extension type _Env(JSObject _) implements JSObject {
  @JS('TMC_WORKSPACE')
  external JSString? get tmcWorkspace;
}

/// Get workspace folder from TMC_WORKSPACE env var or current directory.
String _getWorkspaceFolder() =>
    _process.env.tmcWorkspace?.toDart ?? _process.cwd();

/// Default configuration using workspace folder.
final defaultConfig = createDataConfigFromWorkspace(_getWorkspaceFolder());
