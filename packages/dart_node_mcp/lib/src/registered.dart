/// Registered entity types returned from registration methods.
library;

import 'package:dart_node_mcp/src/types.dart';

/// Registered tool returned from registerTool.
///
/// Provides methods to manage the tool lifecycle.
typedef RegisteredTool = ({
  /// The tool name.
  String name,

  /// Remove the tool from the server.
  void Function() remove,

  /// Update the tool configuration.
  void Function(ToolConfig config) update,

  /// Enable the tool.
  void Function() enable,

  /// Disable the tool.
  void Function() disable,
});

/// Registered resource returned from registerResource.
///
/// Provides methods to manage the resource lifecycle.
typedef RegisteredResource = ({
  /// The resource name.
  String name,

  /// The resource URI.
  String uri,

  /// Remove the resource from the server.
  void Function() remove,

  /// Update the resource metadata.
  void Function(ResourceMetadata metadata) update,
});

/// Registered resource template returned from registerResourceTemplate.
///
/// Provides methods to manage the resource template lifecycle.
typedef RegisteredResourceTemplate = ({
  /// The resource template name.
  String name,

  /// The URI template pattern.
  String uriTemplate,

  /// Remove the resource template from the server.
  void Function() remove,

  /// Update the resource template metadata.
  void Function(ResourceMetadata metadata) update,
});

/// Registered prompt returned from registerPrompt.
///
/// Provides methods to manage the prompt lifecycle.
typedef RegisteredPrompt = ({
  /// The prompt name.
  String name,

  /// Remove the prompt from the server.
  void Function() remove,

  /// Update the prompt configuration.
  void Function(PromptConfig config) update,
});
