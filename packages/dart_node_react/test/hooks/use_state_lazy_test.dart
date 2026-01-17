/// Tests for useStateLazy hook functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('initializes with lazy computed value', () {
    var computeCount = 0;

    final lazyCounter = registerFunctionComponent((props) {
      final count = useStateLazy(() {
        computeCount++;
        return 42;
      });
      return div(
        children: [
          pEl('Count: ${count.value}', props: {'data-testid': 'count'}),
          button(
            text: 'Inc',
            props: {'data-testid': 'inc'},
            onClick: () => count.set(count.value + 1),
          ),
        ],
      );
    });

    computeCount = 0;
    final result = render(fc(lazyCounter));

    expect(result.getByTestId('count').textContent, equals('Count: 42'));
    expect(computeCount, equals(1));

    // Re-render should not call initializer again
    fireClick(result.getByTestId('inc'));
    expect(result.getByTestId('count').textContent, equals('Count: 43'));
    expect(computeCount, equals(1));

    result.unmount();
  });
}
