/// Shared counter state - works on web AND mobile!
///
/// This is the core state management logic that's 100% shared
/// between React (web) and React Native (mobile).
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_statecore/dart_node_statecore.dart';

// =============================================================================
// State - just a record, nice and simple
// =============================================================================

/// The counter state containing count, step size, and history.
typedef CounterState = ({int count, int step, List<int> history});

/// Creates the initial counter state.
CounterState initialState() => (count: 0, step: 1, history: [0]);

// =============================================================================
// Actions - type-safe sealed class hierarchy
// =============================================================================

/// Base class for all counter actions.
sealed class CounterAction extends Action {
  const CounterAction();
}

/// Action to increment the counter.
final class Increment extends CounterAction {
  /// Creates an increment action.
  const Increment();
}

/// Action to decrement the counter.
final class Decrement extends CounterAction {
  /// Creates a decrement action.
  const Decrement();
}

/// Action to reset the counter.
final class Reset extends CounterAction {
  /// Creates a reset action.
  const Reset();
}

/// Action to set the step size.
final class SetStep extends CounterAction {
  /// Creates a set step action with the given [step] size.
  const SetStep(this.step);

  /// The step size to set.
  final int step;
}

/// Action to undo the last action.
final class Undo extends CounterAction {
  /// Creates an undo action.
  const Undo();
}

// =============================================================================
// Reducer - pure function, easy to test
// =============================================================================

/// The counter reducer - handles all counter actions.
CounterState counterReducer(CounterState state, Action action) {
  final count = state.count;
  final step = state.step;
  final history = state.history;

  return switch (action) {
    Increment() => (
        count: count + step,
        step: step,
        history: [...history, count + step],
      ),
    Decrement() => (
        count: count - step,
        step: step,
        history: [...history, count - step],
      ),
    Reset() => initialState(),
    SetStep(:final step) => (
        count: count,
        step: step,
        history: history,
      ),
    Undo() when history.length > 1 => (
        count: history[history.length - 2],
        step: step,
        history: history.sublist(0, history.length - 1),
      ),
    _ => state,
  };
}

// =============================================================================
// Selectors - memoized for performance
// =============================================================================

/// Selects the current count from state.
int selectCount(CounterState s) => s.count;

/// Selects the current step size from state.
int selectStep(CounterState s) => s.step;

/// Selects the history list from state.
List<int> selectHistory(CounterState s) => s.history;

/// Memoized selector that returns whether undo is available.
final selectCanUndo = createSelector1(
  selectHistory,
  (history) => history.length > 1,
);

/// Memoized selector that calculates history statistics.
final selectHistoryStats = createSelector1(
  selectHistory,
  (history) {
    if (history.isEmpty) return (min: 0, max: 0, avg: 0.0);
    return (
      min: history.reduce((a, b) => a < b ? a : b),
      max: history.reduce((a, b) => a > b ? a : b),
      avg: history.reduce((a, b) => a + b) / history.length,
    );
  },
);

// =============================================================================
// Middleware - logging for debugging
// =============================================================================

/// Middleware that logs all actions and state changes using dart_logging.
Middleware<CounterState> loggerMiddleware(Logger logger) =>
    (api) => (next) => (action) {
      final before = api.getState();
      next(action);
      final after = api.getState();
      final actionName = action.runtimeType.toString();
      logger.debug(
        '[$actionName] ${before.count} -> ${after.count}',
        structuredData: {
          'action': actionName,
          'before': before.count,
          'after': after.count,
        },
      );
    };

// =============================================================================
// Store Factory - creates a configured store
// =============================================================================

/// Creates a counter store with optional logging middleware.
Store<CounterState> createCounterStore({Logger? logger}) =>
    createStore<CounterState>(
      counterReducer,
      initialState(),
      enhancer: logger != null
          ? applyMiddleware([loggerMiddleware(logger)])
          : null,
    );
