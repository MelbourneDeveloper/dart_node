/// Tests for component utilities (forwardRef, memo, Children).
@TestOn('js')
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  group('forwardRef2', () {
    test('forwards ref to child component', () {
      final fancyInput = forwardRef2(
        (props, ref) => input(
          type: 'text',
          placeholder: props['placeholder'] as String? ?? '',
          props: {'ref': ref, 'data-testid': 'fancy-input'},
        ),
      );

      final result = render(
        createElement(fancyInput, createProps({'placeholder': 'Enter text'})),
      );

      final inputEl = result.getByTestId('fancy-input');
      expect(inputEl.getAttribute('placeholder'), equals('Enter text'));

      result.unmount();
    });
  });

  group('memo2', () {
    test('prevents unnecessary re-renders', () {
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

    test('re-renders when props change with custom comparison', () {
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
  });

  group('Children utilities', () {
    test('Children.count works with null children', () {
      final wrapper = registerFunctionComponent((props) {
        final children = props['children'] as JSAny?;
        final count = Children.count(children);
        return pEl('Count: $count', props: {'data-testid': 'count'});
      });

      // Pass no children - count should be 0
      final result = render(fc(wrapper));

      expect(result.getByTestId('count').textContent, equals('Count: 0'));

      result.unmount();
    });

    test('Children utilities are available for import', () {
      // Simple test to verify Children utilities compile and are accessible
      // The count function exists and works with null
      final count = Children.count(null);
      expect(count, equals(0));

      // toArray with null returns empty list
      final arr = Children.toArray(null);
      expect(arr, isEmpty);
    });
  });
}
