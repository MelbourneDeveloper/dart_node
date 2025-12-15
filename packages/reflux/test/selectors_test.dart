import 'package:reflux/reflux.dart';
import 'package:test/test.dart';

typedef AppState = ({List<int> numbers, String filter});
typedef State3 = ({int a, int b, int c});
typedef State4 = ({int a, int b, int c, int d});
typedef State5 = ({int a, int b, int c, int d, int e});
typedef Stats = ({int total, int even, int odd});

void main() {
  group('createSelector1', () {
    test('computes derived value', () {
      List<int> getNumbers(AppState state) => state.numbers;
      final getSum = createSelector1(
        getNumbers,
        (nums) => nums.fold(0, (a, b) => a + b),
      );

      final state = (numbers: [1, 2, 3], filter: '');
      expect(getSum(state), equals(6));
    });

    test('first call always computes (hasCache starts false)', () {
      var computeCount = 0;
      List<int> getNumbers(AppState state) => state.numbers;
      final getSum = createSelector1(getNumbers, (nums) {
        computeCount++;
        return nums.length;
      });

      // First call MUST compute, hasCache is false
      final numbers = [1, 2, 3];
      final state = (numbers: numbers, filter: '');
      final result = getSum(state);
      expect(result, equals(3));
      expect(computeCount, equals(1));
    });

    test('memoizes result when input unchanged', () {
      var computeCount = 0;
      List<int> getNumbers(AppState state) => state.numbers;
      final getSum = createSelector1(getNumbers, (nums) {
        computeCount++;
        return nums.fold(0, (a, b) => a + b);
      });

      final numbers = [1, 2, 3];
      final state1 = (numbers: numbers, filter: '');
      final state2 = (numbers: numbers, filter: 'changed');

      getSum(state1);
      expect(computeCount, equals(1));

      getSum(state2); // Same numbers reference
      expect(computeCount, equals(1)); // Should not recompute
    });

    test('hasCache becomes true after first computation', () {
      var computeCount = 0;
      List<int> getNumbers(AppState state) => state.numbers;
      final selector = createSelector1(getNumbers, (nums) {
        computeCount++;
        return nums.length;
      });

      final numbers = [1, 2, 3];
      final state = (numbers: numbers, filter: '');

      // First call computes
      selector(state);
      expect(computeCount, equals(1));

      // Second call with same input uses cache (hasCache is now true)
      selector(state);
      expect(computeCount, equals(1));

      // Third call still uses cache
      selector((numbers: numbers, filter: 'different'));
      expect(computeCount, equals(1));
    });

    test('recomputes when input changes', () {
      var computeCount = 0;
      List<int> getNumbers(AppState state) => state.numbers;
      final getSum = createSelector1(getNumbers, (nums) {
        computeCount++;
        return nums.fold(0, (a, b) => a + b);
      });

      getSum((numbers: [1, 2, 3], filter: ''));
      expect(computeCount, equals(1));

      getSum((numbers: [1, 2, 3, 4], filter: ''));
      expect(computeCount, equals(2));
    });
  });

  group('createSelector2', () {
    test('computes from two inputs', () {
      List<int> getNumbers(AppState state) => state.numbers;
      String getFilter(AppState state) => state.filter;

      final getFiltered = createSelector2(
        getNumbers,
        getFilter,
        (nums, filter) => switch (filter) {
          'even' => nums.where((n) => n.isEven).toList(),
          'odd' => nums.where((n) => n.isOdd).toList(),
          _ => nums,
        },
      );

      expect(
        getFiltered((numbers: [1, 2, 3, 4, 5], filter: 'even')),
        equals([2, 4]),
      );
      expect(
        getFiltered((numbers: [1, 2, 3, 4, 5], filter: 'odd')),
        equals([1, 3, 5]),
      );
    });

    test('memoizes when both inputs unchanged', () {
      var computeCount = 0;
      List<int> getNumbers(AppState state) => state.numbers;
      String getFilter(AppState state) => state.filter;

      final getFiltered = createSelector2(getNumbers, getFilter, (
        nums,
        filter,
      ) {
        computeCount++;
        return nums;
      });

      final numbers = [1, 2, 3];
      final state = (numbers: numbers, filter: 'test');

      getFiltered(state);
      getFiltered(state);
      expect(computeCount, equals(1));
    });

    test('recomputes when only first input changes (tests && not ||)', () {
      var computeCount = 0;
      List<int> getNumbers(AppState state) => state.numbers;
      String getFilter(AppState state) => state.filter;

      final selector = createSelector2(getNumbers, getFilter, (nums, filter) {
        computeCount++;
        return '${nums.length}-$filter';
      });

      const filter = 'same';
      selector((numbers: [1], filter: filter));
      expect(computeCount, equals(1));

      // Change ONLY input1, keep input2 same
      selector((numbers: [1, 2], filter: filter));
      expect(computeCount, equals(2)); // Must recompute
    });

    test('recomputes when only second input changes (tests && not ||)', () {
      var computeCount = 0;
      List<int> getNumbers(AppState state) => state.numbers;
      String getFilter(AppState state) => state.filter;

      final selector = createSelector2(getNumbers, getFilter, (nums, filter) {
        computeCount++;
        return '${nums.length}-$filter';
      });

      final numbers = [1, 2, 3];
      selector((numbers: numbers, filter: 'a'));
      expect(computeCount, equals(1));

      // Change ONLY input2, keep input1 same
      selector((numbers: numbers, filter: 'b'));
      expect(computeCount, equals(2)); // Must recompute
    });

    test('first call computes even with same inputs (hasCache starts false)',
        () {
      var computeCount = 0;
      List<int> getNumbers(AppState state) => state.numbers;
      String getFilter(AppState state) => state.filter;

      final selector = createSelector2(getNumbers, getFilter, (nums, filter) {
        computeCount++;
        return nums.length;
      });

      final numbers = [1, 2, 3];
      final state = (numbers: numbers, filter: 'test');
      final result = selector(state);
      expect(result, equals(3));
      expect(computeCount, equals(1));
    });
  });

  group('createSelector3', () {
    test('computes from three inputs', () {
      int getA(State3 s) => s.a;
      int getB(State3 s) => s.b;
      int getC(State3 s) => s.c;

      final getSum = createSelector3(getA, getB, getC, (a, b, c) => a + b + c);

      expect(getSum((a: 1, b: 2, c: 3)), equals(6));
    });

    test('first call always computes (hasCache starts false)', () {
      var computeCount = 0;
      final selector = createSelector3<State3, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (a, b, c) {
          computeCount++;
          return a + b + c;
        },
      );

      final result = selector((a: 1, b: 2, c: 3));
      expect(result, equals(6));
      expect(computeCount, equals(1));
    });

    test('first call returns computed value not null', () {
      // If hasCache starts as true (mutation), lastResult is null
      // This test verifies we get actual computed value
      final selector = createSelector3<State3, int, int, int, String>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (a, b, c) => 'result:$a-$b-$c',
      );

      final result = selector((a: 1, b: 2, c: 3));
      expect(result, equals('result:1-2-3'));
      expect(result.length, equals(12));
    });

    test('memoizes when all inputs unchanged', () {
      var computeCount = 0;
      final selector = createSelector3<State3, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (a, b, c) {
          computeCount++;
          return a + b + c;
        },
      );

      const state = (a: 1, b: 2, c: 3);
      selector(state);
      selector(state);
      expect(computeCount, equals(1));
    });

    test('recomputes when only input1 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector3<State3, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (a, b, c) {
          computeCount++;
          return a + b + c;
        },
      );

      selector((a: 1, b: 2, c: 3));
      expect(computeCount, equals(1));

      selector((a: 10, b: 2, c: 3)); // Only a changed
      expect(computeCount, equals(2));
    });

    test('recomputes when only input2 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector3<State3, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (a, b, c) {
          computeCount++;
          return a + b + c;
        },
      );

      selector((a: 1, b: 2, c: 3));
      expect(computeCount, equals(1));

      selector((a: 1, b: 20, c: 3)); // Only b changed
      expect(computeCount, equals(2));
    });

    test('recomputes when only input3 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector3<State3, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (a, b, c) {
          computeCount++;
          return a + b + c;
        },
      );

      selector((a: 1, b: 2, c: 3));
      expect(computeCount, equals(1));

      selector((a: 1, b: 2, c: 30)); // Only c changed
      expect(computeCount, equals(2));
    });
  });

  group('createSelector4', () {
    test('computes from four inputs', () {
      int getA(State4 s) => s.a;
      int getB(State4 s) => s.b;
      int getC(State4 s) => s.c;
      int getD(State4 s) => s.d;

      final getSum = createSelector4(
        getA,
        getB,
        getC,
        getD,
        (a, b, c, d) => a + b + c + d,
      );

      expect(getSum((a: 1, b: 2, c: 3, d: 4)), equals(10));
    });

    test('first call always computes (hasCache starts false)', () {
      var computeCount = 0;
      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (a, b, c, d) {
          computeCount++;
          return a + b + c + d;
        },
      );

      final result = selector((a: 1, b: 2, c: 3, d: 4));
      expect(result, equals(10));
      expect(computeCount, equals(1));
    });

    test('first call returns computed value not null', () {
      final selector = createSelector4<State4, int, int, int, int, String>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (a, b, c, d) => 'r:$a-$b-$c-$d',
      );

      final result = selector((a: 1, b: 2, c: 3, d: 4));
      expect(result, equals('r:1-2-3-4'));
      expect(result.length, equals(10));
    });

    test('memoizes when all inputs unchanged', () {
      var computeCount = 0;
      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (a, b, c, d) {
          computeCount++;
          return a + b + c + d;
        },
      );

      const state = (a: 1, b: 2, c: 3, d: 4);
      selector(state);
      selector(state);
      expect(computeCount, equals(1));
    });

    test('recomputes when only input1 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (a, b, c, d) {
          computeCount++;
          return a + b + c + d;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4));
      selector((a: 10, b: 2, c: 3, d: 4)); // Only a changed
      expect(computeCount, equals(2));
    });

    test('recomputes when only input2 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (a, b, c, d) {
          computeCount++;
          return a + b + c + d;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4));
      selector((a: 1, b: 20, c: 3, d: 4)); // Only b changed
      expect(computeCount, equals(2));
    });

    test('recomputes when only input3 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (a, b, c, d) {
          computeCount++;
          return a + b + c + d;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4));
      selector((a: 1, b: 2, c: 30, d: 4)); // Only c changed
      expect(computeCount, equals(2));
    });

    test('recomputes when only input4 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (a, b, c, d) {
          computeCount++;
          return a + b + c + d;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4));
      selector((a: 1, b: 2, c: 3, d: 40)); // Only d changed
      expect(computeCount, equals(2));
    });
  });

  group('createSelector5', () {
    test('computes from five inputs', () {
      int getA(State5 s) => s.a;
      int getB(State5 s) => s.b;
      int getC(State5 s) => s.c;
      int getD(State5 s) => s.d;
      int getE(State5 s) => s.e;

      final getSum = createSelector5(
        getA,
        getB,
        getC,
        getD,
        getE,
        (a, b, c, d, e) => a + b + c + d + e,
      );

      expect(getSum((a: 1, b: 2, c: 3, d: 4, e: 5)), equals(15));
    });

    test('first call always computes (hasCache starts false)', () {
      var computeCount = 0;
      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (a, b, c, d, e) {
          computeCount++;
          return a + b + c + d + e;
        },
      );

      final result = selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      expect(result, equals(15));
      expect(computeCount, equals(1));
    });

    test('first call returns computed value not null', () {
      final selector =
          createSelector5<State5, int, int, int, int, int, String>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (a, b, c, d, e) => 'v:$a$b$c$d$e',
      );

      final result = selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      expect(result, equals('v:12345'));
      expect(result.length, equals(7));
    });

    test('memoizes when all inputs unchanged', () {
      var computeCount = 0;
      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (a, b, c, d, e) {
          computeCount++;
          return a + b + c + d + e;
        },
      );

      const state = (a: 1, b: 2, c: 3, d: 4, e: 5);
      selector(state);
      selector(state);
      expect(computeCount, equals(1));
    });

    test('recomputes when only input1 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (a, b, c, d, e) {
          computeCount++;
          return a + b + c + d + e;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      selector((a: 10, b: 2, c: 3, d: 4, e: 5)); // Only a changed
      expect(computeCount, equals(2));
    });

    test('recomputes when only input2 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (a, b, c, d, e) {
          computeCount++;
          return a + b + c + d + e;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      selector((a: 1, b: 20, c: 3, d: 4, e: 5)); // Only b changed
      expect(computeCount, equals(2));
    });

    test('recomputes when only input3 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (a, b, c, d, e) {
          computeCount++;
          return a + b + c + d + e;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      selector((a: 1, b: 2, c: 30, d: 4, e: 5)); // Only c changed
      expect(computeCount, equals(2));
    });

    test('recomputes when only input4 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (a, b, c, d, e) {
          computeCount++;
          return a + b + c + d + e;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      selector((a: 1, b: 2, c: 3, d: 40, e: 5)); // Only d changed
      expect(computeCount, equals(2));
    });

    test('recomputes when only input5 changes (tests && not ||)', () {
      var computeCount = 0;
      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (a, b, c, d, e) {
          computeCount++;
          return a + b + c + d + e;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      selector((a: 1, b: 2, c: 3, d: 4, e: 50)); // Only e changed
      expect(computeCount, equals(2));
    });
  });

  group('ResettableSelector', () {
    test('allows resetting cache', () {
      var computeCount = 0;

      final selector = ResettableSelector.create1<AppState, List<int>, int>(
        (s) => s.numbers,
        (nums) {
          computeCount++;
          return nums.length;
        },
      );

      final numbers = [1, 2, 3];
      final state = (numbers: numbers, filter: '');

      selector
        ..select(state)
        ..select(state);
      expect(computeCount, equals(1));

      selector
        ..resetCache()
        ..select(state);
      expect(computeCount, equals(2));
    });

    test('create1 first call computes (hasCache starts false)', () {
      var computeCount = 0;

      final selector = ResettableSelector.create1<AppState, List<int>, int>(
        (s) => s.numbers,
        (nums) {
          computeCount++;
          return nums.length;
        },
      );

      final numbers = [1, 2, 3];
      final state = (numbers: numbers, filter: '');
      final result = selector.select(state);
      expect(result, equals(3));
      expect(computeCount, equals(1));
    });

    test('create1 first call returns computed value not null', () {
      final selector =
          ResettableSelector.create1<AppState, List<int>, String>(
        (s) => s.numbers,
        (nums) => 'len:${nums.length}',
      );

      final result = selector.select((numbers: [1, 2, 3], filter: ''));
      expect(result, equals('len:3'));
      expect(result.length, equals(5));
    });

    test('create1 recomputes when input changes (tests && not ||)', () {
      var computeCount = 0;

      final selector = ResettableSelector.create1<AppState, List<int>, int>(
        (s) => s.numbers,
        (nums) {
          computeCount++;
          return nums.length;
        },
      )..select((numbers: [1, 2], filter: ''));
      expect(computeCount, equals(1));

      selector.select((numbers: [1, 2, 3], filter: ''));
      expect(computeCount, equals(2));
    });

    test('create1 resetCache sets hasCache to false', () {
      var computeCount = 0;

      final selector = ResettableSelector.create1<AppState, List<int>, int>(
        (s) => s.numbers,
        (nums) {
          computeCount++;
          return nums.length;
        },
      );

      final numbers = [1, 2, 3];
      final state = (numbers: numbers, filter: '');

      // First call computes
      selector.select(state);
      expect(computeCount, equals(1));

      // Cached call doesn't compute
      selector.select(state);
      expect(computeCount, equals(1));

      // Reset clears cache, then compute again with same input
      selector
        ..resetCache()
        ..select(state);
      expect(computeCount, equals(2));
    });

    test('create2 allows resetting cache', () {
      var computeCount = 0;

      final selector =
          ResettableSelector.create2<AppState, List<int>, String, String>(
            (s) => s.numbers,
            (s) => s.filter,
            (nums, filter) {
              computeCount++;
              return '$filter: ${nums.length}';
            },
          );

      final numbers = [1, 2, 3];
      final state = (numbers: numbers, filter: 'test');

      selector
        ..select(state)
        ..select(state);
      expect(computeCount, equals(1));

      selector
        ..resetCache()
        ..select(state);
      expect(computeCount, equals(2));
    });

    test('create2 first call computes (hasCache starts false)', () {
      var computeCount = 0;

      final selector =
          ResettableSelector.create2<AppState, List<int>, String, String>(
            (s) => s.numbers,
            (s) => s.filter,
            (nums, filter) {
              computeCount++;
              return '$filter: ${nums.length}';
            },
          );

      final result = selector.select((numbers: [1, 2, 3], filter: 'test'));
      expect(result, equals('test: 3'));
      expect(computeCount, equals(1));
    });

    test('create2 recomputes when only input1 changes (tests && not ||)', () {
      var computeCount = 0;

      final selector =
          ResettableSelector.create2<AppState, List<int>, String, String>(
            (s) => s.numbers,
            (s) => s.filter,
            (nums, filter) {
              computeCount++;
              return '$filter: ${nums.length}';
            },
          );

      const filter = 'same';
      selector.select((numbers: [1], filter: filter));
      expect(computeCount, equals(1));

      selector.select((numbers: [1, 2], filter: filter));
      expect(computeCount, equals(2));
    });

    test('create2 recomputes when only input2 changes (tests && not ||)', () {
      var computeCount = 0;

      final selector =
          ResettableSelector.create2<AppState, List<int>, String, String>(
            (s) => s.numbers,
            (s) => s.filter,
            (nums, filter) {
              computeCount++;
              return '$filter: ${nums.length}';
            },
          );

      final numbers = [1, 2, 3];
      selector.select((numbers: numbers, filter: 'a'));
      expect(computeCount, equals(1));

      selector.select((numbers: numbers, filter: 'b'));
      expect(computeCount, equals(2));
    });

    test('create2 resetCache sets hasCache to false', () {
      var computeCount = 0;

      final selector =
          ResettableSelector.create2<AppState, List<int>, String, String>(
            (s) => s.numbers,
            (s) => s.filter,
            (nums, filter) {
              computeCount++;
              return '$filter: ${nums.length}';
            },
          );

      final numbers = [1, 2, 3];
      final state = (numbers: numbers, filter: 'test');

      selector
        ..select(state)
        ..select(state);
      expect(computeCount, equals(1));

      selector
        ..resetCache()
        ..select(state);
      expect(computeCount, equals(2));
    });
  });

  group('createStructuredSelector', () {
    test('computes structured result', () {
      final getStats = createStructuredSelector<AppState, Stats>(
        (state) => (
          total: state.numbers.length,
          even: state.numbers.where((n) => n.isEven).length,
          odd: state.numbers.where((n) => n.isOdd).length,
        ),
      );

      final result = getStats((numbers: [1, 2, 3, 4, 5], filter: ''));
      expect(result.total, equals(5));
      expect(result.even, equals(2));
      expect(result.odd, equals(3));
    });

    test('memoizes on identical state', () {
      var computeCount = 0;

      final selector = createStructuredSelector<AppState, int>((state) {
        computeCount++;
        return state.numbers.length;
      });

      final state = (numbers: [1, 2, 3], filter: '');
      selector(state);
      selector(state);
      expect(computeCount, equals(1));
    });

    test('first call always computes (hasCache starts false)', () {
      var computeCount = 0;

      final selector = createStructuredSelector<AppState, int>((state) {
        computeCount++;
        return state.numbers.length;
      });

      final state = (numbers: [1, 2, 3], filter: '');
      final result = selector(state);
      expect(result, equals(3));
      expect(computeCount, equals(1));
    });

    test('recomputes when state changes', () {
      var computeCount = 0;

      final selector = createStructuredSelector<AppState, int>((state) {
        computeCount++;
        return state.numbers.length;
      });

      selector((numbers: [1, 2], filter: ''));
      expect(computeCount, equals(1));

      selector((numbers: [1, 2, 3], filter: ''));
      expect(computeCount, equals(2));
    });

    test('hasCache becomes true after first computation', () {
      var computeCount = 0;

      final selector = createStructuredSelector<AppState, int>((state) {
        computeCount++;
        return state.numbers.length;
      });

      final state = (numbers: [1, 2, 3], filter: '');

      // First call computes
      selector(state);
      expect(computeCount, equals(1));

      // Second call uses cache
      selector(state);
      expect(computeCount, equals(1));

      // Third call still uses cache
      selector(state);
      expect(computeCount, equals(1));
    });
  });
}
