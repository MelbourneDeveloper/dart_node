/// Full app UI tests for the web counter app.
///
/// Tests verify actual UI interactions - clicking buttons, not dispatching.
///
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'package:dart_node_react/src/testing_library.dart';
import 'package:statecore_demo/state/counter_state.dart';
import 'package:statecore_demo/web/counter_app.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

DomNode _getIncrementBtn(TestRenderResult result) =>
    result.container.querySelector('.primary')!;

DomNode _getDecrementBtn(TestRenderResult result) => result.container
    .querySelectorAll('.controls .btn')
    .firstWhere((b) => !b.className.contains('primary'));

DomNode _getUndoBtn(TestRenderResult result) => result.container
    .querySelectorAll('.actions .btn')
    .firstWhere((b) => !b.className.contains('danger'));

DomNode _getResetBtn(TestRenderResult result) =>
    result.container.querySelector('.danger')!;

void main() {
  test('renders with initial state', () {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    expect(result.container.textContent, contains('Statecore Counter'));
    expect(result.container.querySelector('.count')!.textContent, '0');
    expect(result.container.textContent, contains('History: 1 entries'));
    expect(result.container.textContent, contains('+1'));
    expect(result.container.textContent, contains('-1'));
    expect(result.container.textContent, contains('Undo'));
    expect(result.container.textContent, contains('Reset'));
    expect(isDisabled(_getUndoBtn(result)), isTrue);

    result.unmount();
  });

  test('click increment once', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    expect(result.container.querySelector('.count')!.textContent, '0');

    fireClick(_getIncrementBtn(result));

    await waitForText(result, 'History: 2 entries');
    expect(result.container.querySelector('.count')!.textContent, '1');
    expect(store.getState().count, 1);
    expect(isDisabled(_getUndoBtn(result)), isFalse);

    result.unmount();
  });

  test('click increment multiple times', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 2 entries');
    expect(result.container.querySelector('.count')!.textContent, '1');

    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 3 entries');
    expect(result.container.querySelector('.count')!.textContent, '2');

    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 4 entries');
    expect(result.container.querySelector('.count')!.textContent, '3');
    expect(store.getState().count, 3);

    result.unmount();
  });

  test('click decrement once', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    fireClick(_getDecrementBtn(result));

    await waitForText(result, 'History: 2 entries');
    expect(result.container.querySelector('.count')!.textContent, '-1');
    expect(store.getState().count, -1);

    result.unmount();
  });

  test('click decrement multiple times', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    fireClick(_getDecrementBtn(result));
    await waitForText(result, 'History: 2 entries');
    expect(result.container.querySelector('.count')!.textContent, '-1');

    fireClick(_getDecrementBtn(result));
    await waitForText(result, 'History: 3 entries');
    expect(result.container.querySelector('.count')!.textContent, '-2');

    fireClick(_getDecrementBtn(result));
    await waitForText(result, 'History: 4 entries');
    expect(result.container.querySelector('.count')!.textContent, '-3');
    expect(store.getState().count, -3);

    result.unmount();
  });

  test('increment then decrement via clicks', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 2 entries');
    expect(result.container.querySelector('.count')!.textContent, '1');

    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 3 entries');
    expect(result.container.querySelector('.count')!.textContent, '2');

    fireClick(_getDecrementBtn(result));
    await waitForText(result, 'History: 4 entries');
    expect(result.container.querySelector('.count')!.textContent, '1');
    expect(store.getState().count, 1);

    result.unmount();
  });

  test('click undo button reverses last action', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 2 entries');
    expect(result.container.querySelector('.count')!.textContent, '1');

    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 3 entries');
    expect(result.container.querySelector('.count')!.textContent, '2');

    fireClick(_getUndoBtn(result));
    await waitForText(result, 'History: 2 entries');
    expect(result.container.querySelector('.count')!.textContent, '1');
    expect(store.getState().count, 1);

    result.unmount();
  });

  test('click reset button restores initial state', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 2 entries');
    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 3 entries');
    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 4 entries');
    expect(result.container.querySelector('.count')!.textContent, '3');

    fireClick(_getResetBtn(result));

    await waitForText(result, 'History: 1 entries');
    expect(result.container.querySelector('.count')!.textContent, '0');
    expect(store.getState().count, 0);
    expect(isDisabled(_getUndoBtn(result)), isTrue);

    result.unmount();
  });

  test('step selector changes increment amount then increment', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    final select = result.container.querySelector('select')!;
    fireChange(select, value: '5');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(result.container.textContent, contains('+5'));
    expect(result.container.textContent, contains('-5'));

    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 2 entries');
    expect(result.container.querySelector('.count')!.textContent, '5');
    expect(store.getState().count, 5);

    result.unmount();
  });

  test('step selector changes decrement amount', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    final select = result.container.querySelector('select')!;
    fireChange(select, value: '10');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    fireClick(_getDecrementBtn(result));
    await waitForText(result, 'History: 2 entries');
    expect(result.container.querySelector('.count')!.textContent, '-10');
    expect(store.getState().count, -10);

    result.unmount();
  });

  test('full interaction flow: inc, inc, dec, undo, reset', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    // Start at 0
    expect(result.container.querySelector('.count')!.textContent, '0');
    expect(result.container.textContent, contains('History: 1 entries'));

    // Click increment -> 1
    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 2 entries');
    expect(result.container.querySelector('.count')!.textContent, '1');

    // Click increment -> 2
    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 3 entries');
    expect(result.container.querySelector('.count')!.textContent, '2');

    // Click decrement -> 1
    fireClick(_getDecrementBtn(result));
    await waitForText(result, 'History: 4 entries');
    expect(result.container.querySelector('.count')!.textContent, '1');

    // Click undo -> 2
    fireClick(_getUndoBtn(result));
    await waitForText(result, 'History: 3 entries');
    expect(result.container.querySelector('.count')!.textContent, '2');

    // Click reset -> 0
    fireClick(_getResetBtn(result));
    await waitForText(result, 'History: 1 entries');
    expect(result.container.querySelector('.count')!.textContent, '0');
    expect(store.getState().count, 0);

    result.unmount();
  });

  test('stats update correctly after multiple clicks', () async {
    final store = createCounterStore();
    final result = render(counterApp(store: store));

    // 0 -> 1 -> 2 -> 3 -> 2 -> 1 -> 0 -> -1
    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 2 entries');
    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 3 entries');
    fireClick(_getIncrementBtn(result));
    await waitForText(result, 'History: 4 entries');
    fireClick(_getDecrementBtn(result));
    await waitForText(result, 'History: 5 entries');
    fireClick(_getDecrementBtn(result));
    await waitForText(result, 'History: 6 entries');
    fireClick(_getDecrementBtn(result));
    await waitForText(result, 'History: 7 entries');
    fireClick(_getDecrementBtn(result));
    await waitForText(result, 'History: 8 entries');

    expect(result.container.querySelector('.count')!.textContent, '-1');
    expect(result.container.textContent, contains('Min: -1'));
    expect(result.container.textContent, contains('Max: 3'));
    expect(result.container.textContent, contains('Avg: 1.0'));

    result.unmount();
  });

  test(
    'undo disabled initially, enabled after click, disabled after reset',
    () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      expect(isDisabled(_getUndoBtn(result)), isTrue);

      fireClick(_getIncrementBtn(result));
      await waitForText(result, 'History: 2 entries');
      expect(isDisabled(_getUndoBtn(result)), isFalse);

      fireClick(_getResetBtn(result));
      await waitForText(result, 'History: 1 entries');
      expect(isDisabled(_getUndoBtn(result)), isTrue);

      result.unmount();
    },
  );
}
