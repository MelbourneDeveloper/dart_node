/// Tests for dart_node_react library.
///
/// Note: These tests require a JavaScript runtime with React loaded.
/// They are designed to be run in a browser or Node.js environment
/// with React available globally.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart';
import 'package:test/test.dart';

void main() {
  group('ReactElement', () {
    test('createElement creates a valid element', () {
      final element = div();
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('div with text creates element', () {
      final element = pEl('Hello World');
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('div with children creates element', () {
      final element = div(children: [pEl('Child 1'), pEl('Child 2')]);
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('nested elements work correctly', () {
      final element = div(
        children: [
          header(children: [h1('Title')]),
          mainEl(children: [pEl('Content')]),
          footer(children: [pEl('Footer')]),
        ],
      );
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });
  });

  group('HTML Elements', () {
    test('h1 creates heading element', () {
      final element = h1('Heading');
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('h2 creates heading element', () {
      final element = h2('Sub-heading');
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('button creates button element', () {
      final element = button(text: 'Click me');
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('button with onClick handler', () {
      final element = button(text: 'Click', onClick: () {});
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('input creates input element', () {
      final element = input(type: 'text', placeholder: 'Enter text');
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('input with onChange handler', () {
      final element = input(
        type: 'text',
        onChange: (event) {
          // Handler receives SyntheticEvent
          expect(event, isNotNull);
        },
      );
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('img creates image element', () {
      final element = img(src: 'https://example.com/image.png', alt: 'Image');
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('a creates anchor element', () {
      final element = a(href: 'https://example.com', text: 'Link');
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('ul with li children', () {
      final element = ul(children: [li('Item 1'), li('Item 2'), li('Item 3')]);
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('span creates span element', () {
      final element = span('Text');
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });
  });

  group('Special Components', () {
    test('fragment creates fragment element', () {
      final element = fragment(children: [pEl('Child 1'), pEl('Child 2')]);
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('strictMode creates strict mode wrapper', () {
      final element = strictMode(child: div(children: [pEl('Content')]));
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });
  });

  group('Function Components', () {
    test('registerFunctionComponent creates component', () {
      final myComponent = registerFunctionComponent((props) {
        final name = props['name'] as String? ?? 'World';
        return pEl('Hello $name!');
      });
      expect(myComponent, isNotNull);
    });

    test('fc creates element from component', () {
      final myComponent = registerFunctionComponent((props) {
        final name = props['name'] as String? ?? 'World';
        return pEl('Hello $name!');
      });

      final element = fc(myComponent, {'name': 'Dart'});
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });

    test('fc with children', () {
      final wrapper = registerFunctionComponent(
        (props) => div(children: props['children'] as List<ReactElement>?),
      );

      final element = fc(wrapper, null, [pEl('Child content')]);
      expect(element, isNotNull);
      expect(isValidElement(element), isTrue);
    });
  });

  group('cloneElement', () {
    test('cloneElement clones element', () {
      final original = pEl('Original');
      final cloned = cloneElement(original);
      expect(cloned, isNotNull);
      expect(isValidElement(cloned), isTrue);
    });

    test('cloneElement with new props', () {
      final original = div(className: 'original');
      final cloned = cloneElement(original, {'className': 'cloned'});
      expect(cloned, isNotNull);
      expect(isValidElement(cloned), isTrue);
    });
  });

  group('Context', () {
    test('createContext creates context', () {
      final context = createContext('default');
      expect(context, isNotNull);
      expect(context.defaultValue, equals('default'));
    });

    test('context has providerType', () {
      final context = createContext<String>('default');
      expect(context.providerType, isNotNull);
    });
  });

  group('Ref', () {
    test('createRef creates ref', () {
      final ref = createRef<String>();
      expect(ref, isNotNull);
      expect(ref.current, isNull);
    });

    test('ref current can be set', () {
      final ref = createRef<String>()..current = 'value';
      expect(ref.current, equals('value'));
    });
  });

  group('forwardRef', () {
    test('forwardRef2 creates component', () {
      final component = forwardRef2(
        (props, ref) => div(children: [pEl('Forwarded')]),
      );
      expect(component, isNotNull);
    });
  });

  group('memo', () {
    test('memo2 creates memoized component', () {
      final component = registerFunctionComponent((props) => pEl('Memoized'));

      final memoized = memo2(component);
      expect(memoized, isNotNull);
    });

    test('memo2 with custom comparison', () {
      final component = registerFunctionComponent(
        (props) => pEl('Value: ${props['value']}'),
      );

      final memoized = memo2(
        component,
        arePropsEqual: (prev, next) => prev['id'] == next['id'],
      );
      expect(memoized, isNotNull);
    });
  });
}
