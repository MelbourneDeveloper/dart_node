import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:markdown_editor/src/types.dart';

/// JS interop for document.execCommand
@JS('document.execCommand')
external bool _execCommand(JSString command, JSBoolean showUI, JSAny? value);

/// JS interop for document.queryCommandState
@JS('document.queryCommandState')
external JSBoolean _queryCommandState(JSString command);

/// JS interop for window.getSelection
@JS('window.getSelection')
external JSObject? _getSelection();

/// Saved selection range for link operations
JSObject? _savedRange;

/// Saved editable container element to focus before restoring selection
JSObject? _savedEditable;

/// Apply formatting action to the current selection
void applyFormat(FormatAction action) {
  final command = switch (action) {
    FormatAction.bold => 'bold',
    FormatAction.italic => 'italic',
    FormatAction.underline => 'underline',
    FormatAction.strikethrough => 'strikeThrough',
    FormatAction.code => null, // Handled separately
  };
  if (command != null) {
    _execCommand(command.toJS, false.toJS, null);
  } else if (action == FormatAction.code) {
    _wrapSelectionWith('code');
  }
}

/// Apply heading level to the current selection
void applyHeading(int level) {
  final tag = (level == 0) ? 'p' : 'h$level';
  _execCommand('formatBlock'.toJS, false.toJS, '<$tag>'.toJS);
}

/// Toggle list formatting on the current selection
void applyList({required bool ordered}) {
  final command = ordered ? 'insertOrderedList' : 'insertUnorderedList';
  _execCommand(command.toJS, false.toJS, null);
}

/// Apply block-level formatting
void applyBlock(BlockAction action) {
  switch (action) {
    case BlockAction.quote:
      _execCommand('formatBlock'.toJS, false.toJS, '<blockquote>'.toJS);
    case BlockAction.codeBlock:
      _execCommand('formatBlock'.toJS, false.toJS, '<pre>'.toJS);
    case BlockAction.horizontalRule:
      _execCommand('insertHorizontalRule'.toJS, false.toJS, null);
  }
}

/// Save the current selection range (call before opening link dialog)
void saveSelection() {
  final selection = _getSelection();
  if (selection == null) return;

  final rangeCount = selection['rangeCount'];
  if (rangeCount == null) return;

  final count = (rangeCount as JSNumber).toDartInt;
  if (count > 0) {
    final getRangeAt = selection['getRangeAt'];
    if (getRangeAt != null && getRangeAt.isA<JSFunction>()) {
      final range = (getRangeAt as JSFunction).callAsFunction(
        selection,
        0.toJS,
      );
      if (range != null && range.isA<JSObject>()) {
        // Save the common ancestor container to focus later
        final container = (range as JSObject)['commonAncestorContainer'];
        if (container != null && container.isA<JSObject>()) {
          _savedEditable = _findEditableParent(container as JSObject);
        }

        final cloneRange = range['cloneRange'];
        if (cloneRange != null && cloneRange.isA<JSFunction>()) {
          final cloned = (cloneRange as JSFunction).callAsFunction(range);
          if (cloned != null && cloned.isA<JSObject>()) {
            _savedRange = cloned as JSObject;
          }
        }
      }
    }
  }
}

/// Find the contenteditable parent element
JSObject? _findEditableParent(JSObject node) {
  var current = node;
  while (true) {
    final editable = current['contentEditable'];
    if (editable != null && editable.isA<JSString>()) {
      if ((editable as JSString).toDart == 'true') {
        return current;
      }
    }
    final parent = current['parentElement'];
    if (parent == null || !parent.isA<JSObject>()) break;
    current = parent as JSObject;
  }
  return null;
}

/// Restore the saved selection range (call before applying link)
void restoreSelection() {
  if (_savedRange == null) return;

  // Focus the editable element first
  if (_savedEditable != null) {
    final focus = _savedEditable!['focus'];
    if (focus != null && focus.isA<JSFunction>()) {
      (focus as JSFunction).callAsFunction(_savedEditable);
    }
  }

  final selection = _getSelection();
  if (selection == null) return;

  final removeAllRanges = selection['removeAllRanges'];
  final addRange = selection['addRange'];

  if (removeAllRanges != null && removeAllRanges.isA<JSFunction>()) {
    (removeAllRanges as JSFunction).callAsFunction(selection);
  }
  if (addRange != null && addRange.isA<JSFunction>()) {
    (addRange as JSFunction).callAsFunction(selection, _savedRange);
  }
}

/// Clear the saved selection
void clearSavedSelection() {
  _savedRange = null;
  _savedEditable = null;
}

/// Insert a link at the current selection
void applyLink(String url, String text) {
  if (url.isEmpty) return;
  restoreSelection();
  _execCommand('createLink'.toJS, false.toJS, url.toJS);
  clearSavedSelection();
}

/// Get the URL of the currently selected link (if cursor is inside a link)
/// Returns a record with url and text, or null if not inside a link
({String url, String text})? getSelectedLinkInfo() {
  final selection = _getSelection();
  if (selection == null) return null;

  // Get the anchor node (where the cursor is)
  final anchorNode = selection['anchorNode'];
  if (anchorNode == null) return null;

  // Walk up the DOM tree to find an anchor element
  var node = anchorNode.isA<JSObject>() ? anchorNode as JSObject : null;
  while (node != null) {
    final nodeName = node['nodeName'];
    if (nodeName case final JSString name) {
      if (name.toDart.toUpperCase() == 'A') {
        // Found an anchor element
        final href = node['href'];
        final text = node['textContent'];
        final hrefStr = (href != null && href.isA<JSString>())
            ? (href as JSString).toDart
            : '';
        final textStr = (text != null && text.isA<JSString>())
            ? (text as JSString).toDart
            : '';
        return (url: hrefStr, text: textStr);
      }
    }
    // Move to parent node
    final parent = node['parentNode'];
    node = (parent != null && parent.isA<JSObject>())
        ? parent as JSObject
        : null;
  }

  return null;
}

/// Check if a format is currently active at the cursor position
bool isFormatActive(FormatAction action) {
  final command = switch (action) {
    FormatAction.bold => 'bold',
    FormatAction.italic => 'italic',
    FormatAction.underline => 'underline',
    FormatAction.strikethrough => 'strikeThrough',
    FormatAction.code => null,
  };
  return (command != null) && _queryCommandState(command.toJS).toDart;
}

/// Wrap the current selection with a tag
void _wrapSelectionWith(String tag) {
  final selection = _getSelection();
  if (selection == null) return;

  final text = selection.callMethod<JSString>('toString'.toJS);
  final wrapped = '<$tag>${text.toDart}</$tag>';
  _execCommand('insertHTML'.toJS, false.toJS, wrapped.toJS);
}
