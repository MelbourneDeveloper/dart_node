/// Tests for useMemo hook functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('memoizes expensive computation', () {
    var computeCount = 0;

    final memoComponent = registerFunctionComponent((props) {
      final count = useState(0);
      final other = useState(0);

      final expensive = useMemo(() {
        computeCount++;
        return count.value * 2;
      }, [count.value]);

      return div(
        children: [
          pEl('Result: $expensive', props: {'data-testid': 'result'}),
          button(
            text: 'Inc Count',
            props: {'data-testid': 'inc-count'},
            onClick: () => count.set(count.value + 1),
          ),
          button(
            text: 'Inc Other',
            props: {'data-testid': 'inc-other'},
            onClick: () => other.set(other.value + 1),
          ),
        ],
      );
    });

    computeCount = 0;
    final result = render(fc(memoComponent));

    expect(result.getByTestId('result').textContent, equals('Result: 0'));
    final initialCompute = computeCount;

    fireClick(result.getByTestId('inc-count'));
    expect(result.getByTestId('result').textContent, equals('Result: 2'));
    expect(computeCount, greaterThan(initialCompute));

    final afterIncrement = computeCount;

    fireClick(result.getByTestId('inc-other'));
    expect(computeCount, equals(afterIncrement));

    result.unmount();
  });
}
