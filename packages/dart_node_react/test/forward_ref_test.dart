/// Tests for forwardRef2.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('forwardRef2 forwards ref to child component', () {
    final fancyInput = forwardRef2(
      (props, ref) => input(
        type: 'text',
        placeholder: props['placeholder'] as String? ?? '',
        props: {'ref': ref, 'data-testid': 'fancy-input'},
      ),
    );

    final result = render(
      createElement(fancyInput, createProps({'placeholder': 'Enter text'})),
    );

    final inputEl = result.getByTestId('fancy-input');
    expect(inputEl.getAttribute('placeholder'), equals('Enter text'));

    result.unmount();
  });
}
