import 'package:reflux/reflux.dart';
import 'package:test/test.dart';

typedef CounterState = ({int count});

sealed class CounterAction extends Action {
  const CounterAction();
}

final class Increment extends CounterAction {
  const Increment();
}

final class Decrement extends CounterAction {
  const Decrement();
}

final class TriggerBadBehavior extends Action {
  const TriggerBadBehavior();
}

CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      Decrement() => (count: state.count - 1),
      _ => state,
    };

void main() {
  group('Store unsubscribe edge cases', () {
    test('unsubscribe when already unsubscribed does nothing', () {
      final store = createStore(counterReducer, (count: 0));
      var callCount = 0;

      final unsubscribe = store.subscribe(() => callCount++);
      store.dispatch(const Increment());
      expect(callCount, equals(1));

      unsubscribe();
      store.dispatch(const Increment());
      expect(callCount, equals(1));

      unsubscribe();
      store.dispatch(const Increment());
      expect(callCount, equals(1));
    });

    test('unsubscribe sets isSubscribed to false', () {
      final store = createStore(counterReducer, (count: 0));
      var callCount = 0;

      final unsubscribe = store.subscribe(() => callCount++);
      store.dispatch(const Increment());
      expect(callCount, equals(1));

      unsubscribe();
      unsubscribe();
      unsubscribe();

      store.dispatch(const Increment());
      expect(callCount, equals(1));
    });

    test('throwing during unsubscribe inside reducer', () {
      late Store<CounterState> store;

      CounterState badReducer(CounterState state, Action action) {
        if (action is TriggerBadBehavior) {
          final unsubscribe = store.subscribe(() {});
          try {
            unsubscribe();
          } on DispatchInReducerException {
            return (count: -999);
          }
        }
        return counterReducer(state, action);
      }

      store = createStore(badReducer, (count: 0));
      expect(
        () => store.dispatch(const TriggerBadBehavior()),
        throwsA(isA<SubscribeInReducerException>()),
      );
    });

    test('dispatch during unsubscribe throws', () {
      late Store<CounterState> store;
      late Unsubscribe unsubscribe;

      CounterState badReducer(CounterState state, Action action) {
        if (action is TriggerBadBehavior) {
          unsubscribe();
        }
        return counterReducer(state, action);
      }

      store = createStore(badReducer, (count: 0));
      unsubscribe = store.subscribe(() {});

      expect(
        () => store.dispatch(const TriggerBadBehavior()),
        throwsA(isA<DispatchInReducerException>()),
      );
    });
  });

  group('DispatchInReducerException tests', () {
    test('exception message is descriptive', () {
      final exception = DispatchInReducerException();
      final message = exception.toString();

      expect(message, contains('DispatchInReducerException'));
      expect(message, contains('Cannot dispatch'));
      expect(message, contains('reducer'));
    });

    test('exception is thrown on nested dispatch', () {
      late Store<CounterState> store;

      CounterState badReducer(CounterState state, Action action) {
        if (action is TriggerBadBehavior) {
          store.dispatch(const Increment());
        }
        return counterReducer(state, action);
      }

      store = createStore(badReducer, (count: 0));
      expect(
        () => store.dispatch(const TriggerBadBehavior()),
        throwsA(isA<DispatchInReducerException>()),
      );
    });
  });

  group('SubscribeInReducerException tests', () {
    test('exception message is descriptive', () {
      final exception = SubscribeInReducerException();
      final message = exception.toString();

      expect(message, contains('SubscribeInReducerException'));
      expect(message, contains('Cannot subscribe'));
      expect(message, contains('reducer'));
    });

    test('exception is thrown on subscribe during reduce', () {
      late Store<CounterState> store;

      CounterState badReducer(CounterState state, Action action) {
        if (action is TriggerBadBehavior) {
          store.subscribe(() {});
        }
        return counterReducer(state, action);
      }

      store = createStore(badReducer, (count: 0));
      expect(
        () => store.dispatch(const TriggerBadBehavior()),
        throwsA(isA<SubscribeInReducerException>()),
      );
    });
  });

  group('Store listener during iteration', () {
    test('unsubscribing during listener iteration is safe', () {
      final store = createStore(counterReducer, (count: 0));
      var callCount1 = 0;
      var callCount2 = 0;

      late Unsubscribe unsub1;
      unsub1 = store.subscribe(() {
        callCount1++;
        unsub1();
      });
      store
        ..subscribe(() => callCount2++)
        ..dispatch(const Increment());

      expect(callCount1, equals(1));
      expect(callCount2, equals(1));

      store.dispatch(const Increment());

      expect(callCount1, equals(1));
      expect(callCount2, equals(2));
    });

    test('subscribing in listener works for next dispatch', () {
      final store = createStore(counterReducer, (count: 0));
      var callCount1 = 0;
      var callCount2 = 0;
      var added = false;

      store
        ..subscribe(() {
          callCount1++;
          if (!added) {
            added = true;
            store.subscribe(() => callCount2++);
          }
        })
        ..dispatch(const Increment());
      expect(callCount1, equals(1));
      expect(callCount2, equals(0));

      store.dispatch(const Increment());
      expect(callCount1, equals(2));
      expect(callCount2, equals(1));
    });
  });

  group('Store reducer replacement', () {
    test('replaceReducer dispatches ReplaceAction', () {
      var replaceActionSeen = false;

      CounterState trackingReducer(CounterState state, Action action) {
        if (action is ReplaceAction) {
          replaceActionSeen = true;
        }
        return counterReducer(state, action);
      }

      createStore(counterReducer, (count: 0))
          .replaceReducer(trackingReducer);

      expect(replaceActionSeen, isTrue);
    });

    test('new reducer handles subsequent dispatches', () {
      final store = createStore(counterReducer, (count: 0));

      CounterState doubleReducer(CounterState state, Action action) =>
          switch (action) {
            Increment() => (count: state.count + 2),
            _ => state,
          };

      store
        ..dispatch(const Increment())
        ..replaceReducer(doubleReducer)
        ..dispatch(const Increment());

      expect(store.getState().count, equals(3));
    });
  });

  group('Store with enhancer', () {
    test('enhancer receives createStore function', () {
      var enhancerCalled = false;

      final enhancer = (
        Store<CounterState> Function(Reducer<CounterState>, CounterState)
            createStore,
        Reducer<CounterState> reducer,
        CounterState preloadedState,
      ) {
        enhancerCalled = true;
        return createStore(reducer, preloadedState);
      };

      createStore(counterReducer, (count: 0), enhancer: enhancer);
      expect(enhancerCalled, isTrue);
    });

    test('enhancer can modify reducer', () {
      final enhancer = (
        Store<CounterState> Function(Reducer<CounterState>, CounterState)
            createStore,
        Reducer<CounterState> reducer,
        CounterState preloadedState,
      ) {
        CounterState wrappedReducer(CounterState state, Action action) {
          final newState = reducer(state, action);
          return (count: newState.count * 2);
        }

        return createStore(wrappedReducer, preloadedState);
      };

      final store = createStore(counterReducer, (count: 1), enhancer: enhancer);
      expect(store.getState().count, equals(2));
    });
  });

  group('InitAction', () {
    test('InitAction is dispatched on store creation', () {
      var initActionReceived = false;

      CounterState trackingReducer(CounterState state, Action action) {
        if (action is InitAction) {
          initActionReceived = true;
        }
        return state;
      }

      createStore(trackingReducer, (count: 0));
      expect(initActionReceived, isTrue);
    });

    test('InitAction has correct type', () {
      expect(initAction, isA<InitAction>());
    });
  });

  group('Decrement action', () {
    test('Decrement reduces count by 1', () {
      final store = createStore(counterReducer, (count: 5))
        ..dispatch(const Decrement());
      expect(store.getState().count, equals(4));
    });
  });
}
