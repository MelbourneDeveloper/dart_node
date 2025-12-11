/// Full app UI tests for the web counter app.
///
/// Tests verify actual UI interactions - clicking buttons, not dispatching.
/// Each test verifies the ENTIRE UI tree after EVERY action.
///
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'package:counter_state/counter_state.dart';
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';
import 'package:web_counter/counter_app.dart';

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
  expect(
    r.container.querySelector('.count')!.textContent,
    '$count',
    reason: 'Count display should show $count',
  );

  expect(store.getState().count, count, reason: 'Store count mismatch');
  expect(store.getState().step, step, reason: 'Store step mismatch');
  expect(
    store.getState().history.length,
    historyLength,
    reason: 'Store history length mismatch',
  );

  expect(r.container.textContent, contains('+$step'));
  expect(r.container.textContent, contains('-$step'));
  expect(r.container.textContent, contains('History: $historyLength entries'));
  expect(isDisabled(_getUndoBtn(r)), !canUndo);
  expect(r.container.textContent, contains('Min: $min'));
  expect(r.container.textContent, contains('Max: $max'));
  expect(r.container.textContent, contains('Avg: $avg'));
  expect(r.container.textContent, contains('Statecore Counter'));
}

void main() {
  test('app works without externally provided store', () async {
    final r = render(counterApp());

    expect(r.container.querySelector('.count')!.textContent, '0');
    expect(r.container.textContent, contains('History: 1 entries'));

    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 2 entries');
    expect(r.container.querySelector('.count')!.textContent, '1');

    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 3 entries');
    expect(r.container.querySelector('.count')!.textContent, '2');

    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 4 entries');
    expect(r.container.querySelector('.count')!.textContent, '3');

    fireClick(_getDecrementBtn(r));
    await waitForText(r, 'History: 5 entries');
    expect(r.container.querySelector('.count')!.textContent, '2');

    fireClick(_getUndoBtn(r));
    await waitForText(r, 'History: 4 entries');
    expect(r.container.querySelector('.count')!.textContent, '3');

    r.unmount();
  });

  test('full user journey', () async {
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

    fireClick(_getDecrementBtn(r));
    await waitForText(r, 'History: 4 entries');
    _assertFullState(
      r,
      store,
      count: 1,
      step: 1,
      historyLength: 4,
      canUndo: true,
      min: 0,
      max: 2,
      avg: '1.0',
    );

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

    r.unmount();
  });

  test('decrement into negative territory', () async {
    final store = createCounterStore();
    final r = render(counterApp(store: store));

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

    r.unmount();
  });

  test('rapid clicks all register', () async {
    final store = createCounterStore();
    final r = render(counterApp(store: store));

    for (var i = 1; i <= 10; i++) {
      fireClick(_getIncrementBtn(r));
      await waitForText(r, 'History: ${i + 1} entries');
      expect(r.container.querySelector('.count')!.textContent, '$i');
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

    r.unmount();
  });

  test('reset preserves step size', () async {
    final store = createCounterStore();
    final r = render(counterApp(store: store));

    fireChange(_getSelect(r), value: '10');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    fireClick(_getIncrementBtn(r));
    await waitForText(r, 'History: 2 entries');
    expect(store.getState().count, 10);
    expect(store.getState().step, 10);

    fireClick(_getResetBtn(r));
    await waitForText(r, 'History: 1 entries');
    expect(store.getState().count, 0);
    expect(store.getState().step, 10);

    r.unmount();
  });
}
