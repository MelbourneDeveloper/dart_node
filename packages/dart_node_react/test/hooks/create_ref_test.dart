/// Tests for createRef functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart';
import 'package:test/test.dart';

void main() {
  test('creates a new ref each time', () {
    final ref1 = createRef<String>();
    final ref2 = createRef<String>();

    expect(ref1.current, isNull);
    expect(ref2.current, isNull);

    ref1.current = 'hello';
    expect(ref1.current, equals('hello'));
    expect(ref2.current, isNull);
  });
}
