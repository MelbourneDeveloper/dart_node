import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:markdown_editor/src/markdown_parser.dart';

/// Build the WYSIWYG editor area (contenteditable div)
/// Only syncs to parent state on blur to avoid focus loss
ReactElement buildEditorArea({
  required String htmlContent,
  required void Function(String) onContentChange,
}) => createElement(
  ((JSAny props) {
    final editorRef = useRef<JSObject>();
    final lastHtmlRef = useRef<String>();

    // Set innerHTML only when htmlContent prop changes from parent
    useEffect(() {
      final editor = editorRef.current;
      if (editor == null) return null;

      // Only update DOM if the incoming HTML is different from what we last set
      if (lastHtmlRef.current != htmlContent) {
        editor['innerHTML'] = htmlContent.toJS;
        lastHtmlRef.current = htmlContent;
      }
      return null;
    }, [htmlContent]);

    // Sync to parent state ONLY on blur
    void handleBlur(JSObject event) {
      final target = event['target'];
      if (target case final JSObject t) {
        final html = (t['innerHTML'] as JSString?)?.toDart ?? '';
        lastHtmlRef.current = html;
        onContentChange(htmlToMarkdown(html));
      }
    }

    return createElement(
      'div'.toJS,
      createProps({
        'className': 'editor-content',
        'contentEditable': 'true',
        'ref': editorRef.jsRef,
        'onBlur': handleBlur.toJS,
        'data-testid': 'editor-content',
      }),
    );
  }).toJS,
);
