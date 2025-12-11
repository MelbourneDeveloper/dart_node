/// Selectors are functions that extract and optionally transform
/// data from the state. Memoized selectors cache their results
/// and only recompute when their inputs change.
library;

/// A basic selector that extracts data from state.
typedef Selector<S, R> = R Function(S state);

/// Creates a memoized selector that caches its result.
///
/// The selector will only recompute when the input changes.
/// This is useful for expensive computations derived from state.
///
/// Example:
/// ```dart
/// final getTodos = (AppState state) => state.todos;
/// final getFilter = (AppState state) => state.filter;
///
/// final getVisibleTodos = createSelector1(
///   getTodos,
///   (todos) => todos.where((t) => !t.completed).toList(),
/// );
/// ```
Selector<S, R> createSelector1<S, T1, R>(
  Selector<S, T1> selector1,
  R Function(T1) combiner,
) {
  T1? lastInput;
  R? lastResult;
  var hasCache = false;

  return (S state) {
    final input = selector1(state);

    if (hasCache && identical(input, lastInput)) {
      return lastResult as R;
    }

    lastInput = input;
    lastResult = combiner(input);
    hasCache = true;

    return lastResult as R;
  };
}

/// Creates a memoized selector with two input selectors.
///
/// Example:
/// ```dart
/// final getVisibleTodos = createSelector2(
///   getTodos,
///   getFilter,
///   (todos, filter) => switch (filter) {
///     'completed' => todos.where((t) => t.completed).toList(),
///     'active' => todos.where((t) => !t.completed).toList(),
///     _ => todos,
///   },
/// );
/// ```
Selector<S, R> createSelector2<S, T1, T2, R>(
  Selector<S, T1> selector1,
  Selector<S, T2> selector2,
  R Function(T1, T2) combiner,
) {
  T1? lastInput1;
  T2? lastInput2;
  R? lastResult;
  var hasCache = false;

  return (S state) {
    final input1 = selector1(state);
    final input2 = selector2(state);

    if (hasCache &&
        identical(input1, lastInput1) &&
        identical(input2, lastInput2)) {
      return lastResult as R;
    }

    lastInput1 = input1;
    lastInput2 = input2;
    lastResult = combiner(input1, input2);
    hasCache = true;

    return lastResult as R;
  };
}

/// Creates a memoized selector with three input selectors.
Selector<S, R> createSelector3<S, T1, T2, T3, R>(
  Selector<S, T1> selector1,
  Selector<S, T2> selector2,
  Selector<S, T3> selector3,
  R Function(T1, T2, T3) combiner,
) {
  T1? lastInput1;
  T2? lastInput2;
  T3? lastInput3;
  R? lastResult;
  var hasCache = false;

  return (S state) {
    final input1 = selector1(state);
    final input2 = selector2(state);
    final input3 = selector3(state);

    if (hasCache &&
        identical(input1, lastInput1) &&
        identical(input2, lastInput2) &&
        identical(input3, lastInput3)) {
      return lastResult as R;
    }

    lastInput1 = input1;
    lastInput2 = input2;
    lastInput3 = input3;
    lastResult = combiner(input1, input2, input3);
    hasCache = true;

    return lastResult as R;
  };
}

/// Creates a memoized selector with four input selectors.
Selector<S, R> createSelector4<S, T1, T2, T3, T4, R>(
  Selector<S, T1> selector1,
  Selector<S, T2> selector2,
  Selector<S, T3> selector3,
  Selector<S, T4> selector4,
  R Function(T1, T2, T3, T4) combiner,
) {
  T1? lastInput1;
  T2? lastInput2;
  T3? lastInput3;
  T4? lastInput4;
  R? lastResult;
  var hasCache = false;

  return (S state) {
    final input1 = selector1(state);
    final input2 = selector2(state);
    final input3 = selector3(state);
    final input4 = selector4(state);

    if (hasCache &&
        identical(input1, lastInput1) &&
        identical(input2, lastInput2) &&
        identical(input3, lastInput3) &&
        identical(input4, lastInput4)) {
      return lastResult as R;
    }

    lastInput1 = input1;
    lastInput2 = input2;
    lastInput3 = input3;
    lastInput4 = input4;
    lastResult = combiner(input1, input2, input3, input4);
    hasCache = true;

    return lastResult as R;
  };
}

/// Creates a memoized selector with five input selectors.
Selector<S, R> createSelector5<S, T1, T2, T3, T4, T5, R>(
  Selector<S, T1> selector1,
  Selector<S, T2> selector2,
  Selector<S, T3> selector3,
  Selector<S, T4> selector4,
  Selector<S, T5> selector5,
  R Function(T1, T2, T3, T4, T5) combiner,
) {
  T1? lastInput1;
  T2? lastInput2;
  T3? lastInput3;
  T4? lastInput4;
  T5? lastInput5;
  R? lastResult;
  var hasCache = false;

  return (S state) {
    final input1 = selector1(state);
    final input2 = selector2(state);
    final input3 = selector3(state);
    final input4 = selector4(state);
    final input5 = selector5(state);

    if (hasCache &&
        identical(input1, lastInput1) &&
        identical(input2, lastInput2) &&
        identical(input3, lastInput3) &&
        identical(input4, lastInput4) &&
        identical(input5, lastInput5)) {
      return lastResult as R;
    }

    lastInput1 = input1;
    lastInput2 = input2;
    lastInput3 = input3;
    lastInput4 = input4;
    lastInput5 = input5;
    lastResult = combiner(input1, input2, input3, input4, input5);
    hasCache = true;

    return lastResult as R;
  };
}

/// A resettable memoized selector.
///
/// Unlike the standard createSelector functions, this returns
/// an object that allows you to reset the cache.
///
/// Example:
/// ```dart
/// final selector = ResettableSelector.create1(
///   getTodos,
///   (todos) => todos.where((t) => !t.completed).toList(),
/// );
///
/// final result = selector.select(state);
/// selector.resetCache(); // Clear the cached result
/// ```
final class ResettableSelector<S, R> {
  ResettableSelector._(this._selector, this._reset);

  final Selector<S, R> _selector;
  final void Function() _reset;

  /// Selects data from the state.
  R select(S state) => _selector(state);

  /// Resets the selector's cache.
  void resetCache() => _reset();

  /// Creates a resettable selector with one input.
  static ResettableSelector<S, R> create1<S, T1, R>(
    Selector<S, T1> selector1,
    R Function(T1) combiner,
  ) {
    T1? lastInput;
    R? lastResult;
    var hasCache = false;

    void reset() {
      lastInput = null;
      lastResult = null;
      hasCache = false;
    }

    R select(S state) {
      final input = selector1(state);

      if (hasCache && identical(input, lastInput)) {
        return lastResult as R;
      }

      lastInput = input;
      lastResult = combiner(input);
      hasCache = true;

      return lastResult as R;
    }

    return ResettableSelector._(select, reset);
  }

  /// Creates a resettable selector with two inputs.
  static ResettableSelector<S, R> create2<S, T1, T2, R>(
    Selector<S, T1> selector1,
    Selector<S, T2> selector2,
    R Function(T1, T2) combiner,
  ) {
    T1? lastInput1;
    T2? lastInput2;
    R? lastResult;
    var hasCache = false;

    void reset() {
      lastInput1 = null;
      lastInput2 = null;
      lastResult = null;
      hasCache = false;
    }

    R select(S state) {
      final input1 = selector1(state);
      final input2 = selector2(state);

      if (hasCache &&
          identical(input1, lastInput1) &&
          identical(input2, lastInput2)) {
        return lastResult as R;
      }

      lastInput1 = input1;
      lastInput2 = input2;
      lastResult = combiner(input1, input2);
      hasCache = true;

      return lastResult as R;
    }

    return ResettableSelector._(select, reset);
  }
}

/// Structured selector that computes multiple derived values at once.
///
/// This is useful when you need to compute multiple derived values
/// from the same base selectors.
///
/// Example:
/// ```dart
/// final todoStats = createStructuredSelector<AppState, TodoStats>(
///   (state) => (
///     total: state.todos.length,
///     completed: state.todos.where((t) => t.completed).length,
///     active: state.todos.where((t) => !t.completed).length,
///   ),
/// );
/// ```
Selector<S, R> createStructuredSelector<S, R>(R Function(S state) compute) {
  R? lastResult;
  S? lastState;
  var hasCache = false;

  return (S state) {
    if (hasCache && identical(state, lastState)) {
      return lastResult as R;
    }

    lastState = state;
    lastResult = compute(state);
    hasCache = true;

    return lastResult as R;
  };
}
