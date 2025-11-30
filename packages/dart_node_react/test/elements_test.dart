// Test for React element style conversion
// Run with: dart compile js test/elements_test.dart -o test/elements_test.js
// Then open test/test.html in browser and check console

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';

@JS('console.log')
external void consoleLog(JSAny? message);

@JS('console.error')
external void consoleError(JSAny? message);

void main() {
  consoleLog('=== STYLE TEST START ==='.toJS);

  _testDivWithStyle();
  _testButtonWithStyle();
  _testInputWithStyle();
  _testNumericPxConversion();
  _testNumericNoPxConversion();

  consoleLog('=== ALL TESTS PASSED ==='.toJS);
}

void _testDivWithStyle() {
  final element = div(
    style: {'backgroundColor': '#ff0000', 'padding': 20, 'margin': '10px'},
  );

  final props = element.getProperty('props'.toJS) as JSObject?;
  _assert(props != null, 'div props should exist');

  final style = props?.getProperty('style'.toJS) as JSObject?;
  _assert(style != null, 'div style should exist');

  final bgColor = style?.getProperty('backgroundColor'.toJS);
  _assert(
    (bgColor as JSString?)?.toDart == '#ff0000',
    'backgroundColor should be #ff0000',
  );

  final padding = style?.getProperty('padding'.toJS);
  _assert(
    (padding as JSString?)?.toDart == '20px',
    'padding should be 20px (numeric converted)',
  );

  final margin = style?.getProperty('margin'.toJS);
  _assert(
    (margin as JSString?)?.toDart == '10px',
    'margin should be 10px (string preserved)',
  );

  consoleLog('✓ testDivWithStyle passed'.toJS);
}

void _testButtonWithStyle() {
  final element = button(
    text: 'Click me',
    style: {'backgroundColor': '#6366f1', 'borderRadius': 12, 'color': 'white'},
  );

  final props = element.getProperty('props'.toJS) as JSObject?;
  final style = props?.getProperty('style'.toJS) as JSObject?;
  _assert(style != null, 'button style should exist');

  final bgColor = style?.getProperty('backgroundColor'.toJS);
  _assert(
    (bgColor as JSString?)?.toDart == '#6366f1',
    'button backgroundColor should be #6366f1',
  );

  final borderRadius = style?.getProperty('borderRadius'.toJS);
  _assert(
    (borderRadius as JSString?)?.toDart == '12px',
    'button borderRadius should be 12px',
  );

  consoleLog('✓ testButtonWithStyle passed'.toJS);
}

void _testInputWithStyle() {
  final element = input(
    type: 'text',
    style: {'backgroundColor': '#12121a', 'borderWidth': 1, 'padding': 16},
  );

  final props = element.getProperty('props'.toJS) as JSObject?;
  final style = props?.getProperty('style'.toJS) as JSObject?;
  _assert(style != null, 'input style should exist');

  final padding = style?.getProperty('padding'.toJS);
  _assert(
    (padding as JSString?)?.toDart == '16px',
    'input padding should be 16px',
  );

  consoleLog('✓ testInputWithStyle passed'.toJS);
}

void _testNumericPxConversion() {
  final element = div(
    style: {
      'width': 100,
      'height': 50,
      'borderRadius': 8,
      'fontSize': 16,
      'marginTop': 24,
      'paddingLeft': 12,
    },
  );

  final props = element.getProperty('props'.toJS) as JSObject?;
  final style = props?.getProperty('style'.toJS) as JSObject?;

  _assert(
    (style?.getProperty('width'.toJS) as JSString?)?.toDart == '100px',
    'width should have px suffix',
  );
  _assert(
    (style?.getProperty('height'.toJS) as JSString?)?.toDart == '50px',
    'height should have px suffix',
  );
  _assert(
    (style?.getProperty('borderRadius'.toJS) as JSString?)?.toDart == '8px',
    'borderRadius should have px suffix',
  );
  _assert(
    (style?.getProperty('fontSize'.toJS) as JSString?)?.toDart == '16px',
    'fontSize should have px suffix',
  );

  consoleLog('✓ testNumericPxConversion passed'.toJS);
}

void _testNumericNoPxConversion() {
  final element = div(
    style: {
      'flex': 1,
      'fontWeight': 600,
      'opacity': 0.5,
      'zIndex': 100,
      'lineHeight': 1.5,
      'order': 2,
    },
  );

  final props = element.getProperty('props'.toJS) as JSObject?;
  final style = props?.getProperty('style'.toJS) as JSObject?;

  // These should NOT have px suffix
  final flex = style?.getProperty('flex'.toJS);
  final fontWeight = style?.getProperty('fontWeight'.toJS);
  final opacity = style?.getProperty('opacity'.toJS);

  // Check they're numbers, not strings with px
  _assert(
    flex != null && (flex as JSNumber).toDartInt == 1,
    'flex should be number 1, not "1px"',
  );
  _assert(
    fontWeight != null && (fontWeight as JSNumber).toDartInt == 600,
    'fontWeight should be number 600, not "600px"',
  );
  _assert(
    opacity != null && (opacity as JSNumber).toDartDouble == 0.5,
    'opacity should be number 0.5, not "0.5px"',
  );

  consoleLog('✓ testNumericNoPxConversion passed'.toJS);
}

void _assert(bool condition, String message) => condition
    ? () {}()
    : () {
        consoleError('ASSERTION FAILED: $message'.toJS);
        throw StateError('Test failed: $message');
      }();
