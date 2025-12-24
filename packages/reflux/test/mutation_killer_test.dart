// Tests specifically designed to kill surviving mutations.
// These tests target the exact mutations that survived in mutation testing.
import 'package:reflux/reflux.dart';
import 'package:test/test.dart';

typedef CounterState = ({int count});
typedef NullableState = ({int? value, String? name, bool? flag});
typedef MultiNullState = ({int? a, int? b, int? c, int? d, int? e});

sealed class CounterAction extends Action {
  const CounterAction();
}

final class Increment extends CounterAction {
  const Increment();
}

final class SetValue extends CounterAction {
  const SetValue(this.value);
  final int value;
}

CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      SetValue(:final value) => (count: value),
      _ => state,
    };

void main() {
  // ============================================================
  // SELECTORS: hasCache = false -> true mutations
  // ============================================================
  // These mutations change initial hasCache from false to true.
  // If hasCache starts as true, the first call checks:
  //   if (hasCache && identical(input, lastInput))
  // Since lastInput is null initially, if the actual input is ALSO null,
  // identical(null, null) is true and it would return cached null result
  // instead of computing.

  group('createSelector3 hasCache mutation killer', () {
    test('computes when all inputs are null on first call', () {
      var computeCount = 0;

      final selector =
          createSelector3<NullableState, int?, String?, bool?, String>(
            (s) => s.value,
            (s) => s.name,
            (s) => s.flag,
            (a, b, c) {
              computeCount++;
              return 'computed: $a, $b, $c';
            },
          );

      final result = selector((value: null, name: null, flag: null));
      expect(result, equals('computed: null, null, null'));
      expect(computeCount, equals(1));
    });

    test('computes when first input is null', () {
      var computeCount = 0;

      final selector =
          createSelector3<NullableState, int?, String?, bool?, String>(
            (s) => s.value,
            (s) => s.name,
            (s) => s.flag,
            (a, b, c) {
              computeCount++;
              return 'computed: $a, $b, $c';
            },
          );

      final result = selector((value: null, name: 'test', flag: true));
      expect(result, equals('computed: null, test, true'));
      expect(computeCount, equals(1));
    });
  });

  group('createSelector4 hasCache mutation killer', () {
    test('computes when all inputs are null on first call', () {
      var computeCount = 0;

      final selector =
          createSelector4<MultiNullState, int?, int?, int?, int?, String>(
            (s) => s.a,
            (s) => s.b,
            (s) => s.c,
            (s) => s.d,
            (a, b, c, d) {
              computeCount++;
              return 'computed: $a, $b, $c, $d';
            },
          );

      final result = selector((a: null, b: null, c: null, d: null, e: null));
      expect(result, equals('computed: null, null, null, null'));
      expect(computeCount, equals(1));
    });
  });

  group('createSelector5 hasCache mutation killer', () {
    test('computes when all inputs are null on first call', () {
      var computeCount = 0;

      final selector =
          createSelector5<MultiNullState, int?, int?, int?, int?, int?, String>(
            (s) => s.a,
            (s) => s.b,
            (s) => s.c,
            (s) => s.d,
            (s) => s.e,
            (a, b, c, d, e) {
              computeCount++;
              return 'computed: $a, $b, $c, $d, $e';
            },
          );

      final result = selector((a: null, b: null, c: null, d: null, e: null));
      expect(result, equals('computed: null, null, null, null, null'));
      expect(computeCount, equals(1));
    });
  });

  group('ResettableSelector.create1 hasCache mutation killer', () {
    test('computes when input is null on first call', () {
      var computeCount = 0;

      final selector = ResettableSelector.create1<({int? value}), int?, String>(
        (s) => s.value,
        (v) {
          computeCount++;
          return 'computed: $v';
        },
      );

      final result = selector.select((value: null));
      expect(result, equals('computed: null'));
      expect(computeCount, equals(1));
    });

    test('resetCache sets hasCache to false - verifies reset then null', () {
      var computeCount = 0;

      // First call with null, then non-null, reset, then null again
      ResettableSelector.create1<({int? value}), int?, String>((s) => s.value, (
          v,
        ) {
          computeCount++;
          return 'computed: $v';
        })
        ..select((value: null))
        ..select((value: 42))
        ..resetCache()
        ..select((value: null));
      expect(computeCount, equals(3));
    });
  });

  group('ResettableSelector.create2 hasCache mutation killer', () {
    test('computes when both inputs are null on first call', () {
      var computeCount = 0;

      final selector =
          ResettableSelector.create2<({int? a, int? b}), int?, int?, String>(
            (s) => s.a,
            (s) => s.b,
            (a, b) {
              computeCount++;
              return 'computed: $a, $b';
            },
          );

      final result = selector.select((a: null, b: null));
      expect(result, equals('computed: null, null'));
      expect(computeCount, equals(1));
    });

    test('resetCache sets hasCache to false - verifies reset then null', () {
      var computeCount = 0;

      // First call with nulls, then non-null, reset, then nulls again
      ResettableSelector.create2<({int? a, int? b}), int?, int?, String>(
          (s) => s.a,
          (s) => s.b,
          (a, b) {
            computeCount++;
            return 'computed: $a, $b';
          },
        )
        ..select((a: null, b: null))
        ..select((a: 1, b: 2))
        ..resetCache()
        ..select((a: null, b: null));
      expect(computeCount, equals(3));
    });
  });

  // ============================================================
  // STORE: isSubscribed mutations
  // ============================================================
  // Line 86: (!isSubscribed) -> (false) - the early return guard
  // Line 89: isSubscribed = false -> true - setting the flag

  group('Store isSubscribed mutation killer', () {
    test('double unsubscribe does not remove listener twice', () {
      final store = createStore(counterReducer, (count: 0));
      var callCount = 0;

      void listener() => callCount++;

      final unsubscribe = store.subscribe(listener);

      store.dispatch(const Increment());
      expect(callCount, equals(1));

      unsubscribe();

      store.dispatch(const Increment());
      expect(callCount, equals(1));

      // Add the SAME listener again
      final unsubscribe2 = store.subscribe(listener);

      store.dispatch(const Increment());
      expect(callCount, equals(2));

      // Call the FIRST unsubscribe again (double unsubscribe)
      // If mutation (!isSubscribed) -> (false), this would try to remove
      // listener again, removing the second subscription!
      unsubscribe();

      // Listener should STILL be called because second subscription active
      store.dispatch(const Increment());
      expect(callCount, equals(3));

      unsubscribe2();
    });

    test('isSubscribed flag prevents double removal', () {
      final store = createStore(counterReducer, (count: 0));
      final callCounts = <int>[0, 0];

      final unsubscribe1 = store.subscribe(() => callCounts[0]++);
      store
        ..subscribe(() => callCounts[1]++)
        ..dispatch(const Increment());
      expect(callCounts, equals([1, 1]));

      unsubscribe1();
      store.dispatch(const Increment());
      expect(callCounts, equals([1, 2]));

      // Call unsubscribe again multiple times
      unsubscribe1();
      unsubscribe1();
      unsubscribe1();

      // Second listener should still work
      store.dispatch(const Increment());
      expect(callCounts, equals([1, 3]));
    });
  });

  // ============================================================
  // ENHANCERS: TimeTravelEnhancer boundary mutations
  // ============================================================
  // Line 128: < -> <= and - -> +
  // Original: if (_currentIndex < _history.length - 1)

  group('TimeTravelEnhancer boundary mutation killer', () {
    test('truncation boundary: exactly at end vs one before end', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment())
            ..dispatch(const Increment())
            ..dispatch(const Increment());

      expect(timeTravel.history.length, equals(4));

      // Go back to state 2 (index 2, count=2)
      timeTravel.jumpTo(2);
      expect(store.getState().count, equals(2));

      // Dispatch new action - should truncate history after index 2
      store.dispatch(const SetValue(100));

      // History should now be: 0, 1, 2, 100 (4 items)
      expect(timeTravel.history.length, equals(4));
      expect(timeTravel.history.last, equals((count: 100)));
    });

    test('truncation at exact boundary where < vs <= differs', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store =
          createStore(counterReducer, (count: 0), enhancer: timeTravel.enhancer)
            ..dispatch(const Increment())
            ..dispatch(const Increment());

      expect(timeTravel.history.length, equals(3));

      // Jump to last state (index 2)
      // _currentIndex = 2, _history.length = 3
      // Check: if (_currentIndex < _history.length - 1)
      // = if (2 < 3 - 1) = if (2 < 2) = FALSE -> don't truncate
      // Mutation: if (2 <= 3 - 1) = if (2 <= 2) = TRUE -> truncate
      timeTravel.jumpTo(2);
      expect(store.getState().count, equals(2));

      // Dispatch new action
      store.dispatch(const Increment());

      // Original: no truncation needed, just append
      // History should be: 0, 1, 2, 3 (4 items)
      expect(timeTravel.history.length, equals(4));
      expect(
        timeTravel.history,
        equals([(count: 0), (count: 1), (count: 2), (count: 3)]),
      );
    });

    test('arithmetic boundary: - vs + in history length calculation', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store = createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer)..dispatch(const Increment());

      expect(timeTravel.history.length, equals(2));

      // Jump back to state 0 (index 0)
      timeTravel.jumpTo(0);
      expect(store.getState().count, equals(0));

      // Try index 1 case
      timeTravel.jumpTo(1);
      // _currentIndex = 1, _history.length = 2
      // Original: if (1 < 2 - 1) = if (1 < 1) = FALSE
      // Mutation: if (1 < 2 + 1) = if (1 < 3) = TRUE
      expect(store.getState().count, equals(1));

      // Dispatch - with mutation this would incorrectly truncate
      store.dispatch(const Increment());

      // Should have 3 states: 0, 1, 2
      expect(timeTravel.history.length, equals(3));
      expect(store.getState().count, equals(2));
    });

    test('verifies truncation removes future states correctly', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store = createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer);

      for (var i = 0; i < 4; i++) {
        store.dispatch(const Increment());
      }
      expect(timeTravel.history.length, equals(5));
      expect(store.getState().count, equals(4));

      // Go back to count=1 (index 1)
      timeTravel.jumpTo(1);
      expect(store.getState().count, equals(1));
      expect(timeTravel.history.length, equals(5));

      // Dispatch new action - should truncate states 2,3,4 and add new state
      store.dispatch(const SetValue(99));

      // History should be: 0, 1, 99 (3 items)
      expect(timeTravel.history.length, equals(3));
      expect(timeTravel.history, equals([(count: 0), (count: 1), (count: 99)]));
    });

    test('no truncation when at latest state', () {
      final timeTravel = TimeTravelEnhancer<CounterState>();
      final store = createStore(counterReducer, (
        count: 0,
      ), enhancer: timeTravel.enhancer)..dispatch(const Increment());

      // At latest state (index 1, length 2)
      // _currentIndex=1, _history.length=2
      // Check: if (1 < 2 - 1) = if (1 < 1) = false -> no truncation
      expect(timeTravel.currentIndex, equals(1));
      expect(timeTravel.history.length, equals(2));

      // Dispatch another - should just append, no truncation
      store.dispatch(const Increment());

      expect(timeTravel.history.length, equals(3));
      expect(timeTravel.history, equals([(count: 0), (count: 1), (count: 2)]));
    });
  });

  // ============================================================
  // COMPOSE ENHANCERS: isEmpty and length==1 mutations
  // ============================================================

  group('composeEnhancers mutation killer', () {
    test('empty list returns identity enhancer that works', () {
      final composed = composeEnhancers<CounterState>([]);
      final store = createStore(counterReducer, (count: 0), enhancer: composed)
        ..dispatch(const Increment())
        ..dispatch(const Increment());
      expect(store.getState().count, equals(2));
    });

    test('single enhancer is returned directly and called', () {
      var enhancerCalled = false;
      var createStoreCalled = false;

      Store<CounterState> singleEnhancer(
        Store<CounterState> Function(Reducer<CounterState>, CounterState)
        createStoreFn,
        Reducer<CounterState> reducer,
        CounterState preloadedState,
      ) {
        enhancerCalled = true;
        final store = createStoreFn(reducer, preloadedState);
        createStoreCalled = true;
        return store;
      }

      final composed = composeEnhancers<CounterState>([singleEnhancer]);
      createStore(counterReducer, (count: 0), enhancer: composed);

      expect(enhancerCalled, isTrue);
      expect(createStoreCalled, isTrue);
    });

    test('multiple enhancers composed right-to-left', () {
      final order = <int>[];

      StoreEnhancer<CounterState> makeEnhancer(int id) =>
          (createStore, reducer, preloadedState) {
            order.add(id);
            return createStore(reducer, preloadedState);
          };

      final composed = composeEnhancers<CounterState>([
        makeEnhancer(1),
        makeEnhancer(2),
        makeEnhancer(3),
      ]);

      createStore(counterReducer, (count: 0), enhancer: composed);

      // Enhancers should be applied right-to-left but execute in order
      expect(order, equals([1, 2, 3]));
    });
  });
}
