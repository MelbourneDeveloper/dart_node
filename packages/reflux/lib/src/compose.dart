/// Composes single-argument functions from right to left.
///
/// The rightmost function can take multiple arguments as it provides
/// the signature for the resulting composite function.
///
/// Example:
/// ```dart
/// final add = (int x) => x + 1;
/// final multiply = (int x) => x * 2;
/// final subtract = (int x) => x - 3;
///
/// // Without compose: subtract(multiply(add(5)))
/// // With compose: compose([subtract, multiply, add])(5)
/// final composed = compose([subtract, multiply, add]);
/// print(composed(5)); // ((5 + 1) * 2) - 3 = 9
/// ```
///
/// This is mainly useful for composing store enhancers.
T Function(T) compose<T>(List<T Function(T)> functions) {
  if (functions.isEmpty) return (arg) => arg;
  if (functions.length == 1) return functions.first;

  return functions.reduce(
    (a, b) =>
        (arg) => a(b(arg)),
  );
}

/// Composes functions with different input/output types.
///
/// This is a more flexible version of [compose] that allows for
/// type transformations through the composition chain.
///
/// Example:
/// ```dart
/// final toString = (int x) => x.toString();
/// final addExclaim = (String s) => '$s!';
/// final getLength = (String s) => s.length;
///
/// final pipeline = pipe3(toString, addExclaim, getLength);
/// print(pipeline(42)); // 3 (length of "42!")
/// ```
C Function(A) pipe2<A, B, C>(B Function(A) f1, C Function(B) f2) =>
    (a) => f2(f1(a));

/// Three-function pipeline composition.
D Function(A) pipe3<A, B, C, D>(
  B Function(A) f1,
  C Function(B) f2,
  D Function(C) f3,
) =>
    (a) => f3(f2(f1(a)));

/// Four-function pipeline composition.
E Function(A) pipe4<A, B, C, D, E>(
  B Function(A) f1,
  C Function(B) f2,
  D Function(C) f3,
  E Function(D) f4,
) =>
    (a) => f4(f3(f2(f1(a))));

/// Five-function pipeline composition.
F Function(A) pipe5<A, B, C, D, E, F>(
  B Function(A) f1,
  C Function(B) f2,
  D Function(C) f3,
  E Function(D) f4,
  F Function(E) f5,
) =>
    (a) => f5(f4(f3(f2(f1(a)))));
