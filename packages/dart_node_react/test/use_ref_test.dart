/// Tests for useRef and createRef.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('useRef maintains reference across renders', () {
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

  test('useRef stores mutable value without causing re-render', () {
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

  test('createRef creates a new ref each time', () {
    final ref1 = createRef<String>();
    final ref2 = createRef<String>();

    expect(ref1.current, isNull);
    expect(ref2.current, isNull);

    ref1.current = 'hello';
    expect(ref1.current, equals('hello'));
    expect(ref2.current, isNull);
  });

  test('useRef stores complex Dart objects correctly', () {
    final complexRefComponent = registerFunctionComponent((props) {
      final counterRef = useRef<_Counter>();
      final forceUpdate = useState(0);

      if (counterRef.current == null) {
        counterRef.current = _Counter();
      }

      return div(
        children: [
          pEl(
            'Count: ${counterRef.current!.value}',
            props: {'data-testid': 'count'},
          ),
          button(
            text: 'Increment',
            props: {'data-testid': 'increment'},
            onClick: () {
              counterRef.current!.increment();
              forceUpdate.set(forceUpdate.value + 1);
            },
          ),
        ],
      );
    });

    final result = render(fc(complexRefComponent));

    expect(result.getByTestId('count').textContent, equals('Count: 0'));

    fireClick(result.getByTestId('increment'));
    expect(result.getByTestId('count').textContent, equals('Count: 1'));

    fireClick(result.getByTestId('increment'));
    expect(result.getByTestId('count').textContent, equals('Count: 2'));

    fireClick(result.getByTestId('increment'));
    expect(result.getByTestId('count').textContent, equals('Count: 3'));

    result.unmount();
  });

  test('useRef preserves object identity across renders', () {
    _Counter? capturedCounter;

    final identityComponent = registerFunctionComponent((props) {
      final counterRef = useRef<_Counter>();
      final forceUpdate = useState(0);

      if (counterRef.current == null) {
        counterRef.current = _Counter();
      }

      capturedCounter = counterRef.current;

      return div(
        children: [
          pEl('Value: ${counterRef.current!.value}'),
          button(
            text: 'Re-render',
            props: {'data-testid': 'rerender'},
            onClick: () => forceUpdate.set(forceUpdate.value + 1),
          ),
        ],
      );
    });

    final result = render(fc(identityComponent));
    final firstCounter = capturedCounter;
    expect(firstCounter, isNotNull);

    fireClick(result.getByTestId('rerender'));
    expect(capturedCounter, same(firstCounter), reason: 'Object identity lost');

    fireClick(result.getByTestId('rerender'));
    expect(capturedCounter, same(firstCounter), reason: 'Object identity lost');

    result.unmount();
  });
}

final class _Counter {
  int value = 0;
  void increment() => value++;
}
