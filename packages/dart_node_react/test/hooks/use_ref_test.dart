/// Tests for useRef hook functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('maintains reference across renders', () {
    final refComponent = registerFunctionComponent((props) {
      final renderCount = useRefInit(0);
      final forceUpdate = useState(0);

      renderCount.current = renderCount.current + 1;

      return div(
        children: [
          pEl(
            'Renders: ${renderCount.current}',
            props: {'data-testid': 'renders'},
          ),
          button(
            text: 'Re-render',
            props: {'data-testid': 'rerender'},
            onClick: () => forceUpdate.set(forceUpdate.value + 1),
          ),
        ],
      );
    });

    final result = render(fc(refComponent));

    expect(result.getByTestId('renders').textContent, equals('Renders: 1'));

    fireClick(result.getByTestId('rerender'));
    expect(result.getByTestId('renders').textContent, equals('Renders: 2'));

    fireClick(result.getByTestId('rerender'));
    expect(result.getByTestId('renders').textContent, equals('Renders: 3'));

    result.unmount();
  });

  test('stores mutable value without causing re-render', () {
    var renderCount = 0;

    final mutableRef = registerFunctionComponent((props) {
      renderCount++;
      final value = useRefInit(0);

      return div(
        children: [
          pEl('Value: ${value.current}', props: {'data-testid': 'value'}),
          button(
            text: 'Mutate',
            props: {'data-testid': 'mutate'},
            onClick: () => value.current = value.current + 1,
          ),
        ],
      );
    });

    renderCount = 0;
    final result = render(fc(mutableRef));

    expect(renderCount, equals(1));

    fireClick(result.getByTestId('mutate'));
    expect(renderCount, equals(1));

    result.unmount();
  });
}
