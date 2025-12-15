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

    test('unsubscribe after unsubscribed does not remove other listeners', () {
      final store = createStore(counterReducer, (count: 0));
      var listener1Called = 0;
      var listener2Called = 0;

      final unsubscribe1 = store.subscribe(() => listener1Called++);
      store.subscribe(() => listener2Called++);

      // Unsubscribe listener1
      unsubscribe1();

      // Calling unsubscribe again should be a no-op (isSubscribed = false)
      unsubscribe1();

      // Dispatch should only call listener2 now
      store.dispatch(const Increment());

      expect(listener1Called, equals(0));
      expect(listener2Called, equals(1));
    });

    test('unsubscribe sets isSubscribed to false preventing double removal',
        () {
      final store = createStore(counterReducer, (count: 0));
      var callCount = 0;

      final unsubscribe = store.subscribe(() => callCount++);

      // First dispatch notifies
      store.dispatch(const Increment());
      expect(callCount, equals(1));

      // Unsubscribe
      unsubscribe();

      // Second dispatch doesn't notify
      store.dispatch(const Increment());
      expect(callCount, equals(1));

      // Second unsubscribe is safe (isSubscribed is false)
      unsubscribe();

      // Third dispatch still doesn't notify
      store.dispatch(const Increment());
      expect(callCount, equals(1));
    });

    test('throws when unsubscribing during reduce', () {
      late Store<CounterState> store;
      late void Function() unsubscribe;

      CounterState badReducer(CounterState state, Action action) {
        if (action is UnsubscribeDuringReduceAction) {
          unsubscribe();
        }
        return state;
      }

      store = createStore(badReducer, (count: 0));
      unsubscribe = store.subscribe(() {});

      expect(
        () => store.dispatch(const UnsubscribeDuringReduceAction()),
        throwsA(isA<DispatchInReducerException>()),
      );
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

    test('SubscribeInReducerException has correct message', () {
      final exception = SubscribeInReducerException();
      final message = exception.toString();
      expect(message, contains('SubscribeInReducerException'));
      expect(message, contains('Cannot subscribe'));
      expect(message, contains('reducer'));
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

  group('isSubscribed mutation killers', () {
    test('double unsubscribe does not remove other listeners from list', () {
      // This test kills: if (!isSubscribed) return; → if (false) return;
      // If the mutation survives, calling unsubscribe twice would try to
      // remove the same listener twice from the list, potentially
      // causing issues with the listeners list

      final store = createStore(counterReducer, (count: 0));
      var listener1Count = 0;
      var listener2Count = 0;
      var listener3Count = 0;

      final unsub1 = store.subscribe(() => listener1Count++);
      store
        ..subscribe(() => listener2Count++)
        ..subscribe(() => listener3Count++)
        // Verify all listeners are called
        ..dispatch(const Increment());
      expect(listener1Count, equals(1));
      expect(listener2Count, equals(1));
      expect(listener3Count, equals(1));

      // Unsubscribe listener1 twice - should be a no-op second time
      unsub1();
      unsub1();

      // All other listeners should still work
      store.dispatch(const Increment());
      expect(listener1Count, equals(1)); // Still 1 (unsubscribed)
      expect(listener2Count, equals(2)); // Incremented
      expect(listener3Count, equals(2)); // Incremented
    });

    test('isSubscribed becomes false after unsubscribe', () {
      // This test kills: isSubscribed = false; → isSubscribed = true;
      // If the mutation survives, isSubscribed stays true after unsubscribe
      // and subsequent unsubscribe calls would still try to remove

      final store = createStore(counterReducer, (count: 0));
      var listener1Count = 0;
      var listener2Count = 0;

      void listener1() => listener1Count++;
      void listener2() => listener2Count++;

      final unsub1 = store.subscribe(listener1);
      store
        ..subscribe(listener2)
        // Verify both work
        ..dispatch(const Increment());
      expect(listener1Count, equals(1));
      expect(listener2Count, equals(1));

      // Unsubscribe first listener
      unsub1();

      // Unsubscribe again - isSubscribed should be false, so this is a no-op
      // If isSubscribed stayed true (mutation), this would try to remove again
      unsub1();
      unsub1();
      unsub1();

      // listener2 should still be called
      store.dispatch(const Increment());
      expect(listener1Count, equals(1)); // Unchanged
      expect(listener2Count, equals(2)); // Incremented
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

/// Test action that triggers unsubscribe during reduce
final class UnsubscribeDuringReduceAction extends Action {
  const UnsubscribeDuringReduceAction();
}
