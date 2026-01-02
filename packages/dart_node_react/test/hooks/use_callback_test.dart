/// Tests for useCallback hook functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('returns stable function reference', () {
    final callbackComponent = registerFunctionComponent((props) {
      final count = useState(0);

      useCallback(() {}, []);

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

    final result = render(fc(callbackComponent));

    fireClick(result.getByTestId('inc'));
    expect(result.getByTestId('count').textContent, equals('Count: 1'));

    result.unmount();
  });
}
