/// Tests for event handling functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('click handler is called', () {
    var clicked = false;

    final clickable = registerFunctionComponent(
      (props) => button(
        text: 'Click me',
        onClick: () => clicked = true,
        props: {'data-testid': 'btn'},
      ),
    );

    final result = render(fc(clickable));

    expect(clicked, isFalse);

    fireClick(result.getByTestId('btn'));

    expect(clicked, isTrue);

    result.unmount();
  });

  test('multiple click handlers work independently', () {
    var btn1Clicks = 0;
    var btn2Clicks = 0;

    final multiButton = registerFunctionComponent(
      (props) => div(
        children: [
          button(
            text: 'Button 1',
            onClick: () => btn1Clicks++,
            props: {'data-testid': 'btn1'},
          ),
          button(
            text: 'Button 2',
            onClick: () => btn2Clicks++,
            props: {'data-testid': 'btn2'},
          ),
        ],
      ),
    );

    final result = render(fc(multiButton));

    fireClick(result.getByTestId('btn1'));
    fireClick(result.getByTestId('btn1'));
    fireClick(result.getByTestId('btn2'));

    expect(btn1Clicks, equals(2));
    expect(btn2Clicks, equals(1));

    result.unmount();
  });

  test('focus and blur events', () {
    var focused = false;
    var blurred = false;

    final focusInput = registerFunctionComponent(
      (props) => input(
        type: 'text',
        onFocus: (_) => focused = true,
        onBlur: (_) => blurred = true,
        props: {'data-testid': 'input'},
      ),
    );

    final result = render(fc(focusInput));

    fireFocus(result.getByTestId('input'));
    expect(focused, isTrue);

    fireBlur(result.getByTestId('input'));
    expect(blurred, isTrue);

    result.unmount();
  });
}
