/// Tests for component composition functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('parent passes props to child', () {
    final child = registerFunctionComponent(
      (props) =>
          pEl('Hello, ${props['name']}!', props: {'data-testid': 'greeting'}),
    );

    final parent = registerFunctionComponent(
      (props) => div(
        children: [
          fc(child, {'name': 'World'}),
        ],
      ),
    );

    final result = render(fc(parent));

    expect(result.getByTestId('greeting').textContent, equals('Hello, World!'));

    result.unmount();
  });

  test('child calls parent callback', () {
    var parentNotified = false;

    final child = registerFunctionComponent((props) {
      final onNotify = props['onNotify'] as void Function()?;
      return button(
        text: 'Notify',
        onClick: onNotify,
        props: {'data-testid': 'notify'},
      );
    });

    final parent = registerFunctionComponent(
      (props) => fc(child, {'onNotify': () => parentNotified = true}),
    );

    final result = render(fc(parent));

    expect(parentNotified, isFalse);

    fireClick(result.getByTestId('notify'));

    expect(parentNotified, isTrue);

    result.unmount();
  });

  test('deeply nested components work correctly', () {
    final grandChild = registerFunctionComponent(
      (props) => span('GrandChild', props: {'data-testid': 'grandchild'}),
    );

    final child = registerFunctionComponent(
      (props) => div(children: [fc(grandChild)]),
    );

    final parent = registerFunctionComponent(
      (props) => div(children: [fc(child)]),
    );

    final result = render(fc(parent));

    expect(result.getByTestId('grandchild').textContent, equals('GrandChild'));

    result.unmount();
  });
}
