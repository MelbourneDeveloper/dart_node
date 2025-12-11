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
  });

  group('createSelector3', () {
    test('computes from three inputs', () {
      int getA(State3 s) => s.a;
      int getB(State3 s) => s.b;
      int getC(State3 s) => s.c;

      final getSum = createSelector3(getA, getB, getC, (a, b, c) => a + b + c);

      expect(getSum((a: 1, b: 2, c: 3)), equals(6));
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

      selector..select(state)
      ..select(state);
      expect(computeCount, equals(1));

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

      selector..select(state)
      ..select(state);
      expect(computeCount, equals(1));

      selector..resetCache()
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
  });
}
