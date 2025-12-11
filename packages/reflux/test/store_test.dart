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

final class Decrement extends CounterAction {
  const Decrement();
}

final class SetValue extends CounterAction {
  const SetValue(this.value);
  final int value;
}

CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      Decrement() => (count: state.count - 1),
      SetValue(:final value) => (count: value),
      _ => state,
    };

void main() {
  group('createStore', () {
    test('creates a store with initial state', () {
      final store = createStore(counterReducer, (count: 0));
      expect(store.getState().count, equals(0));
    });

    test('dispatches INIT action on creation', () {
      var initCalled = false;
      CounterState reducer(CounterState state, Action action) {
        if (action is InitAction) initCalled = true;
        return state;
      }
      createStore(reducer, (count: 0));
      expect(initCalled, isTrue);
    });
  });

  group('Store.dispatch', () {
    test('updates state through reducer', () {
      final store = createStore(counterReducer, (count: 0))
        ..dispatch(const Increment());
      expect(store.getState().count, equals(1));
    });

    test('handles multiple dispatches', () {
      final store = createStore(counterReducer, (count: 0))
        ..dispatch(const Increment())
        ..dispatch(const Increment())
        ..dispatch(const Decrement());
      expect(store.getState().count, equals(1));
    });

    test('handles actions with payload', () {
      final store = createStore(counterReducer, (count: 0))
        ..dispatch(const SetValue(42));
      expect(store.getState().count, equals(42));
    });

    test('throws when dispatching during reduce', () {
      late Store<CounterState> store;
      CounterState badReducer(CounterState state, Action action) {
        if (action is BadAction) {
          store.dispatch(const Increment());
        }
        return state;
      }
      store = createStore(badReducer, (count: 0));
      expect(
        () => store.dispatch(const BadAction()),
        throwsA(isA<DispatchInReducerException>()),
      );
    });
  });

  group('Store.subscribe', () {
    test('notifies listeners on state change', () {
      var callCount = 0;
      createStore(counterReducer, (count: 0))
        ..subscribe(() => callCount++)
        ..dispatch(const Increment());
      expect(callCount, equals(1));
    });

    test('returns unsubscribe function', () {
      final store = createStore(counterReducer, (count: 0));
      var callCount = 0;
      final unsubscribe = store.subscribe(() => callCount++);
      store.dispatch(const Increment());
      unsubscribe();
      store.dispatch(const Increment());
      expect(callCount, equals(1));
    });

    test('supports multiple listeners', () {
      var count1 = 0;
      var count2 = 0;
      createStore(counterReducer, (count: 0))
        ..subscribe(() => count1++)
        ..subscribe(() => count2++)
        ..dispatch(const Increment());
      expect(count1, equals(1));
      expect(count2, equals(1));
    });

    test('unsubscribe is idempotent', () {
      final store = createStore(counterReducer, (count: 0));
      final unsubscribe = store.subscribe(() {});
      unsubscribe();
      unsubscribe(); // Should not throw
    });

    test('throws when subscribing during reduce', () {
      late Store<CounterState> store;
      CounterState badReducer(CounterState state, Action action) {
        if (action is BadAction) {
          store.subscribe(() {});
        }
        return state;
      }
      store = createStore(badReducer, (count: 0));
      expect(
        () => store.dispatch(const BadAction()),
        throwsA(isA<SubscribeInReducerException>()),
      );
    });
  });

  group('Store.replaceReducer', () {
    test('replaces the reducer', () {
      CounterState doubleReducer(CounterState state, Action action) =>
          switch (action) {
            Increment() => (count: state.count + 2),
            _ => state,
          };

      final store = createStore(counterReducer, (count: 0))
        ..replaceReducer(doubleReducer)
        ..dispatch(const Increment());
      expect(store.getState().count, equals(2));
    });

    test('dispatches REPLACE action', () {
      var replaceCalled = false;
      final store = createStore(counterReducer, (count: 0));

      CounterState newReducer(CounterState state, Action action) {
        if (action is ReplaceAction) replaceCalled = true;
        return state;
      }

      store.replaceReducer(newReducer);
      expect(replaceCalled, isTrue);
    });
  });

  group('Store.getState', () {
    test('returns current state', () {
      final store = createStore(counterReducer, (count: 5));
      expect(store.getState().count, equals(5));
    });

    test('returns updated state after dispatch', () {
      final store = createStore(counterReducer, (count: 0))
        ..dispatch(const Increment());
      expect(store.getState().count, equals(1));
    });
  });
}

/// Test action that triggers bad behavior in reducer
final class BadAction extends Action {
  const BadAction();
}
