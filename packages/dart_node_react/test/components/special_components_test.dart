/// Tests for special components (Fragment, StrictMode) and utilities
/// (cloneElement, isValidElement).
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  group('Special components', () {
    test('Fragment groups children without wrapper', () {
      final fragmentComponent = registerFunctionComponent(
        (props) => fragment(
          children: [
            pEl('First', props: {'data-testid': 'first'}),
            pEl('Second', props: {'data-testid': 'second'}),
          ],
        ),
      );

      final result = render(fc(fragmentComponent));

      expect(result.getByTestId('first').textContent, equals('First'));
      expect(result.getByTestId('second').textContent, equals('Second'));

      result.unmount();
    });

    test('StrictMode wraps children', () {
      final strictComponent = registerFunctionComponent(
        (props) => strictMode(
          child: pEl('Strict content', props: {'data-testid': 'content'}),
        ),
      );

      final result = render(fc(strictComponent));

      expect(
        result.getByTestId('content').textContent,
        equals('Strict content'),
      );

      result.unmount();
    });
  });

  group('cloneElement', () {
    test('clones element with new props', () {
      final original = pEl('Hello', props: {'className': 'original'});
      final cloned = cloneElement(original, {'className': 'cloned'});

      expect(isValidElement(cloned), isTrue);
    });

    test('clones element with new children', () {
      final original = div(children: [pEl('Original child')]);
      final cloned = cloneElement(original, null, [pEl('New child')]);

      expect(isValidElement(cloned), isTrue);
    });
  });

  group('isValidElement', () {
    test('returns true for valid elements', () {
      expect(isValidElement(div()), isTrue);
      expect(isValidElement(pEl('text')), isTrue);
      expect(isValidElement(button(text: 'Click')), isTrue);
    });

    test('returns true for function component elements', () {
      final myComponent = registerFunctionComponent((props) => pEl('Hello'));
      expect(isValidElement(fc(myComponent)), isTrue);
    });
  });
}
