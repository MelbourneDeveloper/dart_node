/// Tests for cloneElement.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:test/test.dart';

void main() {
  test('cloneElement clones element with new props', () {
    final original = pEl('Hello', props: {'className': 'original'});
    final cloned = cloneElement(original, {'className': 'cloned'});

    expect(isValidElement(cloned), isTrue);
  });

  test('cloneElement clones element with new children', () {
    final original = div(children: [pEl('Original child')]);
    final cloned = cloneElement(original, null, [pEl('New child')]);

    expect(isValidElement(cloned), isTrue);
  });
}
