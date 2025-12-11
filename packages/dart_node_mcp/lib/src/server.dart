/// Low-level MCP Server extension type.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_mcp/src/types.dart';
import 'package:nadz/nadz.dart';

/// Low-level MCP Server (wraps TypeScript Server class).
///
/// This provides direct access to the underlying Server class.
/// For most use cases, prefer `McpServer` from mcp_server.dart.
extension type Server._(JSObject _) implements JSObject {
  /// Register capabilities before connection.
  external void registerCapabilities(JSObject capabilities);

  /// Get client capabilities (after initialization).
  external JSObject? getClientCapabilities();

  /// Get client version info.
  external JSObject? getClientVersion();

  /// Set request handler for a schema.
  external void setRequestHandler(JSObject schema, JSFunction handler);

  /// Send logging message to client.
  external JSPromise<JSAny?> sendLoggingMessage(
    JSObject params,
    String? sessionId,
  );

  /// Send resource updated notification.
  external void sendResourceUpdated(JSObject params);

  /// Send resource list changed notification.
  external void sendResourceListChanged();

  /// Send tool list changed notification.
  external void sendToolListChanged();

  /// Send prompt list changed notification.
  external void sendPromptListChanged();

  /// Ping the client.
  external JSPromise<JSAny?> ping();

  /// Connect to a transport.
  external JSPromise<JSAny?> connect(JSObject transport);

  /// Close the server.
  external JSPromise<JSAny?> close();
}

/// Create low-level Server.
///
/// Returns [Success] with the server or [Error] with message on failure.
Result<Server, String> createServer(
  Implementation serverInfo, {
  ServerOptions? options,
}) {
  try {
    final sdkModule = requireModule(
      '@modelcontextprotocol/sdk/server/index.js',
    );
    final serverClass = (sdkModule as JSObject)['Server'];
    final jsServerClass = serverClass as JSFunction;

    final jsServerInfo = _implementationToJs(serverInfo);
    final jsOptions = options != null ? _serverOptionsToJs(options) : null;

    final server = jsOptions != null
        ? jsServerClass.callAsConstructor<Server>(jsServerInfo, jsOptions)
        : jsServerClass.callAsConstructor<Server>(jsServerInfo);

    return Success(server);
  } catch (e) {
    return Error('Failed to create server: $e');
  }
}

JSObject _implementationToJs(Implementation impl) {
  final obj = JSObject();
  obj['name'] = impl.name.toJS;
  obj['version'] = impl.version.toJS;
  return obj;
}

JSObject _serverOptionsToJs(ServerOptions options) {
  final obj = JSObject();
  if (options.capabilities != null) {
    obj['capabilities'] = _serverCapabilitiesToJs(options.capabilities!);
  }
  if (options.instructions != null) {
    obj['instructions'] = options.instructions!.toJS;
  }
  return obj;
}

JSObject _serverCapabilitiesToJs(ServerCapabilities caps) {
  final obj = JSObject();
  if (caps.tools != null) {
    final toolsObj = JSObject();
    if (caps.tools!.listChanged != null) {
      toolsObj['listChanged'] = caps.tools!.listChanged!.toJS;
    }
    obj['tools'] = toolsObj;
  }
  if (caps.resources != null) {
    final resourcesObj = JSObject();
    if (caps.resources!.subscribe != null) {
      resourcesObj['subscribe'] = caps.resources!.subscribe!.toJS;
    }
    if (caps.resources!.listChanged != null) {
      resourcesObj['listChanged'] = caps.resources!.listChanged!.toJS;
    }
    obj['resources'] = resourcesObj;
  }
  if (caps.prompts != null) {
    final promptsObj = JSObject();
    if (caps.prompts!.listChanged != null) {
      promptsObj['listChanged'] = caps.prompts!.listChanged!.toJS;
    }
    obj['prompts'] = promptsObj;
  }
  if (caps.logging != null) {
    final loggingObj = JSObject();
    if (caps.logging!.enabled != null) {
      loggingObj['enabled'] = caps.logging!.enabled!.toJS;
    }
    obj['logging'] = loggingObj;
  }
  return obj;
}
