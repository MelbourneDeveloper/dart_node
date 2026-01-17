/// Tests for useReducer hook functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('manages state transitions with primitive types', () {
    // useReducer with primitive types (int state, String actions)
    // works reliably across JS/Dart boundary.
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

  test('handles string action types', () {
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
}
