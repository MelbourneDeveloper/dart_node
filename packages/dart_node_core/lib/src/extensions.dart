/// Extension methods FP style transformations
extension NullableExtensions<T extends Object> on T? {
  /// Pattern match on nullable value with cases for non-null and null.
  R match<R>({required R Function(T) some, required R Function() none}) =>
      switch (this) {
        final T value => some(value),
        null => none(),
      };
}

/// Extension methods FP style transformations
extension ObjectExtensions<T extends Object> on T {
  /// Apply function [op] to this value if non-null and return the result.
  R let<R>(R Function(T) op) => op(this);
}
