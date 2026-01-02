/// Tests for useReducerLazy hook functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('lazily initializes state with primitive types', () {
    var initCount = 0;

    // Use primitive int for state to avoid JS interop issues with Map
    int init(int initialValue) {
      initCount++;
      return initialValue * 2;
    }

    int reducer(int state, String action) => switch (action) {
      'inc' => state + 1,
      _ => state,
    };

    final lazyReducer = registerFunctionComponent((props) {
      final initialValue = props['initial'] as int? ?? 5;
      final state = useReducerLazy(reducer, initialValue, init);
      return div(
        children: [
          pEl('Count: ${state.state}', props: {'data-testid': 'count'}),
          button(
            text: 'Inc',
            props: {'data-testid': 'inc'},
            onClick: () => state.dispatch('inc'),
          ),
        ],
      );
    });

    initCount = 0;
    final result = render(fc(lazyReducer, {'initial': 10}));

    expect(result.getByTestId('count').textContent, equals('Count: 20'));
    expect(initCount, equals(1));

    fireClick(result.getByTestId('inc'));
    expect(result.getByTestId('count').textContent, equals('Count: 21'));
    expect(initCount, equals(1));

    result.unmount();
  });
}
