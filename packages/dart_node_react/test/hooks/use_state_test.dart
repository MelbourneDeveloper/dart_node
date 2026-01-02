/// Tests for useState hook functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('initializes with the provided value', () {
    final counter = registerFunctionComponent((props) {
      final count = useState(0);
      return div(
        children: [
          pEl('Count: ${count.value}', props: {'data-testid': 'count'}),
        ],
      );
    });

    final result = render(fc(counter));
    final countEl = result.getByTestId('count');

    expect(countEl.textContent, equals('Count: 0'));
    result.unmount();
  });

  test('updates state when set is called', () {
    final counter = registerFunctionComponent((props) {
      final count = useState(0);
      return div(
        children: [
          pEl('Count: ${count.value}', props: {'data-testid': 'count'}),
          button(
            text: 'Increment',
            props: {'data-testid': 'increment'},
            onClick: () => count.set(count.value + 1),
          ),
        ],
      );
    });

    final result = render(fc(counter));
    final countEl = result.getByTestId('count');
    final buttonEl = result.getByTestId('increment');

    expect(countEl.textContent, equals('Count: 0'));

    fireClick(buttonEl);
    expect(result.getByTestId('count').textContent, equals('Count: 1'));

    fireClick(buttonEl);
    expect(result.getByTestId('count').textContent, equals('Count: 2'));

    result.unmount();
  });

  test('updates state with functional updater', () {
    final counter = registerFunctionComponent((props) {
      final count = useState(0);
      return div(
        children: [
          pEl('Count: ${count.value}', props: {'data-testid': 'count'}),
          button(
            text: 'Double',
            props: {'data-testid': 'double'},
            onClick: () => count.setWithUpdater((prev) => prev * 2 + 1),
          ),
        ],
      );
    });

    final result = render(fc(counter));
    final buttonEl = result.getByTestId('double');

    fireClick(buttonEl);
    expect(result.getByTestId('count').textContent, equals('Count: 1'));

    fireClick(buttonEl);
    expect(result.getByTestId('count').textContent, equals('Count: 3'));

    fireClick(buttonEl);
    expect(result.getByTestId('count').textContent, equals('Count: 7'));

    result.unmount();
  });

  test('handles multiple independent states', () {
    final multiState = registerFunctionComponent((props) {
      final count = useState(0);
      final name = useState('Alice');
      return div(
        children: [
          pEl('Count: ${count.value}', props: {'data-testid': 'count'}),
          pEl('Name: ${name.value}', props: {'data-testid': 'name'}),
          button(
            text: 'Inc',
            props: {'data-testid': 'inc'},
            onClick: () => count.set(count.value + 1),
          ),
          button(
            text: 'Toggle',
            props: {'data-testid': 'toggle'},
            onClick: () => name.set(name.value == 'Alice' ? 'Bob' : 'Alice'),
          ),
        ],
      );
    });

    final result = render(fc(multiState));

    expect(result.getByTestId('count').textContent, equals('Count: 0'));
    expect(result.getByTestId('name').textContent, equals('Name: Alice'));

    fireClick(result.getByTestId('inc'));
    expect(result.getByTestId('count').textContent, equals('Count: 1'));
    expect(result.getByTestId('name').textContent, equals('Name: Alice'));

    fireClick(result.getByTestId('toggle'));
    expect(result.getByTestId('count').textContent, equals('Count: 1'));
    expect(result.getByTestId('name').textContent, equals('Name: Bob'));

    result.unmount();
  });

  test('handles null values', () {
    final nullState = registerFunctionComponent((props) {
      final value = useState<String?>(null);
      return div(
        children: [
          pEl(value.value ?? 'No value', props: {'data-testid': 'value'}),
          button(
            text: 'Set',
            props: {'data-testid': 'set'},
            onClick: () => value.set('Hello'),
          ),
          button(
            text: 'Clear',
            props: {'data-testid': 'clear'},
            onClick: () => value.set(null),
          ),
        ],
      );
    });

    final result = render(fc(nullState));

    expect(result.getByTestId('value').textContent, equals('No value'));

    fireClick(result.getByTestId('set'));
    expect(result.getByTestId('value').textContent, equals('Hello'));

    fireClick(result.getByTestId('clear'));
    expect(result.getByTestId('value').textContent, equals('No value'));

    result.unmount();
  });

  test('handles complex object state via multiple state hooks', () {
    // Complex state is best managed with multiple primitive hooks
    // since JS interop doesn't preserve Dart Map/List types.
    final objectState = registerFunctionComponent((props) {
      final name = useState('Alice');
      final age = useState(25);
      return div(
        children: [
          pEl('Name: ${name.value}', props: {'data-testid': 'name'}),
          pEl('Age: ${age.value}', props: {'data-testid': 'age'}),
          button(
            text: 'Birthday',
            props: {'data-testid': 'birthday'},
            onClick: () => age.set(age.value + 1),
          ),
        ],
      );
    });

    final result = render(fc(objectState));

    expect(result.getByTestId('name').textContent, equals('Name: Alice'));
    expect(result.getByTestId('age').textContent, equals('Age: 25'));

    fireClick(result.getByTestId('birthday'));
    expect(result.getByTestId('age').textContent, equals('Age: 26'));

    result.unmount();
  });

  test('handles list state via string serialization', () {
    // List state works best when serialized to a primitive type
    // since JS interop doesn't preserve Dart List types.
    final listState = registerFunctionComponent((props) {
      // Store as comma-separated string
      final itemsStr = useState('Apple,Banana');
      return div(
        children: [
          pEl(
            'Items: ${itemsStr.value.split(",").join(", ")}',
            props: {'data-testid': 'items'},
          ),
          button(
            text: 'Add Cherry',
            props: {'data-testid': 'add'},
            onClick: () => itemsStr.set('${itemsStr.value},Cherry'),
          ),
          button(
            text: 'Remove First',
            props: {'data-testid': 'remove'},
            onClick: () {
              final parts = itemsStr.value.split(',');
              itemsStr.set(parts.skip(1).join(','));
            },
          ),
        ],
      );
    });

    final result = render(fc(listState));

    expect(
      result.getByTestId('items').textContent,
      equals('Items: Apple, Banana'),
    );

    fireClick(result.getByTestId('add'));
    expect(
      result.getByTestId('items').textContent,
      equals('Items: Apple, Banana, Cherry'),
    );

    fireClick(result.getByTestId('remove'));
    expect(
      result.getByTestId('items').textContent,
      equals('Items: Banana, Cherry'),
    );

    result.unmount();
  });
}
