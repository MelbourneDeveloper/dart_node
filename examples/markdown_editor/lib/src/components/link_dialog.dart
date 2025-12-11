import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';

/// Build a link insertion dialog component
ReactElement buildLinkDialog({
  required bool isOpen,
  required void Function() onClose,
  required void Function(String url, String text) onInsert,
  String initialUrl = '',
  String initialText = '',
}) => createElement(
  ((JSAny props) {
    if (!isOpen) return null;

    final urlState = useState(initialUrl);
    final textState = useState(initialText);

    // Update state when initial values change (dialog reopens with new link)
    useEffect(() {
      urlState.set(initialUrl);
      textState.set(initialText);
      return null;
    }, [initialUrl, initialText]);

    void handleSubmit() {
      if (urlState.value.isNotEmpty) {
        onInsert(urlState.value, textState.value);
        urlState.set('');
        textState.set('');
        onClose();
      }
    }

    void handleUrlChange(JSObject e) {
      final target = e['target'];
      if (target case final JSObject t) {
        final value = t['value'];
        if (value case final JSString v) urlState.set(v.toDart);
      }
    }

    void handleTextChange(JSObject e) {
      final target = e['target'];
      if (target case final JSObject t) {
        final value = t['value'];
        if (value case final JSString v) textState.set(v.toDart);
      }
    }

    void handleKeyDown(JSObject e) {
      final key = e['key'];
      if (key case final JSString k) {
        if (k.toDart == 'Enter') handleSubmit();
        if (k.toDart == 'Escape') onClose();
      }
    }

    return $div(className: 'dialog-overlay', onClick: onClose) >>
        [
          createElement(
            'div'.toJS,
            createProps({
              'className': 'dialog',
              'onClick': ((JSObject e) {
                (e['stopPropagation']! as JSFunction).callAsFunction(e);
              }).toJS,
            }),
            [
              $div(className: 'dialog-header') >> 'Insert Link',
              $div(className: 'dialog-body') >>
                  [
                    $div(className: 'form-group') >>
                        [
                          $label() >> 'URL',
                          createElement(
                            'input'.toJS,
                            createProps({
                              'type': 'url',
                              'className': 'dialog-input',
                              'placeholder': 'https://example.com',
                              'value': urlState.value,
                              'onChange': handleUrlChange.toJS,
                              'onKeyDown': handleKeyDown.toJS,
                              'autoFocus': true,
                            }),
                          ),
                        ],
                    $div(className: 'form-group') >>
                        [
                          $label() >> 'Display Text (optional)',
                          createElement(
                            'input'.toJS,
                            createProps({
                              'type': 'text',
                              'className': 'dialog-input',
                              'placeholder': 'Link text',
                              'value': textState.value,
                              'onChange': handleTextChange.toJS,
                              'onKeyDown': handleKeyDown.toJS,
                            }),
                          ),
                        ],
                  ],
              $div(className: 'dialog-footer') >>
                  [
                    $button(className: 'btn btn-secondary', onClick: onClose) >>
                        'Cancel',
                    $button(
                          className: 'btn btn-primary',
                          onClick: handleSubmit,
                        ) >>
                        'Insert',
                  ],
            ].toJS,
          ),
        ];
  }).toJS,
);
