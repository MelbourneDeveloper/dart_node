/// Tests for Children utilities.
@TestOn('js')
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('Children.count works with null children', () {
    final count = Children.count(null);
    expect(count, equals(0));
  });

  test('Children.count counts single child', () {
    final element = pEl('Test');
    final count = Children.count(element);
    expect(count, equals(1));
  });

  test('Children.count counts array children', () {
    final children = [pEl('One'), pEl('Two'), pEl('Three')].toJS;
    final count = Children.count(children);
    expect(count, equals(3));
  });

  test('Children.toArray with null returns empty list', () {
    final arr = Children.toArray(null);
    expect(arr, isEmpty);
  });

  test('Children.toArray converts single child to list', () {
    final element = pEl('Test');
    final arr = Children.toArray(element);
    expect(arr, hasLength(1));
  });

  test('Children.toArray converts array to list', () {
    final children = [pEl('One'), pEl('Two')].toJS;
    final arr = Children.toArray(children);
    expect(arr, hasLength(2));
  });

  test('Children.map with null children returns null', () {
    final mapped = Children.map(null, (child, index) => child);
    expect(mapped, isNull);
  });

  test('Children.map transforms single child', () {
    final element = pEl('Test');
    final mapped = Children.map(
      element,
      (child, index) => cloneElement(child, {'data-index': index}),
    );
    expect(mapped, isNotNull);
    expect(mapped, hasLength(1));
  });

  test('Children.map transforms array children', () {
    final children = [pEl('One'), pEl('Two'), pEl('Three')].toJS;
    var callCount = 0;
    final mapped = Children.map(children, (child, index) {
      callCount++;
      return child;
    });
    expect(mapped, isNotNull);
    expect(mapped, hasLength(3));
    expect(callCount, equals(3));
  });

  test('Children.forEach with null children does nothing', () {
    var called = false;
    Children.forEach(null, (child, index) {
      called = true;
    });
    expect(called, isFalse);
  });

  test('Children.forEach iterates single child', () {
    final element = pEl('Test');
    var callCount = 0;
    Children.forEach(element, (child, index) {
      callCount++;
      expect(index, equals(0));
    });
    expect(callCount, equals(1));
  });

  test('Children.forEach iterates array children', () {
    final children = [pEl('One'), pEl('Two'), pEl('Three')].toJS;
    final indices = <int>[];
    Children.forEach(children, (child, index) {
      indices.add(index);
    });
    expect(indices, equals([0, 1, 2]));
  });

  test('Children.only returns single child', () {
    final element = pEl('Only child');
    final only = Children.only(element);
    expect(only, isNotNull);
  });

  test('Children.only throws for null', () {
    expect(() => Children.only(null), throwsA(anything));
  });

  test('Children.count works in component context', () {
    // Test that Children.count works when called from inside a component
    final wrapper = registerFunctionComponent((props) {
      // Just test the count utility, don't try to render children
      final count = Children.count(null);
      return pEl('Count: $count', props: {'data-testid': 'count'});
    });

    final result = render(fc(wrapper));
    expect(result.getByTestId('count').textContent, equals('Count: 0'));
    result.unmount();
  });

  test('Children utilities are chainable', () {
    final children = [pEl('One'), pEl('Two')].toJS;

    // Convert to array
    final arr = Children.toArray(children);
    expect(arr, hasLength(2));

    // Map the array back
    final mapped = Children.map(arr.toJS, (child, i) => child);
    expect(mapped, hasLength(2));

    // Count the result
    final count = Children.count(mapped?.toJS);
    expect(count, equals(2));
  });

  test('Children.map preserves element type', () {
    final element = div(child: pEl('Test'));
    final mapped = Children.map(element, (child, _) => child);

    expect(mapped, isNotNull);
    expect(mapped, hasLength(1));
    // The mapped element should still be a ReactElement
    expect(mapped?.first, isA<ReactElement>());
  });
}
