/// Core MCP types matching TypeScript SDK.
library;

/// Server implementation info (matches TypeScript Implementation type).
typedef Implementation = ({String name, String version});

/// Tools capability configuration.
typedef ToolsCapability = ({bool? listChanged});

/// Resources capability configuration.
typedef ResourcesCapability = ({bool? subscribe, bool? listChanged});

/// Prompts capability configuration.
typedef PromptsCapability = ({bool? listChanged});

/// Logging capability configuration.
typedef LoggingCapability = ({bool? enabled});

/// Server capabilities.
typedef ServerCapabilities = ({
  ToolsCapability? tools,
  ResourcesCapability? resources,
  PromptsCapability? prompts,
  LoggingCapability? logging,
});

/// Server options for initialization.
typedef ServerOptions = ({
  ServerCapabilities? capabilities,
  String? instructions,
});

/// Tool annotations providing hints about tool behavior.
typedef ToolAnnotations = ({
  String? title,
  bool? readOnlyHint,
  bool? destructiveHint,
  bool? idempotentHint,
  bool? openWorldHint,
});

/// Tool configuration for registration (matches registerTool config param).
typedef ToolConfig = ({
  String? title,
  String? description,
  Map<String, Object?>? inputSchema,
  Map<String, Object?>? outputSchema,
  ToolAnnotations? annotations,
});

/// Resource metadata.
typedef ResourceMetadata = ({String? description, String? mimeType});

/// Resource template for URI patterns.
typedef ResourceTemplate = ({
  String uriTemplate,
  String? name,
  String? description,
  String? mimeType,
});

/// Prompt configuration for registration.
typedef PromptConfig = ({
  String? title,
  String? description,
  Map<String, Object?>? argsSchema,
});

/// Logging message parameters.
typedef LoggingMessageParams = ({String level, String? logger, Object? data});

/// Text content in tool results.
typedef TextContent = ({String type, String text});

/// Image content in tool results (base64 encoded).
typedef ImageContent = ({String type, String data, String mimeType});

/// Resource content in tool results.
typedef ResourceContent = ({
  String type,
  String uri,
  String? mimeType,
  String? text,
});

/// Tool call result.
typedef CallToolResult = ({List<Object> content, bool? isError});

/// Read resource result.
typedef ReadResourceResult = ({List<Object> contents});

/// Prompt message in prompt results.
typedef PromptMessage = ({String role, Object content});

/// Get prompt result.
typedef GetPromptResult = ({String? description, List<PromptMessage> messages});

/// Tool call metadata.
typedef ToolCallMeta = ({String? progressToken});

/// Resource updated notification params.
typedef ResourceUpdatedParams = ({String uri});

/// JSON-RPC message for transport.
typedef JsonRpcMessage = ({
  String jsonrpc,
  String? method,
  Object? params,
  Object? id,
  Object? result,
  Object? error,
});
