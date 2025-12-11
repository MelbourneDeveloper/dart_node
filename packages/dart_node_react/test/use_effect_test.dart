/// Tests for useEffect hook.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('useEffect runs effect after mount', () {
    var effectRan = false;

    final effectComponent = registerFunctionComponent((props) {
      useEffect(() {
        effectRan = true;
        return null;
      }, []);
      return pEl('Mounted', props: {'data-testid': 'text'});
    });

    expect(effectRan, isFalse);

    final result = render(fc(effectComponent));

    expect(result.getByTestId('text').textContent, equals('Mounted'));
    result.unmount();
  });

  test('useEffect runs cleanup on unmount', () {
    var cleanupRan = false;

    final cleanupComponent = registerFunctionComponent((props) {
      useEffect(
        () =>
            () => cleanupRan = true,
        [],
      );
      return pEl('Component');
    });

    final result = render(fc(cleanupComponent));
    expect(cleanupRan, isFalse);

    result.unmount();
    expect(cleanupRan, isTrue);
  });

  test('useEffect re-runs effect when dependencies change', () {
    var effectCount = 0;

    final depsComponent = registerFunctionComponent((props) {
      final count = useState(0);
      useEffect(() {
        effectCount++;
        return null;
      }, [count.value]);
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

    effectCount = 0;
    final result = render(fc(depsComponent));

    final initialCount = effectCount;

    fireClick(result.getByTestId('inc'));
    expect(effectCount, greaterThan(initialCount));

    result.unmount();
  });

  test('useEffect does not re-run effect when dependencies unchanged', () {
    var effectCount = 0;

    final stableDepsComponent = registerFunctionComponent((props) {
      final count = useState(0);
      final other = useState(0);

      useEffect(() {
        effectCount++;
        return null;
      }, [count.value]);

      return div(
        children: [
          pEl('Count: ${count.value}'),
          button(
            text: 'Inc Other',
            props: {'data-testid': 'other'},
            onClick: () => other.set(other.value + 1),
          ),
        ],
      );
    });

    effectCount = 0;
    final result = render(fc(stableDepsComponent));
    final initialCount = effectCount;

    fireClick(result.getByTestId('other'));
    fireClick(result.getByTestId('other'));

    expect(effectCount, equals(initialCount));

    result.unmount();
  });
}
