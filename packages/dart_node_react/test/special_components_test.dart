/// Tests for special components (Fragment, StrictMode).
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('Fragment groups children without wrapper', () {
    final fragmentComponent = registerFunctionComponent(
      (props) => fragment(
        children: [
          pEl('First', props: {'data-testid': 'first'}),
          pEl('Second', props: {'data-testid': 'second'}),
        ],
      ),
    );

    final result = render(fc(fragmentComponent));

    expect(result.getByTestId('first').textContent, equals('First'));
    expect(result.getByTestId('second').textContent, equals('Second'));

    result.unmount();
  });

  test('StrictMode wraps children', () {
    final strictComponent = registerFunctionComponent(
      (props) => strictMode(
        child: pEl('Strict content', props: {'data-testid': 'content'}),
      ),
    );

    final result = render(fc(strictComponent));

    expect(
      result.getByTestId('content').textContent,
      equals('Strict content'),
    );

    result.unmount();
  });
}
