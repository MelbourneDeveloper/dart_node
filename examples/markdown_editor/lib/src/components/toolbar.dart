import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:markdown_editor/src/types.dart';

/// Build the editor toolbar component using JSX DSL
ReactElement buildToolbar({
  required EditorMode mode,
  required ToolbarCallbacks callbacks,
  required void Function() onShowLinkDialog,
  void Function()? onSaveSelection,
}) => createElement(
  ((JSAny props) => $div(className: 'editor-toolbar') >> [
    // Text formatting group
    $div(className: 'toolbar-group') >> [
      _toolbarBtn('B', 'Bold', () => callbacks.onFormat(FormatAction.bold)),
      _toolbarBtn('I', 'Italic', () => callbacks.onFormat(FormatAction.italic)),
      _toolbarBtn(
        'U',
        'Underline',
        () => callbacks.onFormat(FormatAction.underline),
      ),
      _toolbarBtn(
        'S',
        'Strikethrough',
        () => callbacks.onFormat(FormatAction.strikethrough),
      ),
      _toolbarBtn('<>', 'Code', () => callbacks.onFormat(FormatAction.code)),
    ],
    $span(className: 'toolbar-divider') >> '',
    // Heading selector
    _headingSelect(callbacks.onHeading),
    $span(className: 'toolbar-divider') >> '',
    // List buttons
    $div(className: 'toolbar-group') >> [
      _toolbarBtn('•', 'Bullet List', () => callbacks.onList(ordered: false)),
      _toolbarBtn('1.', 'Numbered List', () => callbacks.onList(ordered: true)),
    ],
    $span(className: 'toolbar-divider') >> '',
    // Block formatting
    $div(className: 'toolbar-group') >> [
      _toolbarBtn('"', 'Quote', () => callbacks.onBlock(BlockAction.quote)),
      _toolbarBtn(
        '{ }',
        'Code Block',
        () => callbacks.onBlock(BlockAction.codeBlock),
      ),
      _toolbarBtn(
        '—',
        'Horizontal Rule',
        () => callbacks.onBlock(BlockAction.horizontalRule),
      ),
    ],
    $span(className: 'toolbar-divider') >> '',
    // Link button
    $div(className: 'toolbar-group') >> [
      _toolbarBtn(
        '🔗',
        'Insert Link',
        onShowLinkDialog,
        onMouseDown: onSaveSelection,
      ),
    ],
    // Mode toggle
    $button(className: 'mode-toggle', onClick: callbacks.onToggleMode) >>
        switch (mode) {
          EditorMode.wysiwyg => 'View Markdown',
          EditorMode.markdown => 'View Formatted',
        },
  ]).toJS,
);

ReactElement _toolbarBtn(
  String label,
  String title,
  void Function() onClick, {
  void Function()? onMouseDown,
}) => createElement(
  'button'.toJS,
  createProps({
    'className': 'toolbar-btn',
    'title': title,
    'onClick': onClick.toJS,
    'onMouseDown': ((JSObject e) {
      // Prevent button from stealing focus from editor
      final preventDefault = e['preventDefault'];
      if (preventDefault != null && preventDefault.isA<JSFunction>()) {
        (preventDefault as JSFunction).callAsFunction(e);
      }
      // Call custom onMouseDown if provided
      onMouseDown?.call();
    }).toJS,
  }),
  [label.toJS].toJS,
);

ReactElement _headingSelect(void Function(int) onHeading) => createElement(
  'select'.toJS,
  createProps({
    'className': 'heading-select',
    'onChange': ((JSObject e) {
      final target = e['target'];
      if (target case final JSObject t) {
        final value = t['value'];
        if (value case final JSString v) {
          onHeading(int.tryParse(v.toDart) ?? 0);
        }
      }
    }).toJS,
  }),
  [
    $option(value: '0') >> 'Paragraph',
    $option(value: '1') >> 'Heading 1',
    $option(value: '2') >> 'Heading 2',
    $option(value: '3') >> 'Heading 3',
    $option(value: '4') >> 'Heading 4',
  ].toJS,
);
