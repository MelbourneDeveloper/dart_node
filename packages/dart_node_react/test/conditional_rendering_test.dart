/// Tests for conditional rendering patterns.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart'
    hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('shows/hides content based on state', () {
    final toggle = registerFunctionComponent((props) {
      final visible = useState(false);
      return div(
        children: [
          button(
            text: visible.value ? 'Hide' : 'Show',
            onClick: () => visible.set(!visible.value),
            props: {'data-testid': 'toggle'},
          ),
          if (visible.value)
            pEl('Content', props: {'data-testid': 'content'})
          else
            span(''),
        ],
      );
    });

    final result = render(fc(toggle));

    expect(result.queryByTestId('content'), isNull);

    fireClick(result.getByTestId('toggle'));
    expect(result.queryByTestId('content'), isNotNull);
    expect(result.getByTestId('content').textContent, equals('Content'));

    fireClick(result.getByTestId('toggle'));
    expect(result.queryByTestId('content'), isNull);

    result.unmount();
  });

  test('switches between components', () {
    final switcher = registerFunctionComponent((props) {
      final showA = useState(true);
      return div(
        children: [
          button(
            text: 'Switch',
            onClick: () => showA.set(!showA.value),
            props: {'data-testid': 'switch'},
          ),
          if (showA.value)
            pEl('Component A', props: {'data-testid': 'a'})
          else
            pEl('Component B', props: {'data-testid': 'b'}),
        ],
      );
    });

    final result = render(fc(switcher));

    expect(result.queryByTestId('a'), isNotNull);
    expect(result.queryByTestId('b'), isNull);

    fireClick(result.getByTestId('switch'));

    expect(result.queryByTestId('a'), isNull);
    expect(result.queryByTestId('b'), isNotNull);

    result.unmount();
  });
}
