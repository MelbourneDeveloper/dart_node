/// State logic tests for the mobile counter app.
///
/// Tests the shared state logic that powers both web and mobile UIs.
/// UI rendering tests for React Native require an actual RN environment.
/// Run with: dart test
library;

import 'package:statecore_demo/state/counter_state.dart';
import 'package:test/test.dart';

void main() {
  test('initial state is correct', () {
    final state = initialState();
    expect(state.count, 0);
    expect(state.step, 1);
    expect(state.history, [0]);
  });

  test('increment adds step to count', () {
    var state = initialState();
    state = counterReducer(state, const Increment());
    expect(state.count, 1);
    expect(state.history, [0, 1]);
  });

  test('decrement subtracts step from count', () {
    var state = initialState();
    state = counterReducer(state, const Decrement());
    expect(state.count, -1);
    expect(state.history, [0, -1]);
  });

  test('step changes affect increment amount', () {
    var state = initialState();
    state = counterReducer(state, const SetStep(5));
    state = counterReducer(state, const Increment());
    expect(state.count, 5);
    expect(state.step, 5);
  });

  test('undo reverts last action', () {
    var state = initialState();
    state = counterReducer(state, const Increment());
    state = counterReducer(state, const Increment());
    expect(state.count, 2);
    state = counterReducer(state, const Undo());
    expect(state.count, 1);
    expect(state.history, [0, 1]);
  });

  test('reset returns to initial state', () {
    var state = initialState();
    for (var i = 0; i < 5; i++) {
      state = counterReducer(state, const Increment());
    }
    expect(state.count, 5);
    state = counterReducer(state, const Reset());
    expect(state.count, 0);
    expect(state.history, [0]);
  });

  test('stats update correctly', () {
    var state = initialState();
    for (var i = 0; i < 3; i++) {
      state = counterReducer(state, const Increment());
    }
    for (var i = 0; i < 4; i++) {
      state = counterReducer(state, const Decrement());
    }
    expect(state.count, -1);
    final stats = selectHistoryStats(state);
    expect(stats.min, -1);
    expect(stats.max, 3);
  });

  test('complete user flow', () {
    var state = initialState();

    state = counterReducer(state, const Increment());
    state = counterReducer(state, const Increment());
    expect(state.count, 2);

    state = counterReducer(state, const SetStep(10));
    state = counterReducer(state, const Increment());
    expect(state.count, 12);

    state = counterReducer(state, const Undo());
    expect(state.count, 2);

    state = counterReducer(state, const Decrement());
    expect(state.count, -8);

    state = counterReducer(state, const Reset());
    expect(state.count, 0);
    expect(state.history, [0]);
  });

  test('negative counts work correctly', () {
    var state = initialState();
    state = counterReducer(state, const Decrement());
    state = counterReducer(state, const Decrement());
    state = counterReducer(state, const Decrement());
    expect(state.count, -3);
  });

  test('large step values work correctly', () {
    var state = initialState();
    state = counterReducer(state, const SetStep(100));
    state = counterReducer(state, const Increment());
    state = counterReducer(state, const Increment());
    expect(state.count, 200);
  });

  test('undo is disabled at initial state', () {
    final state = initialState();
    expect(selectCanUndo(state), false);
  });

  test('undo becomes enabled after action', () {
    var state = initialState();
    state = counterReducer(state, const Increment());
    expect(selectCanUndo(state), true);
  });

  test('web and mobile use same state logic', () {
    final state1 = initialState();
    final state2 = counterReducer(state1, const Increment());
    final state3 = counterReducer(state2, const SetStep(5));
    final state4 = counterReducer(state3, const Increment());

    expect(state4.count, 6);
    expect(state4.step, 5);
    expect(state4.history, [0, 1, 6]);
  });

  test('selectors work correctly', () {
    final state = (count: 10, step: 1, history: [0, 5, 10, -5, 10]);

    expect(selectCount(state), 10);
    expect(selectStep(state), 1);
    expect(selectCanUndo(state), true);

    final stats = selectHistoryStats(state);
    expect(stats.min, -5);
    expect(stats.max, 10);
    expect(stats.avg, 4.0);
  });

  test('store dispatches actions correctly', () {
    final store = createCounterStore();

    expect(store.getState().count, 0);

    store.dispatch(const Increment());
    expect(store.getState().count, 1);

    store
      ..dispatch(const SetStep(5))
      ..dispatch(const Increment());
    expect(store.getState().count, 6);

    store.dispatch(const Reset());
    expect(store.getState().count, 0);
  });

  test('store notifies subscribers', () {
    final store = createCounterStore()..subscribe(() {});
    var notifyCount = 0;

    store
      ..subscribe(() => notifyCount++)
      ..dispatch(const Increment());
    expect(notifyCount, 1);

    store.dispatch(const Increment());
    expect(notifyCount, 2);
  });
}
