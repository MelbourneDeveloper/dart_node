/// Type definitions for the markdown editor
library;

/// Editor view mode - either WYSIWYG or raw markdown
enum EditorMode {
  /// Rich text editing mode
  wysiwyg,

  /// Raw markdown editing mode
  markdown,
}

/// Formatting actions for inline styles
enum FormatAction {
  /// Bold formatting
  bold,

  /// Italic formatting
  italic,

  /// Underline formatting
  underline,

  /// Strikethrough formatting
  strikethrough,

  /// Inline code formatting
  code,
}

/// Block-level formatting actions
enum BlockAction {
  /// Blockquote
  quote,

  /// Code block
  codeBlock,

  /// Horizontal rule
  horizontalRule,
}

/// Heading levels (0 = paragraph, 1-6 = h1-h6)
typedef HeadingLevel = int;

/// Toolbar callback functions record
typedef ToolbarCallbacks = ({
  void Function(FormatAction) onFormat,
  void Function(HeadingLevel) onHeading,
  void Function({required bool ordered}) onList,
  void Function(BlockAction) onBlock,
  void Function(String url, String text) onLink,
  void Function() onToggleMode,
});
