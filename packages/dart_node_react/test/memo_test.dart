/// Tests for memo2.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('memo2 prevents unnecessary re-renders', () {
    var childRenderCount = 0;

    final child = registerFunctionComponent((props) {
      childRenderCount++;
      return pEl('Name: ${props['name']}', props: {'data-testid': 'child'});
    });

    final memoizedChild = memo2(child);

    final parent = registerFunctionComponent((props) {
      final count = useState(0);
      return div(
        children: [
          pEl('Parent count: ${count.value}'),
          createElement(memoizedChild, createProps({'name': 'Alice'})),
          button(
            text: 'Inc Parent',
            props: {'data-testid': 'inc'},
            onClick: () => count.set(count.value + 1),
          ),
        ],
      );
    });

    childRenderCount = 0;
    final result = render(fc(parent));

    final initialRenders = childRenderCount;

    fireClick(result.getByTestId('inc'));

    expect(childRenderCount, equals(initialRenders));

    result.unmount();
  });

  test('memo2 re-renders when props change with custom comparison', () {
    var renderCount = 0;

    final child = registerFunctionComponent((props) {
      renderCount++;
      return pEl(
        'ID: ${props['id']}, Name: ${props['name']}',
        props: {'data-testid': 'child'},
      );
    });

    final memoizedChild = memo2(
      child,
      arePropsEqual: (prev, next) => prev['id'] == next['id'],
    );

    final parent = registerFunctionComponent((props) {
      final id = useState(1);
      final name = useState('Alice');
      return div(
        children: [
          createElement(
            memoizedChild,
            createProps({'id': id.value, 'name': name.value}),
          ),
          button(
            text: 'Change Name',
            props: {'data-testid': 'change-name'},
            onClick: () => name.set('Bob'),
          ),
          button(
            text: 'Change ID',
            props: {'data-testid': 'change-id'},
            onClick: () => id.set(id.value + 1),
          ),
        ],
      );
    });

    renderCount = 0;
    final result = render(fc(parent));

    final initial = renderCount;

    fireClick(result.getByTestId('change-name'));
    expect(renderCount, equals(initial));

    fireClick(result.getByTestId('change-id'));
    expect(renderCount, greaterThan(initial));

    result.unmount();
  });
}
