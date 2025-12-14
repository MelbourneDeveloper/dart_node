/// Tests for synthetic event types.
@TestOn('js')
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('SyntheticEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticEvent.fromJs(jsObj);
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticClipboardEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticClipboardEvent.fromJs(jsObj);
    expect(event, isA<SyntheticClipboardEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticKeyboardEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticKeyboardEvent.fromJs(jsObj);
    expect(event, isA<SyntheticKeyboardEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticCompositionEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticCompositionEvent.fromJs(jsObj);
    expect(event, isA<SyntheticCompositionEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticFocusEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticFocusEvent.fromJs(jsObj);
    expect(event, isA<SyntheticFocusEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticFormEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticFormEvent.fromJs(jsObj);
    expect(event, isA<SyntheticFormEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticMouseEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticMouseEvent.fromJs(jsObj);
    expect(event, isA<SyntheticMouseEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticDragEvent.fromJs extends SyntheticMouseEvent', () {
    final jsObj = JSObject();
    final event = SyntheticDragEvent.fromJs(jsObj);
    expect(event, isA<SyntheticDragEvent>());
    expect(event, isA<SyntheticMouseEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticPointerEvent.fromJs extends SyntheticMouseEvent', () {
    final jsObj = JSObject();
    final event = SyntheticPointerEvent.fromJs(jsObj);
    expect(event, isA<SyntheticPointerEvent>());
    expect(event, isA<SyntheticMouseEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticTouchEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticTouchEvent.fromJs(jsObj);
    expect(event, isA<SyntheticTouchEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticTransitionEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticTransitionEvent.fromJs(jsObj);
    expect(event, isA<SyntheticTransitionEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticAnimationEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticAnimationEvent.fromJs(jsObj);
    expect(event, isA<SyntheticAnimationEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticUIEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticUIEvent.fromJs(jsObj);
    expect(event, isA<SyntheticUIEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticWheelEvent.fromJs extends SyntheticMouseEvent', () {
    final jsObj = JSObject();
    final event = SyntheticWheelEvent.fromJs(jsObj);
    expect(event, isA<SyntheticWheelEvent>());
    expect(event, isA<SyntheticMouseEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticInputEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticInputEvent.fromJs(jsObj);
    expect(event, isA<SyntheticInputEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('SyntheticChangeEvent.fromJs creates valid event', () {
    final jsObj = JSObject();
    final event = SyntheticChangeEvent.fromJs(jsObj);
    expect(event, isA<SyntheticChangeEvent>());
    expect(event, isA<SyntheticEvent>());
  });

  test('click event triggers event handler via props', () {
    SyntheticMouseEvent? capturedEvent;

    final component = registerFunctionComponent(
      (props) => createElement(
        'button'.toJS,
        createProps({
          'data-testid': 'btn',
          'onClick': (SyntheticMouseEvent e) {
            capturedEvent = e;
          },
        }),
        'Click me'.toJS,
      ),
    );

    final result = render(fc(component));
    fireClick(result.getByTestId('btn'));

    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.type, equals('click'));
    expect(capturedEvent!.bubbles, isA<bool>());
    expect(capturedEvent!.cancelable, isA<bool>());
    expect(capturedEvent!.isTrusted, isA<bool>());
    expect(capturedEvent!.timeStamp, isA<num>());
    expect(capturedEvent!.eventPhase, isA<num>());

    result.unmount();
  });

  test('mouse event has coordinate properties', () {
    SyntheticMouseEvent? capturedEvent;

    final component = registerFunctionComponent(
      (props) => createElement(
        'button'.toJS,
        createProps({
          'data-testid': 'btn',
          'onClick': (SyntheticMouseEvent e) {
            capturedEvent = e;
          },
        }),
        'Click me'.toJS,
      ),
    );

    final result = render(fc(component));
    fireClick(result.getByTestId('btn'));

    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.clientX, isA<num>());
    expect(capturedEvent!.clientY, isA<num>());
    expect(capturedEvent!.screenX, isA<num>());
    expect(capturedEvent!.screenY, isA<num>());
    expect(capturedEvent!.pageX, isA<num>());
    expect(capturedEvent!.pageY, isA<num>());
    expect(capturedEvent!.button, isA<num>());
    expect(capturedEvent!.buttons, isA<num>());

    result.unmount();
  });

  test('mouse event has modifier key properties', () {
    SyntheticMouseEvent? capturedEvent;

    final component = registerFunctionComponent(
      (props) => createElement(
        'button'.toJS,
        createProps({
          'data-testid': 'btn',
          'onClick': (SyntheticMouseEvent e) {
            capturedEvent = e;
          },
        }),
        'Click me'.toJS,
      ),
    );

    final result = render(fc(component));
    fireClick(result.getByTestId('btn'));

    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.altKey, isA<bool>());
    expect(capturedEvent!.ctrlKey, isA<bool>());
    expect(capturedEvent!.metaKey, isA<bool>());
    expect(capturedEvent!.shiftKey, isA<bool>());

    result.unmount();
  });

  test('keyboard event has keyboard-specific properties', () {
    SyntheticKeyboardEvent? capturedEvent;

    final component = registerFunctionComponent(
      (props) => createElement(
        'input'.toJS,
        createProps({
          'data-testid': 'input',
          'type': 'text',
          'onKeyDown': (SyntheticKeyboardEvent e) {
            capturedEvent = e;
          },
        }),
      ),
    );

    final result = render(fc(component));
    fireKeyDown(result.getByTestId('input'), key: 'a');

    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.key, isA<String>());
    expect(capturedEvent!.keyCode, isA<num>());
    expect(capturedEvent!.charCode, isA<num>());
    expect(capturedEvent!.location, isA<num>());
    expect(capturedEvent!.repeat, isA<bool>());

    result.unmount();
  });

  test('keyboard event has modifier key properties', () {
    SyntheticKeyboardEvent? capturedEvent;

    final component = registerFunctionComponent(
      (props) => createElement(
        'input'.toJS,
        createProps({
          'data-testid': 'input',
          'type': 'text',
          'onKeyDown': (SyntheticKeyboardEvent e) {
            capturedEvent = e;
          },
        }),
      ),
    );

    final result = render(fc(component));
    fireKeyDown(result.getByTestId('input'), key: 'a');

    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.altKey, isA<bool>());
    expect(capturedEvent!.ctrlKey, isA<bool>());
    expect(capturedEvent!.metaKey, isA<bool>());
    expect(capturedEvent!.shiftKey, isA<bool>());

    result.unmount();
  });

  test('focus events trigger handlers', () {
    var focusCalled = false;
    var blurCalled = false;

    final component = registerFunctionComponent(
      (props) => input(
        type: 'text',
        props: {'data-testid': 'input'},
        onFocus: (_) => focusCalled = true,
        onBlur: (_) => blurCalled = true,
      ),
    );

    final result = render(fc(component));

    fireFocus(result.getByTestId('input'));
    expect(focusCalled, isTrue);

    fireBlur(result.getByTestId('input'));
    expect(blurCalled, isTrue);

    result.unmount();
  });

  test('form submit event', () {
    var submitCalled = false;

    final component = registerFunctionComponent(
      (props) => createElement(
        'form'.toJS,
        createProps({
          'data-testid': 'form',
          'onSubmit': (SyntheticFormEvent e) {
            e.preventDefault();
            submitCalled = true;
          },
        }),
        button(text: 'Submit', props: {'type': 'submit'}),
      ),
    );

    final result = render(fc(component));
    fireSubmit(result.getByTestId('form'));

    expect(submitCalled, isTrue);

    result.unmount();
  });

  test('event stopPropagation prevents bubbling', () {
    var parentClicked = false;
    var childClicked = false;

    final component = registerFunctionComponent(
      (props) => createElement(
        'div'.toJS,
        createProps({
          'data-testid': 'parent',
          'onClick': (SyntheticEvent e) {
            parentClicked = true;
          },
        }),
        createElement(
          'button'.toJS,
          createProps({
            'data-testid': 'child',
            'onClick': (SyntheticEvent e) {
              childClicked = true;
              e.stopPropagation();
            },
          }),
          'Click'.toJS,
        ),
      ),
    );

    final result = render(fc(component));
    fireClick(result.getByTestId('child'));

    expect(childClicked, isTrue);
    expect(parentClicked, isFalse);

    result.unmount();
  });

  test('event preventDefault works', () {
    SyntheticEvent? capturedEvent;

    final component = registerFunctionComponent(
      (props) => createElement(
        'button'.toJS,
        createProps({
          'data-testid': 'btn',
          'onClick': (SyntheticEvent e) {
            e.preventDefault();
            capturedEvent = e;
          },
        }),
        'Click'.toJS,
      ),
    );

    final result = render(fc(component));
    fireClick(result.getByTestId('btn'));

    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.defaultPrevented, isTrue);

    result.unmount();
  });

  test('event target is accessible', () {
    JSAny? capturedTarget;

    final component = registerFunctionComponent(
      (props) => createElement(
        'button'.toJS,
        createProps({
          'data-testid': 'btn',
          'onClick': (SyntheticEvent e) {
            capturedTarget = e.target;
          },
        }),
        'Click'.toJS,
      ),
    );

    final result = render(fc(component));
    fireClick(result.getByTestId('btn'));

    expect(capturedTarget, isNotNull);

    result.unmount();
  });

  test('event nativeEvent is accessible', () {
    SyntheticEvent? capturedEvent;

    final component = registerFunctionComponent(
      (props) => createElement(
        'button'.toJS,
        createProps({
          'data-testid': 'btn',
          'onClick': (SyntheticEvent e) {
            capturedEvent = e;
          },
        }),
        'Click'.toJS,
      ),
    );

    final result = render(fc(component));
    fireClick(result.getByTestId('btn'));

    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.nativeEvent, isNotNull);

    result.unmount();
  });

  test('getModifierState works for keyboard events', () {
    SyntheticKeyboardEvent? capturedEvent;

    final component = registerFunctionComponent(
      (props) => createElement(
        'input'.toJS,
        createProps({
          'data-testid': 'input',
          'type': 'text',
          'onKeyDown': (SyntheticKeyboardEvent e) {
            capturedEvent = e;
          },
        }),
      ),
    );

    final result = render(fc(component));
    fireKeyDown(result.getByTestId('input'), key: 'a');

    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.getModifierState('Shift'), isA<bool>());
    expect(capturedEvent!.getModifierState('Control'), isA<bool>());
    expect(capturedEvent!.getModifierState('Alt'), isA<bool>());
    expect(capturedEvent!.getModifierState('Meta'), isA<bool>());

    result.unmount();
  });

  test('getModifierState works for mouse events', () {
    SyntheticMouseEvent? capturedEvent;

    final component = registerFunctionComponent(
      (props) => createElement(
        'button'.toJS,
        createProps({
          'data-testid': 'btn',
          'onClick': (SyntheticMouseEvent e) {
            capturedEvent = e;
          },
        }),
        'Click'.toJS,
      ),
    );

    final result = render(fc(component));
    fireClick(result.getByTestId('btn'));

    expect(capturedEvent, isNotNull);
    expect(capturedEvent!.getModifierState('Shift'), isA<bool>());

    result.unmount();
  });

  test('input event onChange handler', () {
    var changeValue = '';

    final component = registerFunctionComponent(
      (props) => input(
        type: 'text',
        props: {'data-testid': 'input'},
        onChange: (e) {
          changeValue = 'changed';
        },
      ),
    );

    final result = render(fc(component));
    fireChange(result.getByTestId('input'), value: 'test');

    expect(changeValue, equals('changed'));

    result.unmount();
  });
}
