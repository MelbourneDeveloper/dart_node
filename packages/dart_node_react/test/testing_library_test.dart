/// Full app UI tests for the web counter app.
///
/// Tests the complete user flow using the real components.
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'package:dart_node_react/src/testing_library.dart';
import 'package:statecore_demo/state/counter_state.dart';
import 'package:statecore_demo/web/counter_app.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Counter App - Full Flow', () {
    test('renders with initial state', () {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      expect(result.container.textContent, contains('Statecore Counter'));
      expect(result.container.textContent, contains('0'));
      expect(result.container.textContent, contains('History: 1 entries'));

      result.unmount();
    });

    test('increment button increases count', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      // Find and click the increment button (+1)
      final buttons = result.container.querySelectorAll('button');
      final incrementBtn = _findButtonWithText(buttons, '+1');
      fireClick(incrementBtn!);

      await waitForText(result, '1');
      expect(result.container.textContent, contains('History: 2 entries'));

      result.unmount();
    });

    test('decrement button decreases count', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      // First increment
      final buttons = result.container.querySelectorAll('button');
      fireClick(_findButtonWithText(buttons, '+1')!);
      await waitForText(result, '1');

      // Then decrement
      fireClick(_findButtonWithText(buttons, '-1')!);
      await waitForText(result, '0');
      expect(result.container.textContent, contains('History: 3 entries'));

      result.unmount();
    });

    test('step selector changes increment amount', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      // Change step to 5
      final select = result.container.querySelector('select');
      fireChange(select!, value: '5');

      // Now increment should add 5
      final buttons = result.container.querySelectorAll('button');
      fireClick(_findButtonWithText(buttons, '+5')!);

      await waitForText(result, '5');

      result.unmount();
    });

    test('undo reverts last action', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      // Increment twice
      final buttons = result.container.querySelectorAll('button');
      fireClick(_findButtonWithText(buttons, '+1')!);
      await waitForText(result, '1');
      fireClick(_findButtonWithText(buttons, '+1')!);
      await waitForText(result, '2');

      // Undo
      fireClick(_findButtonWithText(buttons, 'Undo')!);
      await waitForText(result, '1');

      result.unmount();
    });

    test('reset returns to initial state', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      // Increment several times
      final buttons = result.container.querySelectorAll('button');
      for (var i = 0; i < 5; i++) {
        fireClick(_findButtonWithText(buttons, '+1')!);
      }
      await waitForText(result, '5');

      // Reset
      fireClick(_findButtonWithText(buttons, 'Reset')!);
      await waitForText(result, '0');
      expect(result.container.textContent, contains('History: 1 entries'));

      result.unmount();
    });

    test('stats update correctly', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      final buttons = result.container.querySelectorAll('button');

      // Go to 3
      for (var i = 0; i < 3; i++) {
        fireClick(_findButtonWithText(buttons, '+1')!);
      }
      await waitForText(result, '3');

      // Go to -1
      for (var i = 0; i < 4; i++) {
        fireClick(_findButtonWithText(buttons, '-1')!);
      }
      await waitForText(result, '-1');

      // Stats should show min: -1, max: 3
      expect(result.container.textContent, contains('Min: -1'));
      expect(result.container.textContent, contains('Max: 3'));

      result.unmount();
    });

    test('complete user flow', () async {
      final store = createCounterStore();
      final result = render(counterApp(store: store));

      final buttons = result.container.querySelectorAll('button');

      // 1. Increment a few times
      fireClick(_findButtonWithText(buttons, '+1')!);
      fireClick(_findButtonWithText(buttons, '+1')!);
      await waitForText(result, '2');

      // 2. Change step to 10
      final select = result.container.querySelector('select');
      fireChange(select!, value: '10');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 3. Increment by 10
      fireClick(_findButtonWithText(buttons, '+10')!);
      await waitForText(result, '12');

      // 4. Undo back to 2
      fireClick(_findButtonWithText(buttons, 'Undo')!);
      await waitForText(result, '2');

      // 5. Decrement by 10
      fireClick(_findButtonWithText(buttons, '-10')!);
      await waitForText(result, '-8');

      // 6. Reset
      fireClick(_findButtonWithText(buttons, 'Reset')!);
      await waitForText(result, '0');

      expect(result.container.textContent, contains('History: 1 entries'));

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
      state = counterReducer(state, incrementAction());
      expect(state.count, 1);
      expect(state.history, [0, 1]);
    });

    test('decrement action subtracts step from count', () {
      var state = initialState();
      state = counterReducer(state, decrementAction());
      expect(state.count, -1);
    });

    test('setStep changes the step value', () {
      var state = initialState();
      state = counterReducer(state, setStepAction(5));
      expect(state.step, 5);
      state = counterReducer(state, incrementAction());
      expect(state.count, 5);
    });

    test('undo reverts to previous state', () {
      var state = initialState();
      state = counterReducer(state, incrementAction());
      state = counterReducer(state, incrementAction());
      expect(state.count, 2);
      state = counterReducer(state, undoAction());
      expect(state.count, 1);
    });

    test('reset returns to initial state', () {
      var state = initialState();
      state = counterReducer(state, incrementAction());
      state = counterReducer(state, incrementAction());
      state = counterReducer(state, resetAction());
      expect(state.count, 0);
      expect(state.history, [0]);
    });

    test('selectCanUndo returns false for initial state', () {
      final state = initialState();
      expect(selectCanUndo(state), false);
    });

    test('selectCanUndo returns true after actions', () {
      var state = initialState();
      state = counterReducer(state, incrementAction());
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

/// Find a button element containing the given text
DomNode? _findButtonWithText(List<DomNode> buttons, String text) {
  for (final btn in buttons) {
    if (btn.textContent.contains(text)) {
      return btn;
    }
  }
  return null;
}
