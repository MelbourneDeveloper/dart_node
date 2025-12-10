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

/// Convert dartify() result to `Map<String, Object?>`.
/// dartify() returns `JsLinkedHashMap<Object?, Object?>` which doesn't match
/// `Map<String, Object?>` in type checks. This converts it properly.
Map<String, Object?> _toStringKeyMap(Object? dartified) {
  if (dartified == null) return <String, Object?>{};
  if (dartified is! Map) return <String, Object?>{};
  return Map<String, Object?>.fromEntries(
    dartified.entries.map(
      (e) => MapEntry(e.key.toString(), _convertValue(e.value)),
    ),
  );
}

/// Recursively convert nested maps to `Map<String, Object?>`.
Object? _convertValue(Object? value) {
  if (value is Map) return _toStringKeyMap(value);
  if (value is List) return value.map(_convertValue).toList();
  return value;
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

JSObject _toolConfigToJs(ToolConfig config) {
  final obj = JSObject();
  if (config.title != null) {
    obj['title'] = config.title!.toJS;
  }
  if (config.description != null) {
    obj['description'] = config.description!.toJS;
  }
  // MCP SDK v1.24+ requires Zod schemas for inputSchema.
  // We use z.object({}).passthrough() to accept any arguments.
  // This ensures the SDK passes args to our callback properly.
  obj['inputSchema'] = _createPassthroughZodSchema();
  if (config.annotations != null) {
    obj['annotations'] = _toolAnnotationsToJs(config.annotations!);
  }
  return obj;
}

/// Create a Zod passthrough schema that accepts any object.
/// Equivalent to: z.object({}).passthrough()
JSObject _createPassthroughZodSchema() {
  final zod = requireModule('zod') as JSObject;
  final z = zod['z'] as JSObject;
  final objectFn = z['object'] as JSFunction;
  final emptyObj = JSObject();
  final zodObject = objectFn.callAsFunction(z, emptyObj) as JSObject;
  final passthroughFn = zodObject['passthrough'] as JSFunction;
  return passthroughFn.callAsFunction(zodObject) as JSObject;
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

// The MCP SDK calls tool handlers with: handler(args, extra)
// - args: the validated tool arguments (object)
// - extra: context info with signal and requestId
//
// We always pass a Zod passthrough schema, so the SDK always passes 2 args.
JSFunction _wrapToolCallback(ToolCallback callback) =>
    ((JSAny? arg1, JSAny? arg2) {
      final args = arg1 as JSObject? ?? JSObject();
      final meta = arg2 as JSObject?;
      return _asyncToolHandler(callback, args, meta).toJS;
    }).toJS;

/// Async helper to process tool callback results.
/// Separated to avoid closure capture issues in the main wrapper.
Future<JSObject> _asyncToolHandler(
  ToolCallback callback,
  JSObject args,
  JSObject? meta,
) async {
  // Convert JS args to Dart Map
  // dartify() returns JsLinkedHashMap<Object?, Object?>, not
  //Map<String, Object?>
  // We need to cast the keys to strings manually
  final dartified = args.dartify();
  final dartArgs = _toStringKeyMap(dartified);
  final dartMeta = meta != null ? _jsToToolCallMeta(meta) : null;

  // Call the callback and await it
  final result = await callback(dartArgs, dartMeta);

  // Access record fields directly - result is typed as CallToolResult
  final content = result.content;
  final isError = result.isError;

  // Build JS object
  final obj = JSObject();
  final contentJs = <JSObject>[];
  for (final item in content) {
    contentJs.add(_contentToJs(item));
  }
  obj['content'] = contentJs.toJS;
  if (isError != null) {
    obj['isError'] = isError.toJS;
  }
  return obj;
}

// .then() is REQUIRED here - async functions cannot be converted via .toJS
// ignore: no_then
JSFunction _wrapReadResourceCallback(ReadResourceCallback callback) =>
    ((String uri) => callback(uri).then(_readResourceResultToJs).toJS).toJS;

// .then() is REQUIRED here - async functions cannot be converted via .toJS
// ignore: no_then
JSFunction _wrapReadResourceTemplateCallback(
  ReadResourceTemplateCallback callback,
) => ((String uri, JSObject variables) {
  final dartVariables = variables.dartify()! as Map<String, String>;
  return callback(uri, dartVariables).then(_readResourceResultToJs).toJS;
}).toJS;

// .then() is REQUIRED here - async functions cannot be converted via .toJS
// ignore: no_then
JSFunction _wrapPromptCallback(PromptCallback callback) => ((JSObject args) {
  final dartArgs = args.dartify()! as Map<String, String>;
  return callback(dartArgs).then(_getPromptResultToJs).toJS;
}).toJS;

ToolCallMeta? _jsToToolCallMeta(JSObject meta) {
  final progressToken = meta['progressToken'];
  return (
    progressToken: progressToken != null
        ? (progressToken as JSString).toDart
        : null,
  );
}

JSObject _contentToJs(Object content) {
  // Content is a typedef record (TextContent, ImageContent, ResourceContent).
  // We need to convert it to a plain JS object for the MCP SDK.
  //
  // IMPORTANT: In dart2js, records with String fields don't match patterns
  // that expect Object? fields. Record pattern matching checks exact type
  // identity at runtime, not structural compatibility.
  //
  // Solution: Accept Map<String, Object?> as content type. Callers should
  // pass {'type': 'text', 'text': 'value'} instead of typedef records.
  // This is the only reliable cross-platform approach.
  if (content is Map<String, Object?>) {
    return content.jsify()! as JSObject;
  }

  throw StateError(
    'Content must be Map<String, Object?>. '
    'Got: ${content.runtimeType}. '
    'Use {"type": "text", "text": "value"} format.',
  );
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
