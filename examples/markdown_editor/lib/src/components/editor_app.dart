import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:markdown_editor/src/components/editor_area.dart';
import 'package:markdown_editor/src/components/link_dialog.dart';
import 'package:markdown_editor/src/components/markdown_view.dart';
import 'package:markdown_editor/src/components/toolbar.dart';
import 'package:markdown_editor/src/editor_commands.dart';
import 'package:markdown_editor/src/markdown_parser.dart';
import 'package:markdown_editor/src/types.dart';

/// Build the main editor app component
// ignore: non_constant_identifier_names
ReactElement EditorApp() => createElement(
  ((JSAny props) {
    final contentState = useState('');
    final modeState = useState(EditorMode.wysiwyg);
    final linkDialogOpen = useState(false);
    final linkUrlState = useState('');
    final linkTextState = useState('');

    void handleSaveSelection() {
      // Save selection on mousedown BEFORE focus can be lost
      saveSelection();
    }

    void openLinkDialog() {
      // Selection already saved on mousedown
      // Check if cursor is inside an existing link
      final linkInfo = getSelectedLinkInfo();
      if (linkInfo != null) {
        linkUrlState.set(linkInfo.url);
        linkTextState.set(linkInfo.text);
      } else {
        linkUrlState.set('');
        linkTextState.set('');
      }
      linkDialogOpen.set(true);
    }

    final callbacks = (
      onFormat: applyFormat,
      onHeading: applyHeading,
      onList: applyList,
      onBlock: applyBlock,
      onLink: applyLink,
      onToggleMode: () {
        modeState.setWithUpdater(
          (current) => switch (current) {
            EditorMode.wysiwyg => EditorMode.markdown,
            EditorMode.markdown => EditorMode.wysiwyg,
          },
        );
      },
    );

    final htmlContent = markdownToHtml(contentState.value);
    final wordCount = _countWords(contentState.value);

    return $div(className: 'app') >>
        [
          _buildHeader(),
          $main(className: 'main-content') >>
              [
                $div(className: 'editor-container') >>
                    [
                      buildToolbar(
                        mode: modeState.value,
                        callbacks: callbacks,
                        onShowLinkDialog: openLinkDialog,
                        onSaveSelection: handleSaveSelection,
                      ),
                      _buildEditorWrapper(
                        mode: modeState.value,
                        content: contentState.value,
                        htmlContent: htmlContent,
                        onContentChange: contentState.set,
                      ),
                      _buildStatusBar(
                        wordCount: wordCount,
                        mode: modeState.value,
                      ),
                    ],
              ],
          _buildFooter(),
          buildLinkDialog(
            isOpen: linkDialogOpen.value,
            onClose: () => linkDialogOpen.set(false),
            initialUrl: linkUrlState.value,
            initialText: linkTextState.value,
            onInsert: (url, text) {
              applyLink(url, text);
              linkDialogOpen.set(false);
            },
          ),
        ];
  }).toJS,
);

ReactElement _buildHeader() =>
    $header(className: 'header') >>
    ($div(className: 'header-content') >>
        [$span(className: 'logo') >> 'Markdown Editor']);

ReactElement _buildEditorWrapper({
  required EditorMode mode,
  required String content,
  required String htmlContent,
  required void Function(String) onContentChange,
}) =>
    $div(className: 'editor-wrapper') >>
    [
      switch (mode) {
        EditorMode.wysiwyg => buildEditorArea(
          htmlContent: htmlContent,
          onContentChange: onContentChange,
        ),
        EditorMode.markdown => buildMarkdownView(
          content: content,
          onContentChange: onContentChange,
        ),
      },
    ];

ReactElement _buildStatusBar({
  required int wordCount,
  required EditorMode mode,
}) =>
    $div(className: 'status-bar') >>
    [
      $span() >> '$wordCount words',
      $span() >>
          switch (mode) {
            EditorMode.wysiwyg => 'Formatted View',
            EditorMode.markdown => 'Markdown View',
          },
    ];

ReactElement _buildFooter() =>
    $footer(className: 'footer') >>
    ($p() >> 'Powered by Dart + React + Markdown');

int _countWords(String text) {
  if (text.trim().isEmpty) return 0;
  return text.trim().split(RegExp(r'\s+')).length;
}
