/// Full app UI tests for the web counter app.
///
/// Tests verify actual UI interactions - clicking buttons, not dispatching.
/// Each test verifies the ENTIRE UI tree after EVERY action.
///
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'package:dart_node_react/src/testing_library.dart';
import 'package:dart_node_statecore/dart_node_statecore.dart';
import 'package:statecore_demo/state/counter_state.dart';
import 'package:statecore_demo/web/counter_app.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

DomNode _getIncrementBtn(TestRenderResult r) =>
    r.container.querySelector('.primary')!;

DomNode _getDecrementBtn(TestRenderResult r) => r.container
    .querySelectorAll('.controls .btn')
    .firstWhere((b) => !b.className.contains('primary'));

DomNode _getUndoBtn(TestRenderResult r) => r.container
    .querySelectorAll('.actions .btn')
    .firstWhere((b) => !b.className.contains('danger'));

DomNode _getResetBtn(TestRenderResult r) =>
    r.container.querySelector('.danger')!;

DomNode _getSelect(TestRenderResult r) => r.container.querySelector('select')!;

/// Asserts the ENTIRE UI state matches expected values.
/// This is the key - verify EVERYTHING after EVERY action.
void _assertFullState(
  TestRenderResult r,
  Store<CounterState> store, {
  required int count,
  required int step,
  required int historyLength,
  required bool canUndo,
  required int min,
  required int max,
  required String avg,
}) {
  // Count display
  expect(
    r.container.querySelector('.count')!.textContent,
    '$count',
    reason: 'Count display should show $count',
  );

  // Store state matches UI
  expect(store.getState().count, count, reason: 'Store count mismatch');
  expect(store.getState().step, step, reason: 'Store step mismatch');
  expect(
    store.getState().history.length,
    historyLength,
    reason: 'Store history length mismatch',
  );

  // Button labels reflect step
  expect(
    r.container.textContent,
    contains('+$step'),
    reason: 'Increment button should show +$step',
  );
  expect(
    r.container.textContent,
    contains('-$step'),
    reason: 'Decrement button should show -$step',
  );

  // History count
  expect(
    r.container.textContent,
    contains('History: $historyLength entries'),
    reason: 'History should show $historyLength entries',
  );

  // Undo button state
  expect(
    isDisabled(_getUndoBtn(r)),
    !canUndo,
    reason: 'Undo button disabled=$canUndo mismatch',
  );

  // Stats
  expect(
    r.container.textContent,
    contains('Min: $min'),
    reason: 'Min stat should be $min',
  );
  expect(
    r.container.textContent,
    contains('Max: $max'),
    reason: 'Max stat should be $max',
  );
  expect(
    r.container.textContent,
    contains('Avg: $avg'),
    reason: 'Avg stat should be $avg',
  );

  // Title always present
  expect(
    r.container.textContent,
    contains('Statecore Counter'),
    reason: 'Title should always be present',
  );

  // All buttons present
  expect(_getIncrementBtn(r), isNotNull, reason: 'Increment btn missing');
  expect(_getDecrementBtn(r), isNotNull, reason: 'Decrement btn missing');
  expect(_getUndoBtn(r), isNotNull, reason: 'Undo btn missing');
  expect(_getResetBtn(r), isNotNull, reason: 'Reset btn missing');
  expect(_getSelect(r), isNotNull, reason: 'Step select missing');
}

void main() {
  test('app works without externally provided store', () async {
    // This tests the real app scenario where no store is passed
    final r = render(counterApp());

    // Initial state
    expect(r.container.querySelector('.count')!.textContent, '0');
    expect(r.container.textContent, contains('History: 1 entries'));

    // Click increment - this is where the bug manifests
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 2 entries');
    expect(
      r.container.querySelector('.count')!.textContent,
      '1',
      reason: 'Count should be 1 after increment',
    );

    // Click again to verify store persists across renders
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 3 entries');
    expect(
      r.container.querySelector('.count')!.textContent,
      '2',
      reason: 'Count should be 2 after second increment',
    );

    // Continue to verify the store state is truly preserved
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 4 entries');
    expect(
      r.container.querySelector('.count')!.textContent,
      '3',
      reason: 'Count should be 3 after third increment',
    );

    // Verify decrement works (proves store is functional)
    fireClick(_getDecrementBtn(r));
    await waitForText(r, 'History: 5 entries');
    expect(
      r.container.querySelector('.count')!.textContent,
      '2',
      reason: 'Count should be 2 after decrement',
    );

    // Verify undo works (proves history is preserved in store)
    fireClick(_getUndoBtn(r));
    await waitForText(r, 'History: 4 entries');
    expect(
      r.container.querySelector('.count')!.textContent,
      '3',
      reason: 'Count should be 3 after undo',
    );

    r.unmount();
  });

  test('full user journey: increment, decrement, step change, undo, reset',
      () async {
    final store = createCounterStore();
    final r = render(counterApp(store: store));

    // Initial state - verify EVERYTHING
    _assertFullState(
      r,
      store,
      count: 0,
      step: 1,
      historyLength: 1,
      canUndo: false,
      min: 0,
      max: 0,
      avg: '0.0',
    );

    // Action 1: Click increment -> 1
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 2 entries');
    _assertFullState(
      r,
      store,
      count: 1,
      step: 1,
      historyLength: 2,
      canUndo: true,
      min: 0,
      max: 1,
      avg: '0.5',
    );

    // Action 2: Click increment again -> 2
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 3 entries');
    _assertFullState(
      r,
      store,
      count: 2,
      step: 1,
      historyLength: 3,
      canUndo: true,
      min: 0,
      max: 2,
      avg: '1.0',
    );

    // Action 3: Click increment again -> 3
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 4 entries');
    _assertFullState(
      r,
      store,
      count: 3,
      step: 1,
      historyLength: 4,
      canUndo: true,
      min: 0,
      max: 3,
      avg: '1.5',
    );

    // Action 4: Click decrement -> 2
    fireClick(_getDecrementBtn(r));
    await waitForText(r, 'History: 5 entries');
    _assertFullState(
      r,
      store,
      count: 2,
      step: 1,
      historyLength: 5,
      canUndo: true,
      min: 0,
      max: 3,
      avg: '1.6',
    );

    // Action 5: Click undo -> 3
    fireClick(_getUndoBtn(r));
    await waitForText(r, 'History: 4 entries');
    _assertFullState(
      r,
      store,
      count: 3,
      step: 1,
      historyLength: 4,
      canUndo: true,
      min: 0,
      max: 3,
      avg: '1.5',
    );

    // Action 6: Click undo again -> 2
    fireClick(_getUndoBtn(r));
    await waitForText(r, 'History: 3 entries');
    _assertFullState(
      r,
      store,
      count: 2,
      step: 1,
      historyLength: 3,
      canUndo: true,
      min: 0,
      max: 2,
      avg: '1.0',
    );

    // Action 7: Click reset -> 0
    fireClick(_getResetBtn(r));
    await waitForText(r, 'History: 1 entries');
    _assertFullState(
      r,
      store,
      count: 0,
      step: 1,
      historyLength: 1,
      canUndo: false,
      min: 0,
      max: 0,
      avg: '0.0',
    );

    // Action 8: Change step to 5
    fireChange(_getSelect(r), value: '5');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _assertFullState(
      r,
      store,
      count: 0,
      step: 5,
      historyLength: 1,
      canUndo: false,
      min: 0,
      max: 0,
      avg: '0.0',
    );

    // Action 9: Click increment with step=5 -> 5
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 2 entries');
    _assertFullState(
      r,
      store,
      count: 5,
      step: 5,
      historyLength: 2,
      canUndo: true,
      min: 0,
      max: 5,
      avg: '2.5',
    );

    // Action 10: Click increment again -> 10
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 3 entries');
    _assertFullState(
      r,
      store,
      count: 10,
      step: 5,
      historyLength: 3,
      canUndo: true,
      min: 0,
      max: 10,
      avg: '5.0',
    );

    // Action 11: Click decrement -> 5
    fireClick(_getDecrementBtn(r));
    await waitForText(r, 'History: 4 entries');
    _assertFullState(
      r,
      store,
      count: 5,
      step: 5,
      historyLength: 4,
      canUndo: true,
      min: 0,
      max: 10,
      avg: '5.0',
    );

    // Action 12: Change step to 10
    fireChange(_getSelect(r), value: '10');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _assertFullState(
      r,
      store,
      count: 5,
      step: 10,
      historyLength: 4,
      canUndo: true,
      min: 0,
      max: 10,
      avg: '5.0',
    );

    // Action 13: Click decrement with step=10 -> -5
    fireClick(_getDecrementBtn(r));
    await waitForText(r, 'History: 5 entries');
    _assertFullState(
      r,
      store,
      count: -5,
      step: 10,
      historyLength: 5,
      canUndo: true,
      min: -5,
      max: 10,
      avg: '3.0',
    );

    // Action 14: Click undo -> 5
    fireClick(_getUndoBtn(r));
    await waitForText(r, 'History: 4 entries');
    _assertFullState(
      r,
      store,
      count: 5,
      step: 10,
      historyLength: 4,
      canUndo: true,
      min: 0,
      max: 10,
      avg: '5.0',
    );

    // Action 15: Reset everything
    fireClick(_getResetBtn(r));
    await waitForText(r, 'History: 1 entries');
    _assertFullState(
      r,
      store,
      count: 0,
      step: 10,
      historyLength: 1,
      canUndo: false,
      min: 0,
      max: 0,
      avg: '0.0',
    );

    r.unmount();
  });

  test('decrement into negative territory', () async {
    final store = createCounterStore();
    final r = render(counterApp(store: store));

    _assertFullState(
      r,
      store,
      count: 0,
      step: 1,
      historyLength: 1,
      canUndo: false,
      min: 0,
      max: 0,
      avg: '0.0',
    );

    // Dec -> -1
    fireClick(_getDecrementBtn(r));
    await waitForText(r, 'History: 2 entries');
    _assertFullState(
      r,
      store,
      count: -1,
      step: 1,
      historyLength: 2,
      canUndo: true,
      min: -1,
      max: 0,
      avg: '-0.5',
    );

    // Dec -> -2
    fireClick(_getDecrementBtn(r));
    await waitForText(r, 'History: 3 entries');
    _assertFullState(
      r,
      store,
      count: -2,
      step: 1,
      historyLength: 3,
      canUndo: true,
      min: -2,
      max: 0,
      avg: '-1.0',
    );

    // Dec -> -3
    fireClick(_getDecrementBtn(r));
    await waitForText(r, 'History: 4 entries');
    _assertFullState(
      r,
      store,
      count: -3,
      step: 1,
      historyLength: 4,
      canUndo: true,
      min: -3,
      max: 0,
      avg: '-1.5',
    );

    // Inc -> -2
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 5 entries');
    _assertFullState(
      r,
      store,
      count: -2,
      step: 1,
      historyLength: 5,
      canUndo: true,
      min: -3,
      max: 0,
      avg: '-1.6',
    );

    // Undo -> -3
    fireClick(_getUndoBtn(r));
    await waitForText(r, 'History: 4 entries');
    _assertFullState(
      r,
      store,
      count: -3,
      step: 1,
      historyLength: 4,
      canUndo: true,
      min: -3,
      max: 0,
      avg: '-1.5',
    );

    r.unmount();
  });

  test('undo all the way back to start', () async {
    final store = createCounterStore();
    final r = render(counterApp(store: store));

    // Inc 3 times
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 2 entries');
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 3 entries');
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 4 entries');

    _assertFullState(
      r,
      store,
      count: 3,
      step: 1,
      historyLength: 4,
      canUndo: true,
      min: 0,
      max: 3,
      avg: '1.5',
    );

    // Undo -> 2
    fireClick(_getUndoBtn(r));
    await waitForText(r, 'History: 3 entries');
    _assertFullState(
      r,
      store,
      count: 2,
      step: 1,
      historyLength: 3,
      canUndo: true,
      min: 0,
      max: 2,
      avg: '1.0',
    );

    // Undo -> 1
    fireClick(_getUndoBtn(r));
    await waitForText(r, 'History: 2 entries');
    _assertFullState(
      r,
      store,
      count: 1,
      step: 1,
      historyLength: 2,
      canUndo: true,
      min: 0,
      max: 1,
      avg: '0.5',
    );

    // Undo -> 0, undo should now be disabled
    fireClick(_getUndoBtn(r));
    await waitForText(r, 'History: 1 entries');
    _assertFullState(
      r,
      store,
      count: 0,
      step: 1,
      historyLength: 1,
      canUndo: false,
      min: 0,
      max: 0,
      avg: '0.0',
    );

    r.unmount();
  });

  test('rapid successive clicks all register', () async {
    final store = createCounterStore();
    final r = render(counterApp(store: store));

    // 10 rapid increments
    for (var i = 1; i <= 10; i++) {
      fireClick(_getIncrementBtn(r));
      await waitForText(r, 'History: ${i + 1} entries');
      expect(
        r.container.querySelector('.count')!.textContent,
        '$i',
        reason: 'After $i clicks, count should be $i',
      );
      expect(store.getState().count, i);
    }

    _assertFullState(
      r,
      store,
      count: 10,
      step: 1,
      historyLength: 11,
      canUndo: true,
      min: 0,
      max: 10,
      avg: '5.0',
    );

    // 5 rapid decrements
    for (var i = 1; i <= 5; i++) {
      fireClick(_getDecrementBtn(r));
      await waitForText(r, 'History: ${11 + i} entries');
      expect(
        r.container.querySelector('.count')!.textContent,
        '${10 - i}',
        reason: 'After $i decrements, count should be ${10 - i}',
      );
    }

    _assertFullState(
      r,
      store,
      count: 5,
      step: 1,
      historyLength: 16,
      canUndo: true,
      min: 0,
      max: 10,
      avg: '5.6',
    );

    r.unmount();
  });

  test('step changes persist through actions', () async {
    final store = createCounterStore();
    final r = render(counterApp(store: store));

    // Change to step 5
    fireChange(_getSelect(r), value: '5');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _assertFullState(
      r,
      store,
      count: 0,
      step: 5,
      historyLength: 1,
      canUndo: false,
      min: 0,
      max: 0,
      avg: '0.0',
    );

    // Inc -> 5
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 2 entries');
    _assertFullState(
      r,
      store,
      count: 5,
      step: 5,
      historyLength: 2,
      canUndo: true,
      min: 0,
      max: 5,
      avg: '2.5',
    );

    // Change to step 10
    fireChange(_getSelect(r), value: '10');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _assertFullState(
      r,
      store,
      count: 5,
      step: 10,
      historyLength: 2,
      canUndo: true,
      min: 0,
      max: 5,
      avg: '2.5',
    );

    // Inc -> 15
    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 3 entries');
    _assertFullState(
      r,
      store,
      count: 15,
      step: 10,
      historyLength: 3,
      canUndo: true,
      min: 0,
      max: 15,
      avg: '6.7',
    );

    // Change to step 1
    fireChange(_getSelect(r), value: '1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _assertFullState(
      r,
      store,
      count: 15,
      step: 1,
      historyLength: 3,
      canUndo: true,
      min: 0,
      max: 15,
      avg: '6.7',
    );

    // Dec -> 14
    fireClick(_getDecrementBtn(r));
    await waitForText(r, 'History: 4 entries');
    _assertFullState(
      r,
      store,
      count: 14,
      step: 1,
      historyLength: 4,
      canUndo: true,
      min: 0,
      max: 15,
      avg: '8.5',
    );

    r.unmount();
  });
}
