/// High-level MCP Server wrapper.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_mcp/src/callbacks.dart';
import 'package:dart_node_mcp/src/registered.dart';
import 'package:dart_node_mcp/src/server.dart';
import 'package:dart_node_mcp/src/transport.dart';
import 'package:dart_node_mcp/src/types.dart';
import 'package:nadz/nadz.dart';

/// High-level MCP Server (wraps TypeScript McpServer class).
///
/// Provides a simplified API for registering tools, resources, and prompts.
class McpServer {
  McpServer._(this._mcpServer);

  final JSObject _mcpServer;
  bool _connected = false;

  /// The underlying low-level Server instance.
  Server get server {
    final jsServer = _mcpServer['server'];
    return jsServer as Server;
  }

  /// Create McpServer.
  ///
  /// Returns [Success] with the server or [Error] with message on failure.
  static Result<McpServer, String> create(
    Implementation serverInfo, {
    ServerOptions? options,
  }) {
    try {
      final sdkModule = requireModule(
        '@modelcontextprotocol/sdk/server/mcp.js',
      );
      final mcpServerClass = (sdkModule as JSObject)['McpServer'];
      final jsMcpServerClass = mcpServerClass as JSFunction;

      final jsServerInfo = _implementationToJs(serverInfo);
      final jsOptions = options != null ? _serverOptionsToJs(options) : null;

      final mcpServer = jsOptions != null
          ? jsMcpServerClass.callAsConstructor<JSObject>(
              jsServerInfo,
              jsOptions,
            )
          : jsMcpServerClass.callAsConstructor<JSObject>(jsServerInfo);

      return Success(McpServer._(mcpServer));
    } catch (e) {
      return Error('Failed to create MCP server: $e');
    }
  }

  /// Register a tool.
  ///
  /// Returns [Success] with [RegisteredTool] or [Error] with message.
  Result<RegisteredTool, String> registerTool(
    String name,
    ToolConfig config,
    ToolCallback callback,
  ) {
    try {
      final jsConfig = _toolConfigToJs(config);
      final jsCallback = _wrapToolCallback(callback);

      final registerToolFn = _mcpServer['registerTool'] as JSFunction;
      final jsResult =
          registerToolFn.callAsFunction(
                _mcpServer,
                name.toJS,
                jsConfig,
                jsCallback,
              )
              as JSObject;

      return Success(_jsToRegisteredTool(name, jsResult));
    } catch (e) {
      return Error('Failed to register tool "$name": $e');
    }
  }

  /// Register a resource.
  ///
  /// Returns [Success] with [RegisteredResource] or [Error] with message.
  Result<RegisteredResource, String> registerResource(
    String name,
    String uri,
    ResourceMetadata metadata,
    ReadResourceCallback readCallback,
  ) {
    try {
      final jsMetadata = _resourceMetadataToJs(metadata);
      final jsCallback = _wrapReadResourceCallback(readCallback);

      final registerResourceFn = _mcpServer['registerResource'] as JSFunction;
      final jsResult =
          registerResourceFn.callAsFunction(
                _mcpServer,
                name.toJS,
                uri.toJS,
                jsMetadata,
                jsCallback,
              )
              as JSObject;

      return Success(_jsToRegisteredResource(name, uri, jsResult));
    } catch (e) {
      return Error('Failed to register resource "$name": $e');
    }
  }

  /// Register a resource template.
  ///
  /// Returns [Success] with [RegisteredResourceTemplate] or [Error].
  Result<RegisteredResourceTemplate, String> registerResourceTemplate(
    String name,
    ResourceTemplate template,
    ResourceMetadata metadata,
    ReadResourceTemplateCallback readCallback,
  ) {
    try {
      final jsTemplate = _resourceTemplateToJs(template);
      final jsMetadata = _resourceMetadataToJs(metadata);
      final jsCallback = _wrapReadResourceTemplateCallback(readCallback);

      final registerResourceFn = _mcpServer['registerResource'] as JSFunction;
      final jsResult =
          registerResourceFn.callAsFunction(
                _mcpServer,
                name.toJS,
                jsTemplate,
                jsMetadata,
                jsCallback,
              )
              as JSObject;

      return Success(
        _jsToRegisteredResourceTemplate(name, template.uriTemplate, jsResult),
      );
    } catch (e) {
      return Error('Failed to register resource template "$name": $e');
    }
  }

  /// Register a prompt.
  ///
  /// Returns [Success] with [RegisteredPrompt] or [Error] with message.
  Result<RegisteredPrompt, String> registerPrompt(
    String name,
    PromptConfig config,
    PromptCallback callback,
  ) {
    try {
      final jsConfig = _promptConfigToJs(config);
      final jsCallback = _wrapPromptCallback(callback);

      final registerPromptFn = _mcpServer['registerPrompt'] as JSFunction;
      final jsResult =
          registerPromptFn.callAsFunction(
                _mcpServer,
                name.toJS,
                jsConfig,
                jsCallback,
              )
              as JSObject;

      return Success(_jsToRegisteredPrompt(name, jsResult));
    } catch (e) {
      return Error('Failed to register prompt "$name": $e');
    }
  }

  /// Connect to a transport.
  ///
  /// Returns [Success] on successful connection or [Error] with message.
  Future<Result<void, String>> connect(Transport transport) async {
    try {
      final connectFn = _mcpServer['connect'] as JSFunction;
      final promise =
          connectFn.callAsFunction(_mcpServer, transport) as JSPromise;
      await promise.toDart;
      _connected = true;
      return const Success(null);
    } catch (e) {
      return Error('Failed to connect: $e');
    }
  }

  /// Close the server.
  ///
  /// Returns [Success] on successful close or [Error] with message.
  Future<Result<void, String>> close() async {
    try {
      final closeFn = _mcpServer['close'] as JSFunction;
      final promise = closeFn.callAsFunction(_mcpServer) as JSPromise;
      await promise.toDart;
      _connected = false;
      return const Success(null);
    } catch (e) {
      return Error('Failed to close: $e');
    }
  }

  /// Check if server is connected.
  bool isConnected() {
    try {
      final isConnectedFn = _mcpServer['isConnected'] as JSFunction;
      final result = isConnectedFn.callAsFunction(_mcpServer) as JSBoolean;
      return result.toDart;
    } catch (e) {
      return _connected;
    }
  }

  /// Send logging message to client.
  Future<Result<void, String>> sendLoggingMessage(
    LoggingMessageParams params, {
    String? sessionId,
  }) async {
    try {
      final jsParams = _loggingMessageParamsToJs(params);
      final sendFn = _mcpServer['sendLoggingMessage'] as JSFunction;
      final promise = sessionId != null
          ? sendFn.callAsFunction(_mcpServer, jsParams, sessionId.toJS)
                as JSPromise
          : sendFn.callAsFunction(_mcpServer, jsParams) as JSPromise;
      await promise.toDart;
      return const Success(null);
    } catch (e) {
      return Error('Failed to send logging message: $e');
    }
  }

  /// Notify clients that resource list changed.
  void sendResourceListChanged() {
    try {
      (_mcpServer['sendResourceListChanged'] as JSFunction).callAsFunction(
        _mcpServer,
      );
    } catch (_) {
      // Ignore errors on notifications
    }
  }

  /// Notify clients that tool list changed.
  void sendToolListChanged() {
    try {
      (_mcpServer['sendToolListChanged'] as JSFunction).callAsFunction(
        _mcpServer,
      );
    } catch (_) {
      // Ignore errors on notifications
    }
  }

  /// Notify clients that prompt list changed.
  void sendPromptListChanged() {
    try {
      (_mcpServer['sendPromptListChanged'] as JSFunction).callAsFunction(
        _mcpServer,
      );
    } catch (_) {
      // Ignore errors on notifications
    }
  }
}

// Helper functions for JS conversion

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

JSObject _toolConfigToJs(ToolConfig config) {
  final obj = JSObject();
  if (config.title != null) {
    obj['title'] = config.title!.toJS;
  }
  if (config.description != null) {
    obj['description'] = config.description!.toJS;
  }
  if (config.inputSchema != null) {
    obj['inputSchema'] = config.inputSchema!.jsify();
  }
  if (config.outputSchema != null) {
    obj['outputSchema'] = config.outputSchema!.jsify();
  }
  if (config.annotations != null) {
    obj['annotations'] = _toolAnnotationsToJs(config.annotations!);
  }
  return obj;
}

JSObject _toolAnnotationsToJs(ToolAnnotations annotations) {
  final obj = JSObject();
  if (annotations.title != null) {
    obj['title'] = annotations.title!.toJS;
  }
  if (annotations.readOnlyHint != null) {
    obj['readOnlyHint'] = annotations.readOnlyHint!.toJS;
  }
  if (annotations.destructiveHint != null) {
    obj['destructiveHint'] = annotations.destructiveHint!.toJS;
  }
  if (annotations.idempotentHint != null) {
    obj['idempotentHint'] = annotations.idempotentHint!.toJS;
  }
  if (annotations.openWorldHint != null) {
    obj['openWorldHint'] = annotations.openWorldHint!.toJS;
  }
  return obj;
}

JSObject _resourceMetadataToJs(ResourceMetadata metadata) {
  final obj = JSObject();
  if (metadata.description != null) {
    obj['description'] = metadata.description!.toJS;
  }
  if (metadata.mimeType != null) {
    obj['mimeType'] = metadata.mimeType!.toJS;
  }
  return obj;
}

JSObject _resourceTemplateToJs(ResourceTemplate template) {
  final obj = JSObject();
  obj['uriTemplate'] = template.uriTemplate.toJS;
  if (template.name != null) {
    obj['name'] = template.name!.toJS;
  }
  if (template.description != null) {
    obj['description'] = template.description!.toJS;
  }
  if (template.mimeType != null) {
    obj['mimeType'] = template.mimeType!.toJS;
  }
  return obj;
}

JSObject _promptConfigToJs(PromptConfig config) {
  final obj = JSObject();
  if (config.title != null) {
    obj['title'] = config.title!.toJS;
  }
  if (config.description != null) {
    obj['description'] = config.description!.toJS;
  }
  if (config.argsSchema != null) {
    obj['argsSchema'] = config.argsSchema!.jsify();
  }
  return obj;
}

JSObject _loggingMessageParamsToJs(LoggingMessageParams params) {
  final obj = JSObject();
  obj['level'] = params.level.toJS;
  if (params.logger != null) {
    obj['logger'] = params.logger!.toJS;
  }
  if (params.data != null) {
    obj['data'] = params.data!.jsify();
  }
  return obj;
}

JSFunction _wrapToolCallback(ToolCallback callback) =>
    ((JSObject args, JSObject? meta) async {
      final dartArgs = args.dartify()! as Map<String, Object?>;
      final dartMeta = meta != null ? _jsToToolCallMeta(meta) : null;
      final result = await callback(dartArgs, dartMeta);
      return _callToolResultToJs(result);
    }).toJS;

JSFunction _wrapReadResourceCallback(ReadResourceCallback callback) =>
    ((String uri) async {
      final result = await callback(uri);
      return _readResourceResultToJs(result);
    }).toJS;

JSFunction _wrapReadResourceTemplateCallback(
  ReadResourceTemplateCallback callback,
) => ((String uri, JSObject variables) async {
  final dartVariables = variables.dartify()! as Map<String, String>;
  final result = await callback(uri, dartVariables);
  return _readResourceResultToJs(result);
}).toJS;

JSFunction _wrapPromptCallback(PromptCallback callback) =>
    ((JSObject args) async {
      final dartArgs = args.dartify()! as Map<String, String>;
      final result = await callback(dartArgs);
      return _getPromptResultToJs(result);
    }).toJS;

ToolCallMeta? _jsToToolCallMeta(JSObject meta) {
  final progressToken = meta['progressToken'];
  return (
    progressToken: progressToken != null
        ? (progressToken as JSString).toDart
        : null,
  );
}

JSObject _callToolResultToJs(CallToolResult result) {
  final obj = JSObject();
  obj['content'] = result.content.map(_contentToJs).toList().toJS;
  if (result.isError != null) {
    obj['isError'] = result.isError!.toJS;
  }
  return obj;
}

JSObject _contentToJs(Object content) {
  final obj = JSObject();
  switch (content) {
    case TextContent():
      obj['type'] = content.type.toJS;
      obj['text'] = content.text.toJS;
    case ImageContent():
      obj['type'] = content.type.toJS;
      obj['data'] = content.data.toJS;
      obj['mimeType'] = content.mimeType.toJS;
    case ResourceContent():
      obj['type'] = content.type.toJS;
      obj['uri'] = content.uri.toJS;
      if (content.mimeType != null) {
        obj['mimeType'] = content.mimeType!.toJS;
      }
      if (content.text != null) {
        obj['text'] = content.text!.toJS;
      }
    default:
      // Handle as generic map - content must be a Map for jsify
      final contentMap = content as Map<String, Object?>;
      final jsified = contentMap.jsify();
      return jsified! as JSObject;
  }
  return obj;
}

JSObject _readResourceResultToJs(ReadResourceResult result) {
  final obj = JSObject();
  obj['contents'] = result.contents.map(_contentToJs).toList().toJS;
  return obj;
}

JSObject _getPromptResultToJs(GetPromptResult result) {
  final obj = JSObject();
  if (result.description != null) {
    obj['description'] = result.description!.toJS;
  }
  obj['messages'] = result.messages.map(_promptMessageToJs).toList().toJS;
  return obj;
}

JSObject _promptMessageToJs(PromptMessage message) {
  final obj = JSObject();
  obj['role'] = message.role.toJS;
  obj['content'] = _contentToJs(message.content);
  return obj;
}

RegisteredTool _jsToRegisteredTool(String name, JSObject jsResult) {
  final removeFn = jsResult['remove']! as JSFunction;
  final updateFn = jsResult['update']! as JSFunction;
  final enableFn = jsResult['enable'] as JSFunction?;
  final disableFn = jsResult['disable'] as JSFunction?;

  return (
    name: name,
    remove: () => removeFn.callAsFunction(jsResult),
    update: (ToolConfig config) =>
        updateFn.callAsFunction(jsResult, _toolConfigToJs(config)),
    enable: () => enableFn?.callAsFunction(jsResult),
    disable: () => disableFn?.callAsFunction(jsResult),
  );
}

RegisteredResource _jsToRegisteredResource(
  String name,
  String uri,
  JSObject jsResult,
) {
  final removeFn = jsResult['remove']! as JSFunction;
  final updateFn = jsResult['update']! as JSFunction;

  return (
    name: name,
    uri: uri,
    remove: () => removeFn.callAsFunction(jsResult),
    update: (ResourceMetadata metadata) =>
        updateFn.callAsFunction(jsResult, _resourceMetadataToJs(metadata)),
  );
}

RegisteredResourceTemplate _jsToRegisteredResourceTemplate(
  String name,
  String uriTemplate,
  JSObject jsResult,
) {
  final removeFn = jsResult['remove']! as JSFunction;
  final updateFn = jsResult['update']! as JSFunction;

  return (
    name: name,
    uriTemplate: uriTemplate,
    remove: () => removeFn.callAsFunction(jsResult),
    update: (ResourceMetadata metadata) =>
        updateFn.callAsFunction(jsResult, _resourceMetadataToJs(metadata)),
  );
}

RegisteredPrompt _jsToRegisteredPrompt(String name, JSObject jsResult) {
  final removeFn = jsResult['remove']! as JSFunction;
  final updateFn = jsResult['update']! as JSFunction;

  return (
    name: name,
    remove: () => removeFn.callAsFunction(jsResult),
    update: (PromptConfig config) =>
        updateFn.callAsFunction(jsResult, _promptConfigToJs(config)),
  );
}
