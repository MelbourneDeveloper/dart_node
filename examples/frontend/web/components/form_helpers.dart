import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:dart_node_react/dart_node_react.dart';
import 'package:shared/theme/theme.dart';

/// Create a form group with label
DivElement formGroup(String labelText, ReactElement inputElement) => div(
      className: 'form-group',
      style: AppStyles.formGroup,
      children: [labelEl(labelText), inputElement],
    );

/// Create a label element
ReactElement labelEl(String text) => createElement(
      'label'.toJS,
      createProps({
        'className': 'label',
        'style': convertStyle(AppStyles.label),
      }),
      text.toJS,
    );

/// Extract input value from event
JSString getInputValue(JSAny event) {
  final obj = event as JSObject;
  final target = obj.getProperty('target'.toJS);
  return switch (target) {
    final JSObject t => switch (t.getProperty('value'.toJS)) {
      final JSString v => v,
      _ => throw StateError('Input value is not a string'),
    },
    _ => throw StateError('Event target is not an object'),
  };
}

/// Get property from JSObject safely
JSAny? getProp(JSObject obj, String key) => obj.getProperty(key.toJS);

/// Get string property
String? getStringProp(JSObject obj, String key) =>
    (obj.getProperty(key.toJS) as JSString?)?.toDart;

/// Get bool property
bool getBoolProp(JSObject obj, String key, {bool defaultValue = false}) =>
    (obj.getProperty(key.toJS) as JSBoolean?)?.toDart ?? defaultValue;
