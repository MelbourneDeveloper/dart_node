/// Tests for useReducer and useReducerLazy hooks.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('useReducer manages state transitions with primitive types', () {
    int reducer(int state, String action) => switch (action) {
      'increment' => state + 1,
      'decrement' => state - 1,
      'reset' => 0,
      _ => state,
    };

    final reducerCounter = registerFunctionComponent((props) {
      final state = useReducer(reducer, 0);
      return div(
        children: [
          pEl('Count: ${state.state}', props: {'data-testid': 'count'}),
          button(
            text: '+',
            props: {'data-testid': 'inc'},
            onClick: () => state.dispatch('increment'),
          ),
          button(
            text: '-',
            props: {'data-testid': 'dec'},
            onClick: () => state.dispatch('decrement'),
          ),
          button(
            text: 'Reset',
            props: {'data-testid': 'reset'},
            onClick: () => state.dispatch('reset'),
          ),
        ],
      );
    });

    final result = render(fc(reducerCounter));

    expect(result.getByTestId('count').textContent, equals('Count: 0'));

    fireClick(result.getByTestId('inc'));
    expect(result.getByTestId('count').textContent, equals('Count: 1'));

    fireClick(result.getByTestId('inc'));
    fireClick(result.getByTestId('inc'));
    expect(result.getByTestId('count').textContent, equals('Count: 3'));

    fireClick(result.getByTestId('dec'));
    expect(result.getByTestId('count').textContent, equals('Count: 2'));

    fireClick(result.getByTestId('reset'));
    expect(result.getByTestId('count').textContent, equals('Count: 0'));

    result.unmount();
  });

  test('useReducer handles string action types', () {
    int reducer(int state, String action) => switch (action) {
      'add' => state + 10,
      'subtract' => state - 5,
      _ => state,
    };

    final stringReducer = registerFunctionComponent((props) {
      final state = useReducer(reducer, 100);
      return div(
        children: [
          pEl('Value: ${state.state}', props: {'data-testid': 'value'}),
          button(
            text: 'Add',
            props: {'data-testid': 'add'},
            onClick: () => state.dispatch('add'),
          ),
          button(
            text: 'Sub',
            props: {'data-testid': 'sub'},
            onClick: () => state.dispatch('subtract'),
          ),
        ],
      );
    });

    final result = render(fc(stringReducer));

    expect(result.getByTestId('value').textContent, equals('Value: 100'));

    fireClick(result.getByTestId('add'));
    expect(result.getByTestId('value').textContent, equals('Value: 110'));

    fireClick(result.getByTestId('sub'));
    expect(result.getByTestId('value').textContent, equals('Value: 105'));

    result.unmount();
  });

  test('useReducerLazy lazily initializes state with primitive types', () {
    var initCount = 0;

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
