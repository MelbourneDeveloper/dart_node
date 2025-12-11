import 'package:reflux/reflux.dart';
import 'package:test/test.dart';

typedef CounterState = ({int count});

// Define actions as sealed classes for type-safe pattern matching
sealed class CounterAction extends Action {
  const CounterAction();
}

final class Increment extends CounterAction {
  const Increment();
}

final class Double extends CounterAction {
  const Double();
}

final class Blocked extends CounterAction {
  const Blocked();
}

CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      _ => state,
    };

void main() {
  group('applyMiddleware', () {
    test('applies single middleware', () {
      final log = <String>[];

      Middleware<CounterState> loggerMiddleware() =>
          (api) => (next) => (action) {
                final actionName = switch (action) {
                  Increment() => 'INCREMENT',
                  _ => 'UNKNOWN',
                };
                log.add('before: $actionName');
                next(action);
                log.add('after: $actionName');
              };

      createStore(
        counterReducer,
        (count: 0),
        enhancer: applyMiddleware([loggerMiddleware()]),
      ).dispatch(const Increment());

      expect(
        log,
        containsAllInOrder(['before: INCREMENT', 'after: INCREMENT']),
      );
    });

    test('applies multiple middleware in correct order', () {
      final log = <String>[];

      Middleware<CounterState> middleware1() =>
          (api) => (next) => (action) {
                log.add('m1 before');
                next(action);
                log.add('m1 after');
              };

      Middleware<CounterState> middleware2() =>
          (api) => (next) => (action) {
                log.add('m2 before');
                next(action);
                log.add('m2 after');
              };

      createStore(
        counterReducer,
        (count: 0),
        enhancer: applyMiddleware([middleware1(), middleware2()]),
      ).dispatch(const Increment());

      // Middleware should compose: m1 -> m2 -> dispatch
      expect(log, equals(['m1 before', 'm2 before', 'm2 after', 'm1 after']));
    });

    test('middleware can access getState', () {
      int? capturedState;

      Middleware<CounterState> stateCapture() =>
          (api) => (next) => (action) {
                next(action);
                capturedState = api.getState().count;
              };

      createStore(
        counterReducer,
        (count: 0),
        enhancer: applyMiddleware([stateCapture()]),
      ).dispatch(const Increment());
      expect(capturedState, equals(1));
    });

    test('middleware can dispatch new actions', () {
      Middleware<CounterState> doubleMiddleware() =>
          (api) => (next) => (action) {
                next(action);
                if (action is Double) {
                  api.dispatch(const Increment());
                }
              };

      final store = createStore(
        counterReducer,
        (count: 0),
        enhancer: applyMiddleware([doubleMiddleware()]),
      )..dispatch(const Increment());
      expect(store.getState().count, equals(1));

      store.dispatch(const Double());
      expect(store.getState().count, equals(2));
    });

    test('middleware can prevent action from reaching reducer', () {
      Middleware<CounterState> blockMiddleware() =>
          (api) => (next) => (action) {
                if (action is! Blocked) next(action);
              };

      final store = createStore(
        counterReducer,
        (count: 0),
        enhancer: applyMiddleware([blockMiddleware()]),
      )..dispatch(const Increment());
      expect(store.getState().count, equals(1));

      store.dispatch(const Blocked());
      expect(store.getState().count, equals(1));
    });

    test('empty middleware list works', () {
      final store = createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: applyMiddleware<CounterState>([]),
      )..dispatch(const Increment());
      expect(store.getState().count, equals(1));
    });

    test('middleware store preserves subscribe functionality', () {
      var called = false;

      createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: applyMiddleware<CounterState>([]),
      )
        ..subscribe(() => called = true)
        ..dispatch(const Increment());
      expect(called, isTrue);
    });

    test('middleware store preserves replaceReducer', () {
      CounterState doubleReducer(CounterState state, Action action) =>
          switch (action) {
            Increment() => (count: state.count + 2),
            _ => state,
          };

      final store = createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: applyMiddleware<CounterState>([]),
      )
        ..replaceReducer(doubleReducer)
        ..dispatch(const Increment());
      expect(store.getState().count, equals(2));
    });
  });
}
