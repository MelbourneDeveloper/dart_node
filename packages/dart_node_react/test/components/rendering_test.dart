/// Tests for conditional and list rendering functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  group('Conditional rendering', () {
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
  });

  group('List rendering', () {
    test('renders static list of items', () {
      // Static list that doesn't rely on state
      final itemList = registerFunctionComponent((props) {
        // Use static data passed via props
        final itemsStr = props['items'] as String? ?? 'Apple,Banana,Cherry';
        final items = itemsStr.split(',');
        return ul(
          props: {'data-testid': 'list'},
          children: items
              .map((item) => li(item, props: {'key': item}))
              .toList(),
        );
      });

      final result = render(fc(itemList, {'items': 'Apple,Banana,Cherry'}));

      final list = result.getByTestId('list');
      expect(list.innerHTML, contains('Apple'));
      expect(list.innerHTML, contains('Banana'));
      expect(list.innerHTML, contains('Cherry'));

      result.unmount();
    });

    test('adds and removes items via string state', () {
      // Use comma-separated string for list state to work with JS interop
      final dynamicList = registerFunctionComponent((props) {
        final itemsStr = useState('One');
        final items = itemsStr.value.split(',').where((s) => s.isNotEmpty);
        return div(
          children: [
            ul(
              props: {'data-testid': 'list'},
              children: items.map(li).toList(),
            ),
            button(
              text: 'Add',
              onClick: () => itemsStr.set('${itemsStr.value},New'),
              props: {'data-testid': 'add'},
            ),
            button(
              text: 'Remove',
              onClick: () {
                final parts = itemsStr.value.split(',');
                final newValue = parts.length > 1
                    ? parts.sublist(0, parts.length - 1).join(',')
                    : '';
                itemsStr.set(newValue);
              },
              props: {'data-testid': 'remove'},
            ),
          ],
        );
      });

      final result = render(fc(dynamicList));

      expect(result.getByTestId('list').innerHTML, contains('One'));

      fireClick(result.getByTestId('add'));
      expect(result.getByTestId('list').innerHTML, contains('New'));

      fireClick(result.getByTestId('remove'));
      expect(result.getByTestId('list').innerHTML, isNot(contains('New')));

      result.unmount();
    });
  });
}
