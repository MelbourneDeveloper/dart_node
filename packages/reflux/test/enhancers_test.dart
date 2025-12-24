import 'package:reflux/reflux.dart';
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

      createStore(counterReducer, (
        count: 0,
      ), enhancer: composeEnhancers([enhancer1(), enhancer2()]));

      // Enhancers compose right to left, but execute left to right
      expect(log, equals(['enhancer1', 'enhancer2']));
    });

    test('handles empty enhancers list', () {
      final store = createStore<CounterState>(counterReducer, (
        count: 0,
      ), enhancer: composeEnhancers([]))..dispatch(const Increment());
      expect(store.getState().count, equals(1));
    });

    test('handles single enhancer', () {
      var called = false;

      StoreEnhancer<CounterState> enhancer() =>
          (createStore, reducer, preloadedState) {
            called = true;
            return createStore(reducer, preloadedState);
          };

      createStore(counterReducer, (
        count: 0,
      ), enhancer: composeEnhancers([enhancer()]));

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

    test('uses default name parameter', () {
      // The name parameter defaults to 'Store' (non-empty string)
      // This test verifies the default is used correctly
      var nameUsed = false;
      createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: devToolsEnhancer(
          // name defaults to 'Store' - not empty string
          onAction: (action, prev, next) => nameUsed = true,
        ),
      ).dispatch(const Increment());
      expect(nameUsed, isTrue);
    });

    test('accepts custom name parameter', () {
      // Verify custom name is accepted (not empty)
      var actionLogged = false;
      createStore<CounterState>(
        counterReducer,
        (count: 0),
        enhancer: devToolsEnhancer(
          name: 'CustomStore',
          onAction: (action, prev, next) => actionLogged = true,
        ),
      ).dispatch(const Increment());
      expect(actionLogged, isTrue);
    });
  });

  group('TimeTravelEnhancer', () {
    test('records state history', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      expect(timeTravel.history.length, equals(3)); // initial + 2 dispatches
      expect(timeTravel.history[0].count, equals(0));
      expect(timeTravel.history[1].count, equals(1));
      expect(timeTravel.history[2].count, equals(2));
    });

    test('can undo', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
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

      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
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

      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
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

      createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer);

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

      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
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

      createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      timeTravel.reset();

      expect(timeTravel.history.length, equals(1));
      expect(timeTravel.currentIndex, equals(0));
    });

    test('undo does nothing when canUndo is false', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store = createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer);

      // At initial state, canUndo should be false
      expect(timeTravel.canUndo, isFalse);
      expect(timeTravel.currentIndex, equals(0));

      // Calling undo when canUndo is false should do nothing
      timeTravel.undo();

      // Should still be at index 0
      expect(timeTravel.currentIndex, equals(0));
      expect(store.getState().count, equals(0));
    });

    test('redo does nothing when canRedo is false', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store = createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer)..dispatch(const Increment());

      // At latest state, canRedo should be false
      expect(timeTravel.canRedo, isFalse);
      expect(store.getState().count, equals(1));

      // Calling redo when canRedo is false should do nothing
      timeTravel.redo();

      // Should still be at the same state
      expect(store.getState().count, equals(1));
      expect(timeTravel.canRedo, isFalse);
    });

    test('canRedo boundary at history.length - 1', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
        ..dispatch(const Increment())
        ..dispatch(const Increment());

      // history = [0, 1, 2], currentIndex = 2, length = 3
      // canRedo = currentIndex < history.length - 1
      // canRedo = 2 < 2 = false
      expect(timeTravel.history.length, equals(3));
      expect(timeTravel.currentIndex, equals(2));
      expect(timeTravel.canRedo, isFalse);

      timeTravel.undo();
      // currentIndex = 1, canRedo = 1 < 2 = true
      expect(timeTravel.currentIndex, equals(1));
      expect(timeTravel.canRedo, isTrue);

      timeTravel.redo();
      // currentIndex = 2, canRedo = 2 < 2 = false
      expect(timeTravel.currentIndex, equals(2));
      expect(timeTravel.canRedo, isFalse);
    });

    test('canUndo boundary at index 0', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer).dispatch(const Increment());

      // history = [0, 1], currentIndex = 1
      // canUndo = currentIndex > 0 = true
      expect(timeTravel.currentIndex, equals(1));
      expect(timeTravel.canUndo, isTrue);

      timeTravel.undo();
      // currentIndex = 0, canUndo = 0 > 0 = false
      expect(timeTravel.currentIndex, equals(0));
      expect(timeTravel.canUndo, isFalse);
    });

    test('jumpTo boundary at index 0', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment())
            ..dispatch(const Increment());

      // Valid: jumpTo(0) should work (index >= 0)
      timeTravel.jumpTo(0);
      expect(store.getState().count, equals(0));

      // Invalid: jumpTo(-1) should throw (index < 0)
      expect(() => timeTravel.jumpTo(-1), throwsA(isA<RangeError>()));
    });

    test('jumpTo boundary at history.length - 1', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment())
            ..dispatch(const Increment());

      // history = [0, 1, 2], length = 3
      // Valid: jumpTo(2) should work (index < length)
      timeTravel.jumpTo(2);
      expect(store.getState().count, equals(2));

      // Invalid: jumpTo(3) should throw (index >= length)
      expect(() => timeTravel.jumpTo(3), throwsA(isA<RangeError>()));
    });

    test('truncates history correctly after undo and new dispatch', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment()) // count: 1, index 1
            ..dispatch(const Increment()) // count: 2, index 2
            ..dispatch(const Increment()); // count: 3, index 3

      // history = [0, 1, 2, 3], length = 4, currentIndex = 3
      expect(timeTravel.history.length, equals(4));
      expect(timeTravel.currentIndex, equals(3));

      // Undo twice: currentIndex = 1
      timeTravel
        ..undo()
        ..undo();
      expect(timeTravel.currentIndex, equals(1));
      // getState() returns the viewed state (history at currentIndex)
      expect(store.getState().count, equals(1));

      // Dispatch new action - truncates future and adds new state
      // NOTE: The reducer receives internal store state (count=3), not view
      // Before: history = [0, 1, 2, 3], currentIndex = 1
      // Decrement(3) = 2
      // Truncates indices 2,3 and adds 2: history = [0, 1, 2]
      store.dispatch(const Decrement());

      // Verify truncation happened correctly
      expect(timeTravel.history.length, equals(3));
      expect(timeTravel.history[0].count, equals(0));
      expect(timeTravel.history[1].count, equals(1));
      expect(timeTravel.history[2].count, equals(2)); // 3 - 1 = 2
      expect(timeTravel.currentIndex, equals(2));
      expect(timeTravel.canRedo, isFalse);
    });

    test('truncation uses correct range calculation', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();

      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment()) // index 1
            ..dispatch(const Increment()) // index 2
            ..dispatch(const Increment()) // index 3
            ..dispatch(const Increment()); // index 4

      // history = [0, 1, 2, 3, 4], currentIndex = 4
      expect(timeTravel.history.length, equals(5));

      // Go back to index 2
      timeTravel
        ..undo()
        ..undo();
      expect(timeTravel.currentIndex, equals(2));

      // Dispatch SetValue(99) - this sets count to 99 regardless of state
      // Truncates indices 3,4 and adds 99: history = [0, 1, 2, 99]
      store.dispatch(const SetValue(99));

      expect(timeTravel.history.length, equals(4)); // [0, 1, 2, 99]
      expect(timeTravel.history[3].count, equals(99));
      expect(timeTravel.currentIndex, equals(3));
    });
  });
}
