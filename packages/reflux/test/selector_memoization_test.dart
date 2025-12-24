import 'package:reflux/reflux.dart';
import 'package:test/test.dart';

typedef State3 = ({int a, int b, int c});
typedef State4 = ({int a, int b, int c, int d});
typedef State5 = ({int a, int b, int c, int d, int e});
typedef State2 = ({int a, int b});

void main() {
  group('createSelector3 memoization', () {
    test('returns cached result when all inputs identical', () {
      var computeCount = 0;
      const a = 1;
      const b = 2;
      const c = 3;

      final selector = createSelector3<State3, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (x, y, z) {
          computeCount++;
          return x + y + z;
        },
      );

      const state = (a: a, b: b, c: c);
      selector(state);
      expect(computeCount, equals(1));

      selector(state);
      expect(computeCount, equals(1));
    });

    test('recomputes when first input changes', () {
      var computeCount = 0;

      final selector = createSelector3<State3, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (x, y, z) {
          computeCount++;
          return x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3));
      expect(computeCount, equals(1));

      selector((a: 100, b: 2, c: 3));
      expect(computeCount, equals(2));
    });

    test('recomputes when second input changes', () {
      var computeCount = 0;

      final selector = createSelector3<State3, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (x, y, z) {
          computeCount++;
          return x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3));
      expect(computeCount, equals(1));

      selector((a: 1, b: 200, c: 3));
      expect(computeCount, equals(2));
    });

    test('recomputes when third input changes', () {
      var computeCount = 0;

      final selector = createSelector3<State3, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (x, y, z) {
          computeCount++;
          return x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3));
      expect(computeCount, equals(1));

      selector((a: 1, b: 2, c: 300));
      expect(computeCount, equals(2));
    });

    test('caches result after first computation', () {
      var computeCount = 0;
      final list1 = [1];
      final list2 = [2];
      final list3 = [3];

      final selector =
          createSelector3<
            ({List<int> a, List<int> b, List<int> c}),
            List<int>,
            List<int>,
            List<int>,
            int
          >((s) => s.a, (s) => s.b, (s) => s.c, (a, b, c) {
            computeCount++;
            return a.first + b.first + c.first;
          });

      final state1 = (a: list1, b: list2, c: list3);
      final state2 = (a: list1, b: list2, c: list3);

      selector(state1);
      expect(computeCount, equals(1));

      selector(state2);
      expect(computeCount, equals(1));
    });
  });

  group('createSelector4 memoization', () {
    test('returns cached result when all inputs identical', () {
      var computeCount = 0;

      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (w, x, y, z) {
          computeCount++;
          return w + x + y + z;
        },
      );

      const state = (a: 1, b: 2, c: 3, d: 4);
      selector(state);
      expect(computeCount, equals(1));

      selector(state);
      expect(computeCount, equals(1));
    });

    test('recomputes when first input changes', () {
      var computeCount = 0;

      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (w, x, y, z) {
          computeCount++;
          return w + x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4));
      expect(computeCount, equals(1));

      selector((a: 100, b: 2, c: 3, d: 4));
      expect(computeCount, equals(2));
    });

    test('recomputes when second input changes', () {
      var computeCount = 0;

      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (w, x, y, z) {
          computeCount++;
          return w + x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4));
      expect(computeCount, equals(1));

      selector((a: 1, b: 200, c: 3, d: 4));
      expect(computeCount, equals(2));
    });

    test('recomputes when third input changes', () {
      var computeCount = 0;

      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (w, x, y, z) {
          computeCount++;
          return w + x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4));
      expect(computeCount, equals(1));

      selector((a: 1, b: 2, c: 300, d: 4));
      expect(computeCount, equals(2));
    });

    test('recomputes when fourth input changes', () {
      var computeCount = 0;

      final selector = createSelector4<State4, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (w, x, y, z) {
          computeCount++;
          return w + x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4));
      expect(computeCount, equals(1));

      selector((a: 1, b: 2, c: 3, d: 400));
      expect(computeCount, equals(2));
    });

    test('caches result after first computation', () {
      var computeCount = 0;
      final list1 = [1];
      final list2 = [2];
      final list3 = [3];
      final list4 = [4];

      final selector =
          createSelector4<
            ({List<int> a, List<int> b, List<int> c, List<int> d}),
            List<int>,
            List<int>,
            List<int>,
            List<int>,
            int
          >((s) => s.a, (s) => s.b, (s) => s.c, (s) => s.d, (a, b, c, d) {
            computeCount++;
            return a.first + b.first + c.first + d.first;
          });

      final state1 = (a: list1, b: list2, c: list3, d: list4);
      final state2 = (a: list1, b: list2, c: list3, d: list4);

      selector(state1);
      expect(computeCount, equals(1));

      selector(state2);
      expect(computeCount, equals(1));
    });
  });

  group('createSelector5 memoization', () {
    test('returns cached result when all inputs identical', () {
      var computeCount = 0;

      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (v, w, x, y, z) {
          computeCount++;
          return v + w + x + y + z;
        },
      );

      const state = (a: 1, b: 2, c: 3, d: 4, e: 5);
      selector(state);
      expect(computeCount, equals(1));

      selector(state);
      expect(computeCount, equals(1));
    });

    test('recomputes when first input changes', () {
      var computeCount = 0;

      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (v, w, x, y, z) {
          computeCount++;
          return v + w + x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      expect(computeCount, equals(1));

      selector((a: 100, b: 2, c: 3, d: 4, e: 5));
      expect(computeCount, equals(2));
    });

    test('recomputes when second input changes', () {
      var computeCount = 0;

      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (v, w, x, y, z) {
          computeCount++;
          return v + w + x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      expect(computeCount, equals(1));

      selector((a: 1, b: 200, c: 3, d: 4, e: 5));
      expect(computeCount, equals(2));
    });

    test('recomputes when third input changes', () {
      var computeCount = 0;

      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (v, w, x, y, z) {
          computeCount++;
          return v + w + x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      expect(computeCount, equals(1));

      selector((a: 1, b: 2, c: 300, d: 4, e: 5));
      expect(computeCount, equals(2));
    });

    test('recomputes when fourth input changes', () {
      var computeCount = 0;

      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (v, w, x, y, z) {
          computeCount++;
          return v + w + x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      expect(computeCount, equals(1));

      selector((a: 1, b: 2, c: 3, d: 400, e: 5));
      expect(computeCount, equals(2));
    });

    test('recomputes when fifth input changes', () {
      var computeCount = 0;

      final selector = createSelector5<State5, int, int, int, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (s) => s.c,
        (s) => s.d,
        (s) => s.e,
        (v, w, x, y, z) {
          computeCount++;
          return v + w + x + y + z;
        },
      );

      selector((a: 1, b: 2, c: 3, d: 4, e: 5));
      expect(computeCount, equals(1));

      selector((a: 1, b: 2, c: 3, d: 4, e: 500));
      expect(computeCount, equals(2));
    });

    test('caches result after first computation', () {
      var computeCount = 0;
      final list1 = [1];
      final list2 = [2];
      final list3 = [3];
      final list4 = [4];
      final list5 = [5];

      final selector =
          createSelector5<
            ({List<int> a, List<int> b, List<int> c, List<int> d, List<int> e}),
            List<int>,
            List<int>,
            List<int>,
            List<int>,
            List<int>,
            int
          >((s) => s.a, (s) => s.b, (s) => s.c, (s) => s.d, (s) => s.e, (
            a,
            b,
            c,
            d,
            e,
          ) {
            computeCount++;
            return a.first + b.first + c.first + d.first + e.first;
          });

      final state1 = (a: list1, b: list2, c: list3, d: list4, e: list5);
      final state2 = (a: list1, b: list2, c: list3, d: list4, e: list5);

      selector(state1);
      expect(computeCount, equals(1));

      selector(state2);
      expect(computeCount, equals(1));
    });
  });

  group('ResettableSelector.create1 memoization', () {
    test('returns cached result when input identical', () {
      var computeCount = 0;
      final list = [1, 2, 3];

      final selector =
          ResettableSelector.create1<({List<int> nums}), List<int>, int>(
            (s) => s.nums,
            (nums) {
              computeCount++;
              return nums.length;
            },
          );

      final state = (nums: list);
      selector.select(state);
      expect(computeCount, equals(1));

      selector.select(state);
      expect(computeCount, equals(1));
    });

    test('recomputes when input changes', () {
      var computeCount = 0;

      ResettableSelector.create1<({List<int> nums}), List<int>, int>(
          (s) => s.nums,
          (nums) {
            computeCount++;
            return nums.length;
          },
        )
        ..select((nums: [1, 2, 3]))
        ..select((nums: [1, 2, 3, 4]));
      expect(computeCount, equals(2));
    });

    test('resets cache state variables', () {
      var computeCount = 0;
      final list = [1, 2, 3];

      final selector =
          ResettableSelector.create1<({List<int> nums}), List<int>, int>(
            (s) => s.nums,
            (nums) {
              computeCount++;
              return nums.length;
            },
          );

      final state = (nums: list);
      selector.select(state);
      expect(computeCount, equals(1));

      selector
        ..resetCache()
        ..select(state);
      expect(computeCount, equals(2));
    });
  });

  group('ResettableSelector.create2 memoization', () {
    test('returns cached result when both inputs identical', () {
      var computeCount = 0;
      final list = [1, 2, 3];
      const filter = 'test';

      final selector =
          ResettableSelector.create2<
            ({List<int> nums, String filter}),
            List<int>,
            String,
            String
          >((s) => s.nums, (s) => s.filter, (nums, f) {
            computeCount++;
            return '$f: ${nums.length}';
          });

      final state = (nums: list, filter: filter);
      selector
        ..select(state)
        ..select(state);
      expect(computeCount, equals(1));
    });

    test('recomputes when first input changes', () {
      var computeCount = 0;

      ResettableSelector.create2<
          ({List<int> nums, String filter}),
          List<int>,
          String,
          String
        >((s) => s.nums, (s) => s.filter, (nums, f) {
          computeCount++;
          return '$f: ${nums.length}';
        })
        ..select((nums: [1, 2, 3], filter: 'test'))
        ..select((nums: [1, 2, 3, 4], filter: 'test'));
      expect(computeCount, equals(2));
    });

    test('recomputes when second input changes', () {
      var computeCount = 0;
      final list = [1, 2, 3];

      ResettableSelector.create2<
          ({List<int> nums, String filter}),
          List<int>,
          String,
          String
        >((s) => s.nums, (s) => s.filter, (nums, f) {
          computeCount++;
          return '$f: ${nums.length}';
        })
        ..select((nums: list, filter: 'test'))
        ..select((nums: list, filter: 'changed'));
      expect(computeCount, equals(2));
    });

    test('resets cache state variables', () {
      var computeCount = 0;
      final list = [1, 2, 3];
      const filter = 'test';

      final selector =
          ResettableSelector.create2<
            ({List<int> nums, String filter}),
            List<int>,
            String,
            String
          >((s) => s.nums, (s) => s.filter, (nums, f) {
            computeCount++;
            return '$f: ${nums.length}';
          });

      final state = (nums: list, filter: filter);
      selector.select(state);
      expect(computeCount, equals(1));

      selector
        ..resetCache()
        ..select(state);
      expect(computeCount, equals(2));
    });
  });

  group('createSelector1 hasCache behavior', () {
    test('first call always computes', () {
      var computeCount = 0;
      final list = [1, 2, 3];

      final selector = createSelector1<({List<int> nums}), List<int>, int>(
        (s) => s.nums,
        (nums) {
          computeCount++;
          return nums.length;
        },
      );

      final state = (nums: list);
      final result = selector(state);
      expect(result, equals(3));
      expect(computeCount, equals(1));
    });

    test('caches after first call', () {
      var computeCount = 0;
      final list = [1, 2, 3];

      final selector = createSelector1<({List<int> nums}), List<int>, int>(
        (s) => s.nums,
        (nums) {
          computeCount++;
          return nums.length;
        },
      );

      final state = (nums: list);
      selector(state);
      selector(state);
      selector(state);
      expect(computeCount, equals(1));
    });
  });

  group('createSelector2 hasCache behavior', () {
    test('first call always computes', () {
      var computeCount = 0;

      final selector = createSelector2<State2, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (a, b) {
          computeCount++;
          return a + b;
        },
      );

      const state = (a: 1, b: 2);
      final result = selector(state);
      expect(result, equals(3));
      expect(computeCount, equals(1));
    });

    test('caches when both inputs identical', () {
      var computeCount = 0;

      final selector = createSelector2<State2, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (a, b) {
          computeCount++;
          return a + b;
        },
      );

      const state = (a: 1, b: 2);
      selector(state);
      selector(state);
      selector(state);
      expect(computeCount, equals(1));
    });

    test('recomputes only when input1 changes', () {
      var computeCount = 0;

      final selector = createSelector2<State2, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (a, b) {
          computeCount++;
          return a + b;
        },
      );

      selector((a: 1, b: 2));
      expect(computeCount, equals(1));

      selector((a: 100, b: 2));
      expect(computeCount, equals(2));
    });

    test('recomputes only when input2 changes', () {
      var computeCount = 0;

      final selector = createSelector2<State2, int, int, int>(
        (s) => s.a,
        (s) => s.b,
        (a, b) {
          computeCount++;
          return a + b;
        },
      );

      selector((a: 1, b: 2));
      expect(computeCount, equals(1));

      selector((a: 1, b: 200));
      expect(computeCount, equals(2));
    });
  });

  group('createStructuredSelector hasCache behavior', () {
    test('first call always computes', () {
      var computeCount = 0;

      final selector = createStructuredSelector<({int value}), int>((state) {
        computeCount++;
        return state.value * 2;
      });

      const state = (value: 5);
      final result = selector(state);
      expect(result, equals(10));
      expect(computeCount, equals(1));
    });

    test('caches when state identical', () {
      var computeCount = 0;

      final selector = createStructuredSelector<({int value}), int>((state) {
        computeCount++;
        return state.value * 2;
      });

      const state = (value: 5);
      selector(state);
      selector(state);
      selector(state);
      expect(computeCount, equals(1));
    });

    test('recomputes when state changes', () {
      var computeCount = 0;

      final selector = createStructuredSelector<({int value}), int>((state) {
        computeCount++;
        return state.value * 2;
      });

      selector((value: 5));
      expect(computeCount, equals(1));

      selector((value: 10));
      expect(computeCount, equals(2));
    });
  });

  // Tests to kill hasCache = false → true mutations by using null inputs
  // When input is null and lastInput is null, identical(null, null) = true
  // If hasCache starts as true (mutation), it would return null instead of
  // computing

  group('createSelector3 null input handling', () {
    test('first call computes even with null inputs', () {
      final selector =
          createSelector3<({int? a, int? b, int? c}), int?, int?, int?, String>(
            (s) => s.a,
            (s) => s.b,
            (s) => s.c,
            (a, b, c) => 'a=$a,b=$b,c=$c',
          );

      final result = selector((a: null, b: null, c: null));
      expect(result, isNotNull);
      expect(result, equals('a=null,b=null,c=null'));
    });
  });

  group('createSelector4 null input handling', () {
    test('first call computes even with null inputs', () {
      final selector =
          createSelector4<
            ({int? a, int? b, int? c, int? d}),
            int?,
            int?,
            int?,
            int?,
            String
          >(
            (s) => s.a,
            (s) => s.b,
            (s) => s.c,
            (s) => s.d,
            (a, b, c, d) => 'r=$a$b$c$d',
          );

      final result = selector((a: null, b: null, c: null, d: null));
      expect(result, isNotNull);
      expect(result, equals('r=nullnullnullnull'));
    });
  });

  group('createSelector5 null input handling', () {
    test('first call computes even with null inputs', () {
      final selector =
          createSelector5<
            ({int? a, int? b, int? c, int? d, int? e}),
            int?,
            int?,
            int?,
            int?,
            int?,
            String
          >(
            (s) => s.a,
            (s) => s.b,
            (s) => s.c,
            (s) => s.d,
            (s) => s.e,
            (a, b, c, d, e) => 'r=$a$b$c$d$e',
          );

      final result = selector((a: null, b: null, c: null, d: null, e: null));
      expect(result, isNotNull);
      expect(result, equals('r=nullnullnullnullnull'));
    });
  });

  group('ResettableSelector.create1 null input handling', () {
    test('first call computes even with null input', () {
      final selector = ResettableSelector.create1<({int? value}), int?, String>(
        (s) => s.value,
        (v) => 'val=$v',
      );

      final result = selector.select((value: null));
      expect(result, isNotNull);
      expect(result, equals('val=null'));
    });

    test('after reset computes even with null input', () {
      final selector =
          ResettableSelector.create1<({int? value}), int?, String>(
              (s) => s.value,
              (v) => 'val=$v',
            )
            ..select((value: 42))
            ..resetCache();
      final result = selector.select((value: null));
      expect(result, isNotNull);
      expect(result, equals('val=null'));
    });
  });

  group('ResettableSelector.create2 null input handling', () {
    test('first call computes even with null inputs', () {
      final selector =
          ResettableSelector.create2<({int? a, int? b}), int?, int?, String>(
            (s) => s.a,
            (s) => s.b,
            (a, b) => 'a=$a,b=$b',
          );

      final result = selector.select((a: null, b: null));
      expect(result, isNotNull);
      expect(result, equals('a=null,b=null'));
    });

    test('after reset computes even with null inputs', () {
      final selector =
          ResettableSelector.create2<({int? a, int? b}), int?, int?, String>(
              (s) => s.a,
              (s) => s.b,
              (a, b) => 'a=$a,b=$b',
            )
            ..select((a: 1, b: 2))
            ..resetCache();
      final result = selector.select((a: null, b: null));
      expect(result, isNotNull);
      expect(result, equals('a=null,b=null'));
    });
  });
}
