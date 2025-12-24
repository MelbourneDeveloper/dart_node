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
  group('TimeTravelEnhancer boundary tests', () {
    test('canUndo is false at index 0', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer);

      expect(timeTravel.currentIndex, equals(0));
      expect(timeTravel.canUndo, isFalse);
    });

    test('canUndo is true at index 1', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer).dispatch(const Increment());

      expect(timeTravel.currentIndex, equals(1));
      expect(timeTravel.canUndo, isTrue);
    });

    test('canRedo is false at last index', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      expect(timeTravel.currentIndex, equals(timeTravel.history.length - 1));
      expect(timeTravel.canRedo, isFalse);
    });

    test('canRedo is true when currentIndex < history.length - 1', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      timeTravel.undo();
      expect(timeTravel.currentIndex, lessThan(timeTravel.history.length - 1));
      expect(timeTravel.canRedo, isTrue);
    });

    test('undo does nothing when canUndo is false', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store = createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer);

      final indexBefore = timeTravel.currentIndex;
      timeTravel.undo();
      expect(timeTravel.currentIndex, equals(indexBefore));
      expect(store.getState().count, equals(0));
    });

    test('redo does nothing when canRedo is false', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store = createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer)..dispatch(const Increment());

      final indexBefore = timeTravel.currentIndex;
      timeTravel.redo();
      expect(timeTravel.currentIndex, equals(indexBefore));
      expect(store.getState().count, equals(1));
    });

    test('jumpTo index 0 is valid', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment())
            ..dispatch(const Increment());

      timeTravel.jumpTo(0);
      expect(timeTravel.currentIndex, equals(0));
      expect(store.getState().count, equals(0));
    });

    test('jumpTo last valid index is valid', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment())
            ..dispatch(const Increment());

      final lastIndex = timeTravel.history.length - 1;
      timeTravel
        ..jumpTo(0)
        ..jumpTo(lastIndex);
      expect(timeTravel.currentIndex, equals(lastIndex));
      expect(store.getState().count, equals(2));
    });

    test('jumpTo exactly history.length throws RangeError', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      expect(
        () => timeTravel.jumpTo(timeTravel.history.length),
        throwsA(isA<RangeError>()),
      );
    });

    test('jumpTo -1 throws RangeError', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer);

      expect(() => timeTravel.jumpTo(-1), throwsA(isA<RangeError>()));
    });

    test(
      'history truncation at exact boundary (currentIndex == length - 1)',
      () {
        final timeTravel = TimeTravelEnhancer<CounterState>();
        final store =
            createStore(counterReducer, (
                count: 0,
              ), enhancer: timeTravel.enhancer)
              ..dispatch(const Increment())
              ..dispatch(const Increment())
              ..dispatch(const Increment());

        expect(timeTravel.history.length, equals(4));

        timeTravel.undo();
        expect(timeTravel.currentIndex, equals(2));

        // After undo, internal store state is still 3 (undo only changes view)
        // Dispatching Decrement: reducer(3, Decrement) = 2
        // Truncates future (index 3) and adds new state (2)
        store.dispatch(const Decrement());
        expect(timeTravel.history.length, equals(4));
        expect(timeTravel.history.last.count, equals(2));
      },
    );

    test('dispatch at last index does not truncate (< not <=)', () {
      // Tests that when currentIndex == history.length - 1 (last position)
      // the truncation condition (_currentIndex < _history.length - 1) is FALSE
      // so no truncation occurs - only appending
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store = createStore(
        counterReducer,
        (count: 0),
        enhancer: timeTravel.enhancer,
      )..dispatch(const Increment()); // history = [0, 1], index = 1

      expect(timeTravel.history.length, equals(2));
      expect(timeTravel.currentIndex, equals(1)); // At last index

      // Current index IS at history.length - 1, so condition is FALSE
      // No truncation, just append
      store.dispatch(const Increment()); // history = [0, 1, 2], index = 2
      expect(timeTravel.history.length, equals(3));
      expect(timeTravel.history[0].count, equals(0));
      expect(timeTravel.history[1].count, equals(1));
      expect(timeTravel.history[2].count, equals(2));
    });

    test('truncation uses length - 1 not length + 1', () {
      // Tests that the comparison uses _history.length - 1 (not + 1)
      // When currentIndex is 0 and history.length is 2:
      // - With length - 1: 0 < 1 is TRUE, truncation happens
      // - With length + 1: 0 < 3 is TRUE, but wrong range would be used
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment())
            ..dispatch(const Increment()); // history = [0, 1, 2], index = 2

      // Jump back to index 0
      timeTravel.jumpTo(0);
      expect(timeTravel.currentIndex, equals(0));

      // Dispatch at index 0 - should truncate indices 1 and 2
      // If using length + 1 incorrectly, the range calculation would be wrong
      store.dispatch(const SetValue(99));

      // History should be [0, 99] - indices 1,2 truncated, 99 added
      expect(timeTravel.history.length, equals(2));
      expect(timeTravel.history[0].count, equals(0));
      expect(timeTravel.history[1].count, equals(99));
    });

    test('dispatching at non-last index truncates future', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment())
            ..dispatch(const Increment())
            ..dispatch(const Increment());

      expect(timeTravel.history.length, equals(4));

      timeTravel.jumpTo(1);
      expect(timeTravel.currentIndex, equals(1));

      // Internal store state is still 3, jumpTo only changes view
      // Dispatching Decrement: reducer(3, Decrement) = 2
      // Truncates indices 2,3 and adds new state
      store.dispatch(const Decrement());
      expect(timeTravel.history.length, equals(3));
      expect(timeTravel.history[2].count, equals(2));
    });

    test('TimeTravelStore getState returns state at currentIndex', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment())
            ..dispatch(const Increment())
            ..dispatch(const Increment());

      expect(store.getState().count, equals(3));

      timeTravel.jumpTo(1);
      expect(store.getState().count, equals(1));

      timeTravel.jumpTo(0);
      expect(store.getState().count, equals(0));
    });

    test('TimeTravelStore dispatch delegates to wrapped store', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer).dispatch(const Increment());

      expect(timeTravel.history.length, equals(2));
    });

    test('TimeTravelStore subscribe delegates to wrapped store', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store = createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer);

      var notified = false;
      store
        ..subscribe(() => notified = true)
        ..dispatch(const Increment());

      expect(notified, isTrue);
    });

    test('TimeTravelStore replaceReducer delegates to wrapped store', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store = createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer);

      // Verify replaceReducer can be called without throwing
      // Note: replaceReducer replaces the internal store's reducer, which
      // bypasses the time travel wrapper for subsequent dispatches
      expect(() => store.replaceReducer(counterReducer), returnsNormally);
    });
  });

  group('devToolsEnhancer tests', () {
    test('uses default name parameter', () {
      final captured = <String>[];

      createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: devToolsEnhancer(
          onAction: (action, prev, next) {
            captured.add('action:${action.runtimeType}');
          },
        ),
      ).dispatch(const Increment());

      expect(captured.isNotEmpty, isTrue);
    });

    test('uses custom name parameter', () {
      final captured = <String>[];

      createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: devToolsEnhancer(
          name: 'CustomStore',
          onAction: (action, prev, next) {
            captured.add('action:${action.runtimeType}');
          },
        ),
      ).dispatch(const Increment());

      expect(captured.isNotEmpty, isTrue);
    });

    test('onAction is optional', () {
      final store = createStore<CounterState>(counterReducer, (
        count: 0,
      ), enhancer: devToolsEnhancer())..dispatch(const Increment());

      expect(store.getState().count, equals(1));
    });

    test('onAction receives correct prev and next state', () {
      final states = <(int, int)>[];

      createStore<CounterState>(
          counterReducer,
          (count: 0),
          enhancer: devToolsEnhancer(
            onAction: (action, prev, next) {
              if (action is Increment) {
                states.add((prev.count, next.count));
              }
            },
          ),
        )
        ..dispatch(const Increment())
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      expect(states, equals([(0, 1), (1, 2), (2, 3)]));
    });

    test('disabled enhancer still creates working store', () {
      final store =
          createStore<CounterState>(counterReducer, (
              count: 0,
            ), enhancer: devToolsEnhancer(enabled: false))
            ..dispatch(const Increment())
            ..dispatch(const Increment());

      expect(store.getState().count, equals(2));
    });
  });

  group('composeEnhancers edge cases', () {
    test('empty list returns identity enhancer', () {
      final store = createStore<CounterState>(counterReducer, (
        count: 5,
      ), enhancer: composeEnhancers([]));

      expect(store.getState().count, equals(5));
      store.dispatch(const Increment());
      expect(store.getState().count, equals(6));
    });

    test('single enhancer returns that enhancer', () {
      var enhancerCalled = false;

      Store<CounterState> enhancer(
        Store<CounterState> Function(Reducer<CounterState>, CounterState)
        createStore,
        Reducer<CounterState> reducer,
        CounterState preloadedState,
      ) {
        enhancerCalled = true;
        return createStore(reducer, preloadedState);
      }

      createStore<CounterState>(counterReducer, (
        count: 0,
      ), enhancer: composeEnhancers([enhancer]));

      expect(enhancerCalled, isTrue);
    });

    test('multiple enhancers compose correctly', () {
      final order = <int>[];

      StoreEnhancer<CounterState> makeEnhancer(int id) =>
          (createStore, reducer, preloadedState) {
            order.add(id);
            return createStore(reducer, preloadedState);
          };

      createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: composeEnhancers([
          makeEnhancer(1),
          makeEnhancer(2),
          makeEnhancer(3),
        ]),
      );

      expect(order, equals([1, 2, 3]));
    });
  });

  group('createEnhancer tests', () {
    test('wraps store correctly', () {
      var wrapCalled = false;

      final enhancer = createEnhancer<CounterState>((store) {
        wrapCalled = true;
        return store;
      });

      final store = createStore(counterReducer, (count: 0), enhancer: enhancer);
      expect(wrapCalled, isTrue);
      expect(store.getState().count, equals(0));
    });

    test('can modify store behavior', () {
      final logs = <String>[];

      final enhancer = createEnhancer<CounterState>(
        (store) => _LoggingStore(store, logs),
      );

      createStore(counterReducer, (
        count: 0,
      ), enhancer: enhancer).dispatch(const Increment());

      expect(logs, contains('dispatch'));
    });
  });
}

class _LoggingStore implements Store<CounterState> {
  _LoggingStore(this._store, this._logs);

  final Store<CounterState> _store;
  final List<String> _logs;

  @override
  CounterState getState() => _store.getState();

  @override
  void dispatch(Action action) {
    _logs.add('dispatch');
    _store.dispatch(action);
  }

  @override
  Unsubscribe subscribe(StateListener<CounterState> listener) =>
      _store.subscribe(listener);

  @override
  void replaceReducer(Reducer<CounterState> nextReducer) =>
      _store.replaceReducer(nextReducer);
}
