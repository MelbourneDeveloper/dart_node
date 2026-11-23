/// Callback type definitions for MCP handlers.
library;

import 'package:dart_node_mcp/src/types.dart';

/// Tool callback function type (matches `ToolCallback<Args>`).
///
/// Called when a tool is invoked with the given arguments.
typedef ToolCallback =
    Future<CallToolResult> Function(
      Map<String, Object?> args,
      ToolCallMeta? meta,
    );

/// Read resource callback function type.
///
/// Called when a resource is read by URI.
typedef ReadResourceCallback = Future<ReadResourceResult> Function(String uri);

/// Read resource template callback function type.
///
/// Called when a resource template is read with URI and variables.
typedef ReadResourceTemplateCallback =
    Future<ReadResourceResult> Function(
      String uri,
      Map<String, String> variables,
    );

/// Prompt callback function type.
///
/// Called when a prompt is requested with the given arguments.
typedef PromptCallback =
    Future<GetPromptResult> Function(Map<String, String> args);
