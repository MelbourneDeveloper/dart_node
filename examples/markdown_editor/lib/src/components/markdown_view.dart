import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';

/// Build the raw markdown textarea view
/// Uses uncontrolled component with ref to avoid focus loss on typing
ReactElement buildMarkdownView({
  required String content,
  required void Function(String) onContentChange,
}) => createElement(
  ((JSAny props) {
    final textareaRef = useRef<JSObject>();
    final lastContentRef = useRef<String>();

    // Only update textarea value when content prop changes from parent
    useEffect(() {
      final textarea = textareaRef.current;
      if (textarea == null) return null;

      // Only update if the incoming content differs from what we last set
      if (lastContentRef.current != content) {
        textarea['value'] = content.toJS;
        lastContentRef.current = content;
      }
      return null;
    }, [content]);

    // Sync to parent state ONLY on blur to avoid focus loss
    void handleBlur(JSObject event) {
      final target = event['target'];
      if (target case final JSObject t) {
        final value = t['value'];
        if (value case final JSString v) {
          lastContentRef.current = v.toDart;
          onContentChange(v.toDart);
        }
      }
    }

    return createElement(
      'textarea'.toJS,
      createProps({
        'className': 'markdown-textarea',
        'ref': textareaRef.jsRef,
        'onBlur': handleBlur.toJS,
        'placeholder': 'Write your markdown here...',
        'data-testid': 'markdown-textarea',
      }),
    );
  }).toJS,
);
