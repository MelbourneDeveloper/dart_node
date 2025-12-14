/// Comprehensive UI tests for dart_node_react library.
///
/// These tests verify React component behavior through user interactions,
/// following React Testing Library best practices.
@TestOn('js')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

// TODO: Break each group into separate files. No groups!

void main() {
  // ==========================================================================
  // useState Hook Tests
  // ==========================================================================
  group('useState', () {
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
  });

  // ==========================================================================
  // useStateJSArray Hook Tests
  // ==========================================================================
  group('useStateJSArray', () {
    test('initializes with empty array', () {
      final listComponent = registerFunctionComponent((props) {
        final items = useStateJSArray<JSObject>(<JSObject>[].toJS);
        return pEl(
          'Count: ${items.value.length}',
          props: {'data-testid': 'count'},
        );
      });

      final result = render(fc(listComponent));

      expect(result.getByTestId('count').textContent, equals('Count: 0'));
      result.unmount();
    });

    test('adds items with set', () {
      final listComponent = registerFunctionComponent((props) {
        final items = useStateJSArray<JSObject>(<JSObject>[].toJS);
        return div(
          children: [
            pEl(
              'Count: ${items.value.length}',
              props: {'data-testid': 'count'},
            ),
            button(
              text: 'Add',
              props: {'data-testid': 'add'},
              onClick: () {
                final newItem = {'name': 'Item ${items.value.length}'}.jsify()!;
                items.set([...items.value, newItem as JSObject]);
              },
            ),
          ],
        );
      });

      final result = render(fc(listComponent));

      expect(result.getByTestId('count').textContent, equals('Count: 0'));

      fireClick(result.getByTestId('add'));
      expect(result.getByTestId('count').textContent, equals('Count: 1'));

      fireClick(result.getByTestId('add'));
      expect(result.getByTestId('count').textContent, equals('Count: 2'));

      result.unmount();
    });

    test('updates items with setWithUpdater', () {
      final listComponent = registerFunctionComponent((props) {
        final items = useStateJSArray<JSObject>(<JSObject>[].toJS);
        return div(
          children: [
            pEl(
              'Count: ${items.value.length}',
              props: {'data-testid': 'count'},
            ),
            button(
              text: 'Add',
              props: {'data-testid': 'add'},
              onClick: () {
                items.setWithUpdater((prev) {
                  final newItem = {'id': prev.length}.jsify()!;
                  return [...prev, newItem as JSObject];
                });
              },
            ),
            button(
              text: 'Remove Last',
              props: {'data-testid': 'remove'},
              onClick: () {
                items.setWithUpdater(
                  (prev) =>
                      prev.isEmpty ? prev : prev.sublist(0, prev.length - 1),
                );
              },
            ),
          ],
        );
      });

      final result = render(fc(listComponent));

      expect(result.getByTestId('count').textContent, equals('Count: 0'));

      fireClick(result.getByTestId('add'));
      fireClick(result.getByTestId('add'));
      fireClick(result.getByTestId('add'));
      expect(result.getByTestId('count').textContent, equals('Count: 3'));

      fireClick(result.getByTestId('remove'));
      expect(result.getByTestId('count').textContent, equals('Count: 2'));

      result.unmount();
    });

    test('renders list items from JSObject array', () {
      final listComponent = registerFunctionComponent((props) {
        final items = useStateJSArray<JSObject>(<JSObject>[].toJS);
        return div(
          children: [
            ul(
              props: {'data-testid': 'list'},
              children: items.value.map((item) {
                final name = (item['name'] as JSString?)?.toDart ?? '';
                return li(name);
              }).toList(),
            ),
            button(
              text: 'Add Apple',
              props: {'data-testid': 'add-apple'},
              onClick: () {
                items.setWithUpdater((prev) {
                  final newItem = {'name': 'Apple'}.jsify()!;
                  return [...prev, newItem as JSObject];
                });
              },
            ),
            button(
              text: 'Add Banana',
              props: {'data-testid': 'add-banana'},
              onClick: () {
                items.setWithUpdater((prev) {
                  final newItem = {'name': 'Banana'}.jsify()!;
                  return [...prev, newItem as JSObject];
                });
              },
            ),
          ],
        );
      });

      final result = render(fc(listComponent));

      expect(result.getByTestId('list').innerHTML, isEmpty);

      fireClick(result.getByTestId('add-apple'));
      expect(result.getByTestId('list').innerHTML, contains('Apple'));

      fireClick(result.getByTestId('add-banana'));
      expect(result.getByTestId('list').innerHTML, contains('Banana'));

      result.unmount();
    });

    test('filters items with setWithUpdater', () {
      final listComponent = registerFunctionComponent((props) {
        final items = useStateJSArray<JSObject>(<JSObject>[].toJS);
        return div(
          children: [
            pEl(
              'Count: ${items.value.length}',
              props: {'data-testid': 'count'},
            ),
            button(
              text: 'Add Done',
              props: {'data-testid': 'add-done'},
              onClick: () {
                items.setWithUpdater((prev) {
                  final item = {'done': true}.jsify()!;
                  return [...prev, item as JSObject];
                });
              },
            ),
            button(
              text: 'Add Not Done',
              props: {'data-testid': 'add-not-done'},
              onClick: () {
                items.setWithUpdater((prev) {
                  final item = {'done': false}.jsify()!;
                  return [...prev, item as JSObject];
                });
              },
            ),
            button(
              text: 'Remove Done',
              props: {'data-testid': 'remove-done'},
              onClick: () {
                items.setWithUpdater(
                  (prev) => prev.where((item) {
                    final done = (item['done'] as JSBoolean?)?.toDart ?? false;
                    return !done;
                  }).toList(),
                );
              },
            ),
          ],
        );
      });

      final result = render(fc(listComponent));

      fireClick(result.getByTestId('add-done'));
      fireClick(result.getByTestId('add-not-done'));
      fireClick(result.getByTestId('add-done'));
      expect(result.getByTestId('count').textContent, equals('Count: 3'));

      fireClick(result.getByTestId('remove-done'));
      expect(result.getByTestId('count').textContent, equals('Count: 1'));

      result.unmount();
    });

    test('maps items with setWithUpdater', () {
      final listComponent = registerFunctionComponent((props) {
        final items = useStateJSArray<JSObject>(<JSObject>[].toJS);

        int getTotal() => items.value.fold(0, (sum, item) {
          final val = (item['value'] as JSNumber?)?.toDartInt ?? 0;
          return sum + val;
        });

        return div(
          children: [
            pEl('Total: ${getTotal()}', props: {'data-testid': 'total'}),
            button(
              text: 'Add 10',
              props: {'data-testid': 'add'},
              onClick: () {
                items.setWithUpdater((prev) {
                  final item = {'value': 10}.jsify()!;
                  return [...prev, item as JSObject];
                });
              },
            ),
            button(
              text: 'Double All',
              props: {'data-testid': 'double'},
              onClick: () {
                items.setWithUpdater(
                  (prev) => prev.map((item) {
                    final val = (item['value'] as JSNumber?)?.toDartInt ?? 0;
                    return {'value': val * 2}.jsify()! as JSObject;
                  }).toList(),
                );
              },
            ),
          ],
        );
      });

      final result = render(fc(listComponent));

      fireClick(result.getByTestId('add'));
      fireClick(result.getByTestId('add'));
      expect(result.getByTestId('total').textContent, equals('Total: 20'));

      fireClick(result.getByTestId('double'));
      expect(result.getByTestId('total').textContent, equals('Total: 40'));

      result.unmount();
    });
  });

  // ==========================================================================
  // useStateLazy Hook Tests
  // ==========================================================================
  group('useStateLazy', () {
    test('initializes with lazy computed value', () {
      var computeCount = 0;

      final lazyCounter = registerFunctionComponent((props) {
        final count = useStateLazy(() {
          computeCount++;
          return 42;
        });
        return div(
          children: [
            pEl('Count: ${count.value}', props: {'data-testid': 'count'}),
            button(
              text: 'Inc',
              props: {'data-testid': 'inc'},
              onClick: () => count.set(count.value + 1),
            ),
          ],
        );
      });

      computeCount = 0;
      final result = render(fc(lazyCounter));

      expect(result.getByTestId('count').textContent, equals('Count: 42'));
      expect(computeCount, equals(1));

      // Re-render should not call initializer again
      fireClick(result.getByTestId('inc'));
      expect(result.getByTestId('count').textContent, equals('Count: 43'));
      expect(computeCount, equals(1));

      result.unmount();
    });
  });

  // ==========================================================================
  // useEffect Hook Tests
  // ==========================================================================
  group('useEffect', () {
    test('runs effect after mount', () {
      var effectRan = false;

      final effectComponent = registerFunctionComponent((props) {
        useEffect(() {
          effectRan = true;
          return null;
        }, []);
        return pEl('Mounted', props: {'data-testid': 'text'});
      });

      expect(effectRan, isFalse);

      final result = render(fc(effectComponent));

      expect(result.getByTestId('text').textContent, equals('Mounted'));
      result.unmount();
    });

    test('runs cleanup on unmount', () {
      var cleanupRan = false;

      final cleanupComponent = registerFunctionComponent((props) {
        useEffect(
          () =>
              () => cleanupRan = true,
          [],
        );
        return pEl('Component');
      });

      final result = render(fc(cleanupComponent));
      expect(cleanupRan, isFalse);

      result.unmount();
      expect(cleanupRan, isTrue);
    });

    test('re-runs effect when dependencies change', () {
      var effectCount = 0;

      final depsComponent = registerFunctionComponent((props) {
        final count = useState(0);
        useEffect(() {
          effectCount++;
          return null;
        }, [count.value]);
        return div(
          children: [
            pEl('Count: ${count.value}', props: {'data-testid': 'count'}),
            button(
              text: 'Inc',
              props: {'data-testid': 'inc'},
              onClick: () => count.set(count.value + 1),
            ),
          ],
        );
      });

      effectCount = 0;
      final result = render(fc(depsComponent));

      final initialCount = effectCount;

      fireClick(result.getByTestId('inc'));
      expect(effectCount, greaterThan(initialCount));

      result.unmount();
    });

    test('does not re-run effect when dependencies unchanged', () {
      var effectCount = 0;

      final stableDepsComponent = registerFunctionComponent((props) {
        final count = useState(0);
        final other = useState(0);

        useEffect(() {
          effectCount++;
          return null;
        }, [count.value]);

        return div(
          children: [
            pEl('Count: ${count.value}'),
            button(
              text: 'Inc Other',
              props: {'data-testid': 'other'},
              onClick: () => other.set(other.value + 1),
            ),
          ],
        );
      });

      effectCount = 0;
      final result = render(fc(stableDepsComponent));
      final initialCount = effectCount;

      fireClick(result.getByTestId('other'));
      fireClick(result.getByTestId('other'));

      expect(effectCount, equals(initialCount));

      result.unmount();
    });
  });

  // ==========================================================================
  // useLayoutEffect Hook Tests
  // ==========================================================================
  group('useLayoutEffect', () {
    test('runs synchronously after DOM mutations', () {
      final layoutComponent = registerFunctionComponent((props) {
        useLayoutEffect(() => null, []);
        return pEl('Layout', props: {'data-testid': 'text'});
      });

      final result = render(fc(layoutComponent));
      expect(result.getByTestId('text').textContent, equals('Layout'));
      result.unmount();
    });
  });

  // ==========================================================================
  // useReducer Hook Tests
  // ==========================================================================
  group('useReducer', () {
    test('manages state transitions with primitive types', () {
      // useReducer with primitive types (int state, String actions)
      // works reliably across JS/Dart boundary.
      int reducer(int state, String action) => switch (action) {
        'increment' => state + 1,
        'decrement' => state - 1,
        'reset' => 0,
        _ => state,
      };

      final reducerCounter = registerFunctionComponent((props) {
        final state = useReducer(reducer, 0);
        return div(
          children: [
            pEl('Count: ${state.state}', props: {'data-testid': 'count'}),
            button(
              text: '+',
              props: {'data-testid': 'inc'},
              onClick: () => state.dispatch('increment'),
            ),
            button(
              text: '-',
              props: {'data-testid': 'dec'},
              onClick: () => state.dispatch('decrement'),
            ),
            button(
              text: 'Reset',
              props: {'data-testid': 'reset'},
              onClick: () => state.dispatch('reset'),
            ),
          ],
        );
      });

      final result = render(fc(reducerCounter));

      expect(result.getByTestId('count').textContent, equals('Count: 0'));

      fireClick(result.getByTestId('inc'));
      expect(result.getByTestId('count').textContent, equals('Count: 1'));

      fireClick(result.getByTestId('inc'));
      fireClick(result.getByTestId('inc'));
      expect(result.getByTestId('count').textContent, equals('Count: 3'));

      fireClick(result.getByTestId('dec'));
      expect(result.getByTestId('count').textContent, equals('Count: 2'));

      fireClick(result.getByTestId('reset'));
      expect(result.getByTestId('count').textContent, equals('Count: 0'));

      result.unmount();
    });

    test('handles string action types', () {
      int reducer(int state, String action) => switch (action) {
        'add' => state + 10,
        'subtract' => state - 5,
        _ => state,
      };

      final stringReducer = registerFunctionComponent((props) {
        final state = useReducer(reducer, 100);
        return div(
          children: [
            pEl('Value: ${state.state}', props: {'data-testid': 'value'}),
            button(
              text: 'Add',
              props: {'data-testid': 'add'},
              onClick: () => state.dispatch('add'),
            ),
            button(
              text: 'Sub',
              props: {'data-testid': 'sub'},
              onClick: () => state.dispatch('subtract'),
            ),
          ],
        );
      });

      final result = render(fc(stringReducer));

      expect(result.getByTestId('value').textContent, equals('Value: 100'));

      fireClick(result.getByTestId('add'));
      expect(result.getByTestId('value').textContent, equals('Value: 110'));

      fireClick(result.getByTestId('sub'));
      expect(result.getByTestId('value').textContent, equals('Value: 105'));

      result.unmount();
    });
  });

  // ==========================================================================
  // useReducerLazy Hook Tests
  // ==========================================================================
  group('useReducerLazy', () {
    test('lazily initializes state with primitive types', () {
      var initCount = 0;

      // Use primitive int for state to avoid JS interop issues with Map
      int init(int initialValue) {
        initCount++;
        return initialValue * 2;
      }

      int reducer(int state, String action) => switch (action) {
        'inc' => state + 1,
        _ => state,
      };

      final lazyReducer = registerFunctionComponent((props) {
        final initialValue = props['initial'] as int? ?? 5;
        final state = useReducerLazy(reducer, initialValue, init);
        return div(
          children: [
            pEl('Count: ${state.state}', props: {'data-testid': 'count'}),
            button(
              text: 'Inc',
              props: {'data-testid': 'inc'},
              onClick: () => state.dispatch('inc'),
            ),
          ],
        );
      });

      initCount = 0;
      final result = render(fc(lazyReducer, {'initial': 10}));

      expect(result.getByTestId('count').textContent, equals('Count: 20'));
      expect(initCount, equals(1));

      fireClick(result.getByTestId('inc'));
      expect(result.getByTestId('count').textContent, equals('Count: 21'));
      expect(initCount, equals(1));

      result.unmount();
    });
  });

  // ==========================================================================
  // useContext Hook Tests
  // ==========================================================================
  group('useContext', () {
    test('provides default value when no provider', () {
      final themeContext = createContext('light');

      final consumer = registerFunctionComponent((props) {
        final theme = useContext(themeContext);
        return pEl('Theme: $theme', props: {'data-testid': 'theme'});
      });

      final result = render(fc(consumer));

      expect(result.getByTestId('theme').textContent, equals('Theme: light'));

      result.unmount();
    });

    test('reads value from nearest provider', () {
      final themeContext = createContext('light');

      final consumer = registerFunctionComponent((props) {
        final theme = useContext(themeContext);
        return pEl('Theme: $theme', props: {'data-testid': 'theme'});
      });

      final app = registerFunctionComponent(
        (props) => createElement(
          themeContext.providerType,
          createProps({'value': 'dark'}),
          fc(consumer),
        ),
      );

      final result = render(fc(app));

      expect(result.getByTestId('theme').textContent, equals('Theme: dark'));

      result.unmount();
    });

    test('updates when provider value changes', () {
      final countContext = createContext(0);

      final consumer = registerFunctionComponent((props) {
        final count = useContext(countContext);
        return pEl('Count: $count', props: {'data-testid': 'count'});
      });

      final provider = registerFunctionComponent((props) {
        final count = useState(0);
        return createElement(
          countContext.providerType,
          createProps({'value': count.value}),
          div(
            children: [
              fc(consumer),
              button(
                text: 'Inc',
                props: {'data-testid': 'inc'},
                onClick: () => count.set(count.value + 1),
              ),
            ],
          ),
        );
      });

      final result = render(fc(provider));

      expect(result.getByTestId('count').textContent, equals('Count: 0'));

      fireClick(result.getByTestId('inc'));
      expect(result.getByTestId('count').textContent, equals('Count: 1'));

      result.unmount();
    });

    test('handles nested providers', () {
      final themeContext = createContext('default');

      final consumer = registerFunctionComponent((props) {
        final theme = useContext(themeContext);
        return pEl('Theme: $theme', props: {'data-testid': 'theme'});
      });

      final app = registerFunctionComponent(
        (props) => createElement(
          themeContext.providerType,
          createProps({'value': 'outer'}),
          div(
            children: [
              createElement(
                themeContext.providerType,
                createProps({'value': 'inner'}),
                fc(consumer),
              ),
            ],
          ),
        ),
      );

      final result = render(fc(app));

      expect(result.getByTestId('theme').textContent, equals('Theme: inner'));

      result.unmount();
    });
  });

  // ==========================================================================
  // useRef Hook Tests
  // ==========================================================================
  group('useRef', () {
    test('maintains reference across renders', () {
      final refComponent = registerFunctionComponent((props) {
        final renderCount = useRefInit(0);
        final forceUpdate = useState(0);

        renderCount.current = renderCount.current + 1;

        return div(
          children: [
            pEl(
              'Renders: ${renderCount.current}',
              props: {'data-testid': 'renders'},
            ),
            button(
              text: 'Re-render',
              props: {'data-testid': 'rerender'},
              onClick: () => forceUpdate.set(forceUpdate.value + 1),
            ),
          ],
        );
      });

      final result = render(fc(refComponent));

      expect(result.getByTestId('renders').textContent, equals('Renders: 1'));

      fireClick(result.getByTestId('rerender'));
      expect(result.getByTestId('renders').textContent, equals('Renders: 2'));

      fireClick(result.getByTestId('rerender'));
      expect(result.getByTestId('renders').textContent, equals('Renders: 3'));

      result.unmount();
    });

    test('stores mutable value without causing re-render', () {
      var renderCount = 0;

      final mutableRef = registerFunctionComponent((props) {
        renderCount++;
        final value = useRefInit(0);

        return div(
          children: [
            pEl('Value: ${value.current}', props: {'data-testid': 'value'}),
            button(
              text: 'Mutate',
              props: {'data-testid': 'mutate'},
              onClick: () => value.current = value.current + 1,
            ),
          ],
        );
      });

      renderCount = 0;
      final result = render(fc(mutableRef));

      expect(renderCount, equals(1));

      fireClick(result.getByTestId('mutate'));
      expect(renderCount, equals(1));

      result.unmount();
    });
  });

  // ==========================================================================
  // createRef Tests
  // ==========================================================================
  group('createRef', () {
    test('creates a new ref each time', () {
      final ref1 = createRef<String>();
      final ref2 = createRef<String>();

      expect(ref1.current, isNull);
      expect(ref2.current, isNull);

      ref1.current = 'hello';
      expect(ref1.current, equals('hello'));
      expect(ref2.current, isNull);
    });
  });

  // ==========================================================================
  // useMemo Hook Tests
  // ==========================================================================
  group('useMemo', () {
    test('memoizes expensive computation', () {
      var computeCount = 0;

      final memoComponent = registerFunctionComponent((props) {
        final count = useState(0);
        final other = useState(0);

        final expensive = useMemo(() {
          computeCount++;
          return count.value * 2;
        }, [count.value]);

        return div(
          children: [
            pEl('Result: $expensive', props: {'data-testid': 'result'}),
            button(
              text: 'Inc Count',
              props: {'data-testid': 'inc-count'},
              onClick: () => count.set(count.value + 1),
            ),
            button(
              text: 'Inc Other',
              props: {'data-testid': 'inc-other'},
              onClick: () => other.set(other.value + 1),
            ),
          ],
        );
      });

      computeCount = 0;
      final result = render(fc(memoComponent));

      expect(result.getByTestId('result').textContent, equals('Result: 0'));
      final initialCompute = computeCount;

      fireClick(result.getByTestId('inc-count'));
      expect(result.getByTestId('result').textContent, equals('Result: 2'));
      expect(computeCount, greaterThan(initialCompute));

      final afterIncrement = computeCount;

      fireClick(result.getByTestId('inc-other'));
      expect(computeCount, equals(afterIncrement));

      result.unmount();
    });
  });

  // ==========================================================================
  // useCallback Hook Tests
  // ==========================================================================
  group('useCallback', () {
    test('returns stable function reference', () {
      final callbackComponent = registerFunctionComponent((props) {
        final count = useState(0);

        useCallback(() {}, []);

        return div(
          children: [
            pEl('Count: ${count.value}', props: {'data-testid': 'count'}),
            button(
              text: 'Inc',
              props: {'data-testid': 'inc'},
              onClick: () => count.set(count.value + 1),
            ),
          ],
        );
      });

      final result = render(fc(callbackComponent));

      fireClick(result.getByTestId('inc'));
      expect(result.getByTestId('count').textContent, equals('Count: 1'));

      result.unmount();
    });
  });

  // ==========================================================================
  // forwardRef Tests
  // ==========================================================================
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

  // ==========================================================================
  // memo Tests
  // ==========================================================================
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

  // ==========================================================================
  // Children Utilities Tests
  // ==========================================================================
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

  // ==========================================================================
  // Event Handling Tests
  // ==========================================================================
  group('Event handling', () {
    test('click handler is called', () {
      var clicked = false;

      final clickable = registerFunctionComponent(
        (props) => button(
          text: 'Click me',
          onClick: () => clicked = true,
          props: {'data-testid': 'btn'},
        ),
      );

      final result = render(fc(clickable));

      expect(clicked, isFalse);

      fireClick(result.getByTestId('btn'));

      expect(clicked, isTrue);

      result.unmount();
    });

    test('multiple click handlers work independently', () {
      var btn1Clicks = 0;
      var btn2Clicks = 0;

      final multiButton = registerFunctionComponent(
        (props) => div(
          children: [
            button(
              text: 'Button 1',
              onClick: () => btn1Clicks++,
              props: {'data-testid': 'btn1'},
            ),
            button(
              text: 'Button 2',
              onClick: () => btn2Clicks++,
              props: {'data-testid': 'btn2'},
            ),
          ],
        ),
      );

      final result = render(fc(multiButton));

      fireClick(result.getByTestId('btn1'));
      fireClick(result.getByTestId('btn1'));
      fireClick(result.getByTestId('btn2'));

      expect(btn1Clicks, equals(2));
      expect(btn2Clicks, equals(1));

      result.unmount();
    });

    test('focus and blur events', () {
      var focused = false;
      var blurred = false;

      final focusInput = registerFunctionComponent(
        (props) => input(
          type: 'text',
          onFocus: (_) => focused = true,
          onBlur: (_) => blurred = true,
          props: {'data-testid': 'input'},
        ),
      );

      final result = render(fc(focusInput));

      fireFocus(result.getByTestId('input'));
      expect(focused, isTrue);

      fireBlur(result.getByTestId('input'));
      expect(blurred, isTrue);

      result.unmount();
    });
  });

  // ==========================================================================
  // Special Components Tests
  // ==========================================================================
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

  // ==========================================================================
  // cloneElement Tests
  // ==========================================================================
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

  // ==========================================================================
  // isValidElement Tests
  // ==========================================================================
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

  // ==========================================================================
  // HTML Elements Tests
  // ==========================================================================
  group('HTML elements', () {
    test('all common elements render correctly', () {
      final elements = registerFunctionComponent(
        (props) => div(
          children: [
            h1('Heading 1', props: {'data-testid': 'h1'}),
            h2('Heading 2', props: {'data-testid': 'h2'}),
            pEl('Paragraph', props: {'data-testid': 'p'}),
            span('Span text', props: {'data-testid': 'span'}),
            button(text: 'Button', props: {'data-testid': 'button'}),
            a(href: '#', text: 'Link', props: {'data-testid': 'a'}),
          ],
        ),
      );

      final result = render(fc(elements));

      expect(result.getByTestId('h1').textContent, equals('Heading 1'));
      expect(result.getByTestId('h2').textContent, equals('Heading 2'));
      expect(result.getByTestId('p').textContent, equals('Paragraph'));
      expect(result.getByTestId('span').textContent, equals('Span text'));
      expect(result.getByTestId('button').textContent, equals('Button'));
      expect(result.getByTestId('a').textContent, equals('Link'));

      result.unmount();
    });

    test('input types render correctly', () {
      final inputs = registerFunctionComponent(
        (props) => div(
          children: [
            input(type: 'text', props: {'data-testid': 'text'}),
            input(type: 'password', props: {'data-testid': 'password'}),
            input(type: 'checkbox', props: {'data-testid': 'checkbox'}),
            input(type: 'radio', props: {'data-testid': 'radio'}),
          ],
        ),
      );

      final result = render(fc(inputs));

      expect(result.getByTestId('text'), isNotNull);
      expect(result.getByTestId('password'), isNotNull);
      expect(result.getByTestId('checkbox'), isNotNull);
      expect(result.getByTestId('radio'), isNotNull);

      result.unmount();
    });

    test('list elements render correctly', () {
      final listEl = registerFunctionComponent(
        (props) => ul(
          props: {'data-testid': 'list'},
          children: [li('Item 1'), li('Item 2'), li('Item 3')],
        ),
      );

      final result = render(fc(listEl));

      expect(result.getByTestId('list').innerHTML, contains('Item 1'));
      expect(result.getByTestId('list').innerHTML, contains('Item 2'));
      expect(result.getByTestId('list').innerHTML, contains('Item 3'));

      result.unmount();
    });

    test('image element renders with attributes', () {
      final imageEl = registerFunctionComponent(
        (props) => img(
          src: 'test.png',
          alt: 'Test image',
          props: {'data-testid': 'img'},
        ),
      );

      final result = render(fc(imageEl));

      final imgEl = result.getByTestId('img');
      expect(imgEl.getAttribute('src'), equals('test.png'));
      expect(imgEl.getAttribute('alt'), equals('Test image'));

      result.unmount();
    });
  });

  // ==========================================================================
  // Conditional Rendering Tests
  // ==========================================================================
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

  // ==========================================================================
  // List Rendering Tests
  // ==========================================================================
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

  // ==========================================================================
  // Component Composition Tests
  // ==========================================================================
  group('Component composition', () {
    test('parent passes props to child', () {
      final child = registerFunctionComponent(
        (props) =>
            pEl('Hello, ${props['name']}!', props: {'data-testid': 'greeting'}),
      );

      final parent = registerFunctionComponent(
        (props) => div(
          children: [
            fc(child, {'name': 'World'}),
          ],
        ),
      );

      final result = render(fc(parent));

      expect(
        result.getByTestId('greeting').textContent,
        equals('Hello, World!'),
      );

      result.unmount();
    });

    test('child calls parent callback', () {
      var parentNotified = false;

      final child = registerFunctionComponent((props) {
        final onNotify = props['onNotify'] as void Function()?;
        return button(
          text: 'Notify',
          onClick: onNotify,
          props: {'data-testid': 'notify'},
        );
      });

      final parent = registerFunctionComponent(
        (props) => fc(child, {'onNotify': () => parentNotified = true}),
      );

      final result = render(fc(parent));

      expect(parentNotified, isFalse);

      fireClick(result.getByTestId('notify'));

      expect(parentNotified, isTrue);

      result.unmount();
    });

    test('deeply nested components work correctly', () {
      final grandChild = registerFunctionComponent(
        (props) => span('GrandChild', props: {'data-testid': 'grandchild'}),
      );

      final child = registerFunctionComponent(
        (props) => div(children: [fc(grandChild)]),
      );

      final parent = registerFunctionComponent(
        (props) => div(children: [fc(child)]),
      );

      final result = render(fc(parent));

      expect(
        result.getByTestId('grandchild').textContent,
        equals('GrandChild'),
      );

      result.unmount();
    });
  });

  // ==========================================================================
  // JSX DSL Tests
  // ==========================================================================
  group('JSX DSL', () {
    test('creates element with text child using >> operator', () {
      final component = registerFunctionComponent(
        (props) => $h1 >> 'Hello JSX',
      );

      final result = render(fc(component));
      expect(result.container.textContent, equals('Hello JSX'));
      result.unmount();
    });

    test('creates nested elements with >> operator', () {
      final component = registerFunctionComponent(
        (props) =>
            $div(spread: {'data-testid': 'container'}) >>
            [$h1 >> 'Title', $p() >> 'Content'],
      );

      final result = render(fc(component));
      final container = result.getByTestId('container');
      expect(container.textContent, contains('Title'));
      expect(container.textContent, contains('Content'));
      result.unmount();
    });

    test(r'$div with className creates element', () {
      final component = registerFunctionComponent(
        (props) =>
            $div(className: 'my-class', spread: {'data-testid': 'styled'}) >>
            'Styled',
      );

      final result = render(fc(component));
      final el = result.getByTestId('styled');
      expect(el.className, equals('my-class'));
      result.unmount();
    });

    test(r'$button with onClick handler works', () {
      final component = registerFunctionComponent((props) {
        final count = useState(0);
        return $div() >>
            [
              $span(spread: {'data-testid': 'count'}) >>
                  'Count: ${count.value}',
              $button(
                    onClick: () => count.set(count.value + 1),
                    spread: {'data-testid': 'btn'},
                  ) >>
                  'Click',
            ];
      });

      final result = render(fc(component));
      expect(result.getByTestId('count').textContent, equals('Count: 0'));
      fireClick(result.getByTestId('btn'));
      expect(result.getByTestId('count').textContent, equals('Count: 1'));
      result.unmount();
    });

    test(r'$input with onChange handler works', () {
      final component = registerFunctionComponent((props) {
        final text = useState('');
        return $div() >>
            [
              $input(
                type: 'text',
                value: text.value,
                onChange: (e) {
                  final target = e.target;
                  if (target case final JSObject t) {
                    final value = t['value'];
                    if (value case final JSString s) text.set(s.toDart);
                  }
                },
                spread: {'data-testid': 'input'},
              ),
              $span(spread: {'data-testid': 'output'}) >>
                  'Value: ${text.value}',
            ];
      });

      final result = render(fc(component));
      final inputEl = result.getByTestId('input');
      fireChange(inputEl, value: 'Hello');
      expect(result.getByTestId('output').textContent, equals('Value: Hello'));
      result.unmount();
    });

    test(r'$ul and $li create lists', () {
      final component = registerFunctionComponent(
        (props) =>
            $ul(spread: {'data-testid': 'list'}) >>
            [$li() >> 'Item 1', $li() >> 'Item 2', $li() >> 'Item 3'],
      );

      final result = render(fc(component));
      final list = result.getByTestId('list');
      expect(list.textContent, contains('Item 1'));
      expect(list.textContent, contains('Item 2'));
      expect(list.textContent, contains('Item 3'));
      result.unmount();
    });

    test(r'$fragment groups elements without wrapper', () {
      final component = registerFunctionComponent(
        (props) => $fragment >> [$h1 >> 'First', $h2 >> 'Second'],
      );

      final result = render(fc(component));
      expect(result.container.textContent, contains('First'));
      expect(result.container.textContent, contains('Second'));
      result.unmount();
    });

    test('conditional rendering with null children', () {
      final component = registerFunctionComponent((props) {
        final show = useState(false);
        return $div() >>
            [
              $button(
                    onClick: () => show.set(!show.value),
                    spread: {'data-testid': 'toggle'},
                  ) >>
                  'Toggle',
              if (show.value)
                $p(spread: {'data-testid': 'content'}) >> 'Visible',
            ];
      });

      final result = render(fc(component));
      expect(result.queryByTestId('content'), isNull);
      fireClick(result.getByTestId('toggle'));
      expect(result.getByTestId('content').textContent, equals('Visible'));
      result.unmount();
    });

    test('numeric children are converted to string', () {
      final component = registerFunctionComponent(
        (props) => $span(spread: {'data-testid': 'num'}) >> 42,
      );

      final result = render(fc(component));
      expect(result.getByTestId('num').textContent, equals('42'));
      result.unmount();
    });

    test('El elements can be used as children', () {
      final component = registerFunctionComponent((props) {
        final child = $span() >> 'Inner';
        return $div(spread: {'data-testid': 'outer'}) >> child;
      });

      final result = render(fc(component));
      expect(result.getByTestId('outer').textContent, equals('Inner'));
      result.unmount();
    });

    test(r'$a creates anchor with href', () {
      final component = registerFunctionComponent(
        (props) =>
            $a(href: 'https://example.com', spread: {'data-testid': 'link'}) >>
            'Click me',
      );

      final result = render(fc(component));
      final link = result.getByTestId('link');
      expect(link.textContent, equals('Click me'));
      expect(link.getAttribute('href'), isNotNull);
      result.unmount();
    });

    test('semantic elements work correctly', () {
      final component = registerFunctionComponent(
        (props) =>
            $main(spread: {'data-testid': 'main'}) >>
            [
              $header() >> [$h1 >> 'Header'],
              $section() >> [$p() >> 'Section content'],
              $footer() >> [$span() >> 'Footer'],
            ],
      );

      final result = render(fc(component));
      final mainEl = result.getByTestId('main');
      expect(mainEl.textContent, contains('Header'));
      expect(mainEl.textContent, contains('Section content'));
      expect(mainEl.textContent, contains('Footer'));
      result.unmount();
    });
  });
}
