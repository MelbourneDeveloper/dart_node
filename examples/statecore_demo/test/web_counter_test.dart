/// Full app UI tests for the web counter app.
///
/// Tests verify the UI renders correctly and button clicks trigger actions.
///
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'package:dart_node_react/src/testing_library.dart';
import 'package:statecore_demo/state/counter_state.dart';
import 'package:statecore_demo/web/counter_app.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Counter App - UI Interactions', () {
    test('renders with initial state', () {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      expect(result.container.textContent, contains('Statecore Counter'));
      expect(result.container.textContent, contains('0'));
      expect(result.container.textContent, contains('History: 1 entries'));
      expect(result.container.textContent, contains('+1'));
      expect(result.container.textContent, contains('-1'));
      expect(result.container.textContent, contains('Undo'));
      expect(result.container.textContent, contains('Reset'));

      result.unmount();
    });

    test('clicking increment button increases count', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      fireClick(result.container.querySelector('.primary')!);

      await waitForText(result, 'History: 2 entries');
      expect(result.container.textContent, contains('1'));
      expect(store.getState().count, 1);

      result.unmount();
    });

    test('clicking decrement button decreases count', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      final buttons = result.container.querySelectorAll('.controls .btn');
      final decrementBtn = buttons.firstWhere(
        (b) => !b.className.contains('primary'),
      );
      fireClick(decrementBtn);

      await waitForText(result, 'History: 2 entries');
      expect(store.getState().count, -1);

      result.unmount();
    });

    test('step selector changes increment amount', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      final select = result.container.querySelector('select')!;
      fireChange(select, value: '5');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(store.getState().step, 5);
      expect(result.container.textContent, contains('+5'));
      expect(result.container.textContent, contains('-5'));

      result.unmount();
    });

    test('Undo button is disabled initially', () {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      final undoBtn = result.container
          .querySelectorAll('.actions .btn')
          .firstWhere((b) => !b.className.contains('danger'));

      expect(isDisabled(undoBtn), isTrue);

      result.unmount();
    });

    test('Undo button becomes enabled after action', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      var undoBtn = result.container
          .querySelectorAll('.actions .btn')
          .firstWhere((b) => !b.className.contains('danger'));
      expect(isDisabled(undoBtn), isTrue);

      store.dispatch(const Increment());
      await waitForText(result, 'History: 2 entries');

      undoBtn = result.container
          .querySelectorAll('.actions .btn')
          .firstWhere((b) => !b.className.contains('danger'));
      expect(isDisabled(undoBtn), isFalse);

      result.unmount();
    });

    test('stats display correctly', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      // Build up history with multiple dispatches (batch, no waits between)
      store
        ..dispatch(const Increment())
        ..dispatch(const Increment())
        ..dispatch(const Increment())
        ..dispatch(const Decrement())
        ..dispatch(const Decrement())
        ..dispatch(const Decrement())
        ..dispatch(const Decrement());
      await waitForText(result, 'History: 8 entries');

      expect(result.container.textContent, contains('Min: -1'));
      expect(result.container.textContent, contains('Max: 3'));
      expect(result.container.textContent, contains('Avg: 1.0'));

      result.unmount();
    });

    test('increment updates count display', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      expect(result.container.querySelector('.count')!.textContent, '0');

      store.dispatch(const Increment());
      await waitForText(result, 'History: 2 entries');

      expect(result.container.querySelector('.count')!.textContent, '1');

      result.unmount();
    });

    test('decrement updates count display', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      store.dispatch(const Decrement());
      await waitForText(result, 'History: 2 entries');

      expect(result.container.querySelector('.count')!.textContent, '-1');

      result.unmount();
    });

    test('step change updates button text', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      store.dispatch(const SetStep(10));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(result.container.textContent, contains('+10'));
      expect(result.container.textContent, contains('-10'));

      result.unmount();
    });

    test('reset restores initial state', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      // Batch dispatches then wait once
      store
        ..dispatch(const Increment())
        ..dispatch(const Increment())
        ..dispatch(const Reset());
      await waitForText(result, 'History: 1 entries');

      expect(result.container.querySelector('.count')!.textContent, '0');

      result.unmount();
    });

    test('undo removes last history entry', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      // Batch dispatches then wait once
      store
        ..dispatch(const Increment())
        ..dispatch(const Increment())
        ..dispatch(const Undo());
      await waitForText(result, 'History: 2 entries');

      expect(result.container.querySelector('.count')!.textContent, '1');

      result.unmount();
    });

    test('step affects increment amount', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      // Batch dispatches then wait once
      store
        ..dispatch(const SetStep(5))
        ..dispatch(const Increment());
      await waitForText(result, 'History: 2 entries');

      expect(result.container.querySelector('.count')!.textContent, '5');

      result.unmount();
    });
  });

  group('Counter State - Unit Tests', () {
    test('initial state is correct', () {
      final state = initialState();
      expect(state.count, 0);
      expect(state.step, 1);
      expect(state.history, [0]);
    });

    test('increment action adds step to count', () {
      var state = initialState();
      state = counterReducer(state, const Increment());
      expect(state.count, 1);
      expect(state.history, [0, 1]);
    });

    test('decrement action subtracts step from count', () {
      var state = initialState();
      state = counterReducer(state, const Decrement());
      expect(state.count, -1);
    });

    test('setStep changes the step value', () {
      var state = initialState();
      state = counterReducer(state, const SetStep(5));
      expect(state.step, 5);
      state = counterReducer(state, const Increment());
      expect(state.count, 5);
    });

    test('undo reverts to previous state', () {
      var state = initialState();
      state = counterReducer(state, const Increment());
      state = counterReducer(state, const Increment());
      expect(state.count, 2);
      state = counterReducer(state, const Undo());
      expect(state.count, 1);
    });

    test('reset returns to initial state', () {
      var state = initialState();
      state = counterReducer(state, const Increment());
      state = counterReducer(state, const Increment());
      state = counterReducer(state, const Reset());
      expect(state.count, 0);
      expect(state.history, [0]);
    });

    test('selectCanUndo returns false for initial state', () {
      final state = initialState();
      expect(selectCanUndo(state), false);
    });

    test('selectCanUndo returns true after actions', () {
      var state = initialState();
      state = counterReducer(state, const Increment());
      expect(selectCanUndo(state), true);
    });

    test('selectHistoryStats calculates correctly', () {
      final state = (count: 5, step: 1, history: [0, 3, -2, 5]);
      final stats = selectHistoryStats(state);
      expect(stats.min, -2);
      expect(stats.max, 5);
      expect(stats.avg, 1.5);
    });
  });
}
