/// Test helpers for markdown editor UI tests.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/src/testing_library.dart';

/// Wait for text to appear in the rendered component
Future<void> waitForText(
  TestRenderResult result,
  String text, {
  int maxAttempts = 20,
  Duration interval = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxAttempts; i++) {
    if (result.container.textContent.contains(text)) return;
    await Future<void>.delayed(interval);
  }
  throw StateError('Text "$text" not found after $maxAttempts attempts');
}

/// JS interop for window.getSelection
@JS('window.getSelection')
external JSObject? _getSelection();

/// JS interop for document.createRange
@JS('document.createRange')
external JSObject _createRange();

/// Set the innerHTML of an editor content element
void setEditorContent(DomNode element, String html) {
  element.jsNode['innerHTML'] = html.toJS;
}

/// Select text in a contenteditable element by character offsets
void selectTextInEditor(DomNode element, int start, int end) {
  final selection = _getSelection();
  if (selection == null) return;

  final range = _createRange();
  final firstChild = element.jsNode['firstChild'];
  if (firstChild == null) return;

  final setStart = range['setStart'];
  final setEnd = range['setEnd'];
  final removeAllRanges = selection['removeAllRanges'];
  final addRange = selection['addRange'];

  if (setStart != null && setStart.isA<JSFunction>()) {
    (setStart as JSFunction)
        .callAsFunction(range, firstChild, start.toJS);
  }
  if (setEnd != null && setEnd.isA<JSFunction>()) {
    (setEnd as JSFunction).callAsFunction(range, firstChild, end.toJS);
  }
  if (removeAllRanges != null && removeAllRanges.isA<JSFunction>()) {
    (removeAllRanges as JSFunction).callAsFunction(selection);
  }
  if (addRange != null && addRange.isA<JSFunction>()) {
    (addRange as JSFunction).callAsFunction(selection, range);
  }
}

/// Select the contents of a node (positions cursor inside)
void selectNodeContents(DomNode element) {
  final selection = _getSelection();
  if (selection == null) return;

  final range = _createRange();

  final selectNode = range['selectNodeContents'];
  final collapse = range['collapse'];
  final removeAllRanges = selection['removeAllRanges'];
  final addRange = selection['addRange'];

  if (selectNode != null && selectNode.isA<JSFunction>()) {
    (selectNode as JSFunction).callAsFunction(range, element.jsNode);
  }
  if (collapse != null && collapse.isA<JSFunction>()) {
    (collapse as JSFunction).callAsFunction(range, false.toJS);
  }
  if (removeAllRanges != null && removeAllRanges.isA<JSFunction>()) {
    (removeAllRanges as JSFunction).callAsFunction(selection);
  }
  if (addRange != null && addRange.isA<JSFunction>()) {
    (addRange as JSFunction).callAsFunction(selection, range);
  }
}

/// JS interop for document.execCommand
@JS('document.execCommand')
external bool _execCommand(JSString command, JSBoolean showUI, JSAny? value);

/// Focus an element
void focusElement(DomNode element) {
  final focus = element.jsNode['focus'];
  if (focus != null && focus.isA<JSFunction>()) {
    (focus as JSFunction).callAsFunction(element.jsNode);
  }
}

/// Insert text at current cursor using execCommand
void insertTextInEditor(String text) {
  _execCommand('insertText'.toJS, false.toJS, text.toJS);
}

/// Select all content in the editor
void selectAllInEditor(DomNode element) {
  // Focus first
  focusElement(element);

  final selection = _getSelection();
  if (selection == null) return;

  final range = _createRange();

  final selectNodeContentsFunc = range['selectNodeContents'];
  final removeAllRanges = selection['removeAllRanges'];
  final addRange = selection['addRange'];

  if (selectNodeContentsFunc != null &&
      selectNodeContentsFunc.isA<JSFunction>()) {
    (selectNodeContentsFunc as JSFunction)
        .callAsFunction(range, element.jsNode);
  }
  if (removeAllRanges != null && removeAllRanges.isA<JSFunction>()) {
    (removeAllRanges as JSFunction).callAsFunction(selection);
  }
  if (addRange != null && addRange.isA<JSFunction>()) {
    (addRange as JSFunction).callAsFunction(selection, range);
  }
}
