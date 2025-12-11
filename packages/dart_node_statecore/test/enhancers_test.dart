import 'package:dart_node_statecore/dart_node_statecore.dart';
import 'package:test/test.dart';

typedef CounterState = ({int count});

// Counter actions
sealed class CounterAction extends Action {
  const CounterAction();
}

final class Increment extends CounterAction {
  const Increment();
}

final class Decrement extends CounterAction {
  const Decrement();
}

CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      Decrement() => (count: state.count - 1),
      _ => state,
    };

void main() {
  group('composeEnhancers', () {
    test('composes multiple enhancers', () {
      final log = <String>[];

      StoreEnhancer<CounterState> enhancer1() =>
          (createStore, reducer, preloadedState) {
            log.add('enhancer1');
            return createStore(reducer, preloadedState);
          };

      StoreEnhancer<CounterState> enhancer2() =>
          (createStore, reducer, preloadedState) {
            log.add('enhancer2');
            return createStore(reducer, preloadedState);
          };

      createStore(
        counterReducer,
        (count: 0),
        enhancer: composeEnhancers([enhancer1(), enhancer2()]),
      );

      // Enhancers compose right to left, but execute left to right
      expect(log, equals(['enhancer1', 'enhancer2']));
    });

    test('handles empty enhancers list', () {
      final store = createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: composeEnhancers([]),
      )..dispatch(const Increment());
      expect(store.getState().count, equals(1));
    });

    test('handles single enhancer', () {
      var called = false;

      StoreEnhancer<CounterState> enhancer() =>
          (createStore, reducer, preloadedState) {
            called = true;
            return createStore(reducer, preloadedState);
          };

      createStore(
        counterReducer,
        (count: 0),
        enhancer: composeEnhancers([enhancer()]),
      );

      expect(called, isTrue);
    });
  });

  group('createEnhancer', () {
    test('creates custom enhancer', () {
      var wrapCalled = false;

      final enhancer = createEnhancer<CounterState>((store) {
        wrapCalled = true;
        return store;
      });

      createStore(counterReducer, (count: 0), enhancer: enhancer);

      expect(wrapCalled, isTrue);
    });
  });

  group('devToolsEnhancer', () {
    test('logs actions and state changes', () {
      final logs = <(String, int, int)>[];

      createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: devToolsEnhancer(
          onAction: (action, prev, next) {
            logs.add((action.runtimeType.toString(), prev.count, next.count));
          },
        ),
      )
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      // First log is the InitAction
      expect(logs.length, equals(3));
      expect(logs[1], equals(('Increment', 0, 1)));
      expect(logs[2], equals(('Increment', 1, 2)));
    });

    test('can be disabled', () {
      var onActionCalled = false;

      final store = createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: devToolsEnhancer(
          enabled: false,
          onAction: (action, prev, next) => onActionCalled = true,
        ),
      )..dispatch(const Increment());
      expect(onActionCalled, isFalse);
      expect(store.getState().count, equals(1));
    });
  });

  group('TimeTravelEnhancer', () {
    test('records state history', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      createStore(
        counterReducer,
        (count: 0),
        enhancer: timeTravel.enhancer,
      )
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      expect(timeTravel.history.length, equals(3)); // initial + 2 dispatches
      expect(timeTravel.history[0].count, equals(0));
      expect(timeTravel.history[1].count, equals(1));
      expect(timeTravel.history[2].count, equals(2));
    });

    test('can undo', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store = createStore(
        counterReducer,
        (count: 0),
        enhancer: timeTravel.enhancer,
      )
        ..dispatch(const Increment())
        ..dispatch(const Increment());
      expect(store.getState().count, equals(2));

      timeTravel.undo();
      expect(store.getState().count, equals(1));

      timeTravel.undo();
      expect(store.getState().count, equals(0));
    });

    test('can redo', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store = createStore(
        counterReducer,
        (count: 0),
        enhancer: timeTravel.enhancer,
      )
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      timeTravel
        ..undo()
        ..undo();
      expect(store.getState().count, equals(0));

      timeTravel.redo();
      expect(store.getState().count, equals(1));

      timeTravel.redo();
      expect(store.getState().count, equals(2));
    });

    test('can jumpTo specific index', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store = createStore(
        counterReducer,
        (count: 0),
        enhancer: timeTravel.enhancer,
      )
        ..dispatch(const Increment())
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      timeTravel.jumpTo(1);
      expect(store.getState().count, equals(1));

      timeTravel.jumpTo(3);
      expect(store.getState().count, equals(3));
    });

    test('throws on invalid index', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      createStore(
        counterReducer,
        (count: 0),
        enhancer: timeTravel.enhancer,
      );

      expect(() => timeTravel.jumpTo(-1), throwsA(isA<RangeError>()));
      expect(() => timeTravel.jumpTo(100), throwsA(isA<RangeError>()));
    });

    test('canUndo and canRedo', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      createStore(
        counterReducer,
        (count: 0),
        enhancer: timeTravel.enhancer,
      // After InitAction, we have 2 entries: initial + INIT result
      // We can undo back to initial
      ).dispatch(const Increment());
      final canUndoAfterIncrement = timeTravel.canUndo;
      expect(canUndoAfterIncrement, isTrue);
      expect(timeTravel.canRedo, isFalse);

      timeTravel.undo();
      expect(timeTravel.canRedo, isTrue);

      // Go back to start
      while (timeTravel.canUndo) {
        timeTravel.undo();
      }
      expect(timeTravel.canUndo, isFalse);
      expect(timeTravel.canRedo, isTrue);
    });

    test('truncates future history on new dispatch after undo', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store = createStore(
        counterReducer,
        (count: 0),
        enhancer: timeTravel.enhancer,
      )
        ..dispatch(const Increment()) // count: 1
        ..dispatch(const Increment()) // count: 2
        ..dispatch(const Increment()); // count: 3

      timeTravel
        ..undo() // back to count: 2
        ..undo(); // back to count: 1

      store.dispatch(const Decrement()); // count: 0 (new branch)

      expect(timeTravel.history.length, equals(3)); // 0, 1, 0
      expect(timeTravel.canRedo, isFalse);
    });

    test('reset clears history', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      createStore(
        counterReducer,
        (count: 0),
        enhancer: timeTravel.enhancer,
      )
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      timeTravel.reset();

      expect(timeTravel.history.length, equals(1));
      expect(timeTravel.currentIndex, equals(0));
    });
  });
}
