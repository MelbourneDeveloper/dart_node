/// Tests for useLayoutEffect hook functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('runs synchronously after DOM mutations', () {
    final layoutComponent = registerFunctionComponent((props) {
      useLayoutEffect(() => null, []);
      return pEl('Layout', props: {'data-testid': 'text'});
    });

    final result = render(fc(layoutComponent));
    expect(result.getByTestId('text').textContent, equals('Layout'));
    result.unmount();
  });
}
