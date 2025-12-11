/// Tests for isValidElement.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:test/test.dart';

void main() {
  test('isValidElement returns true for valid elements', () {
    expect(isValidElement(div()), isTrue);
    expect(isValidElement(pEl('text')), isTrue);
    expect(isValidElement(button(text: 'Click')), isTrue);
  });

  test('isValidElement returns true for function component elements', () {
    final myComponent = registerFunctionComponent((props) => pEl('Hello'));
    expect(isValidElement(fc(myComponent)), isTrue);
  });
}
