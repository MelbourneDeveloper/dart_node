/// Tests for useContext hook functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('provides default value when no provider', () {
    final themeContext = createContext('light');

    final consumer = registerFunctionComponent((props) {
      final theme = useContext(themeContext);
      return pEl('Theme: $theme', props: {'data-testid': 'theme'});
    });

    final result = render(fc(consumer));

    expect(result.getByTestId('theme').textContent, equals('Theme: light'));

    result.unmount();
  });

  test('reads value from nearest provider', () {
    final themeContext = createContext('light');

    final consumer = registerFunctionComponent((props) {
      final theme = useContext(themeContext);
      return pEl('Theme: $theme', props: {'data-testid': 'theme'});
    });

    final app = registerFunctionComponent(
      (props) => createElement(
        themeContext.providerType,
        createProps({'value': 'dark'}),
        fc(consumer),
      ),
    );

    final result = render(fc(app));

    expect(result.getByTestId('theme').textContent, equals('Theme: dark'));

    result.unmount();
  });

  test('updates when provider value changes', () {
    final countContext = createContext(0);

    final consumer = registerFunctionComponent((props) {
      final count = useContext(countContext);
      return pEl('Count: $count', props: {'data-testid': 'count'});
    });

    final provider = registerFunctionComponent((props) {
      final count = useState(0);
      return createElement(
        countContext.providerType,
        createProps({'value': count.value}),
        div(
          children: [
            fc(consumer),
            button(
              text: 'Inc',
              props: {'data-testid': 'inc'},
              onClick: () => count.set(count.value + 1),
            ),
          ],
        ),
      );
    });

    final result = render(fc(provider));

    expect(result.getByTestId('count').textContent, equals('Count: 0'));

    fireClick(result.getByTestId('inc'));
    expect(result.getByTestId('count').textContent, equals('Count: 1'));

    result.unmount();
  });

  test('handles nested providers', () {
    final themeContext = createContext('default');

    final consumer = registerFunctionComponent((props) {
      final theme = useContext(themeContext);
      return pEl('Theme: $theme', props: {'data-testid': 'theme'});
    });

    final app = registerFunctionComponent(
      (props) => createElement(
        themeContext.providerType,
        createProps({'value': 'outer'}),
        div(
          children: [
            createElement(
              themeContext.providerType,
              createProps({'value': 'inner'}),
              fc(consumer),
            ),
          ],
        ),
      ),
    );

    final result = render(fc(app));

    expect(result.getByTestId('theme').textContent, equals('Theme: inner'));

    result.unmount();
  });
}
