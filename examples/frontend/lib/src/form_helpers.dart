import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';

/// Create a form group with label
DivElement formGroup(String labelText, ReactElement inputElement) =>
    div(className: 'form-group', children: [labelEl(labelText), inputElement]);

/// Create a label element
ReactElement labelEl(String text) =>
    createElement('label'.toJS, createProps({'className': 'label'}), text.toJS);

/// Extract input value from event
JSString getInputValue(JSAny event) {
  final obj = switch (event) {
    final JSObject o => o,
    _ => throw StateError('Event is not an object'),
  };
  final target = obj['target'];
  return switch (target) {
    final JSObject t => switch (t['value']) {
      final JSString v => v,
      _ => throw StateError('Input value is not a string'),
    },
    _ => throw StateError('Event target is not an object'),
  };
}
