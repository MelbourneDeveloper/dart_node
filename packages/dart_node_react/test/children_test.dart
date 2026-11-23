/// Tests for Children utilities.
@TestOn('js')
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
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
}
