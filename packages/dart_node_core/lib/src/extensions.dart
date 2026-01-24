/// Functional programming extensions for nullable and non-null types.
///
/// Provides pattern matching and transformation utilities inspired by
/// functional programming languages like Kotlin and Rust.
library;

/// Extension methods for nullable values enabling pattern matching and
/// functional transformations.
///
/// Example:
/// ```dart
/// String? getName() => 'World';
///
/// final greeting = getName().match(
///   some: (name) => 'Hello, $name!',
///   none: () => 'Hello, stranger!',
/// );
/// ```
extension NullableExtensions<T extends Object> on T? {
  /// Pattern match on nullable value with cases for non-null and null.
  ///
  /// This provides a safe way to handle nullable values by requiring
  /// explicit handling of both the present (`some`) and absent (`none`) cases.
  ///
  /// **Parameters:**
  /// - `some`: Function called when this value is non-null
  /// - `none`: Function called when this value is null
  ///
  /// **Returns:** The result of calling either `some` or `none`
  ///
  /// Example:
  /// ```dart
  /// int? maybeNumber = 42;
  ///
  /// final result = maybeNumber.match(
  ///   some: (n) => 'Number: $n',
  ///   none: () => 'No number',
  /// ); // Returns: "Number: 42"
  /// ```
  R match<R>({required R Function(T) some, required R Function() none}) =>
      switch (this) {
        final T value => some(value),
        null => none(),
      };
}

/// Extension methods for non-null values enabling functional transformations.
///
/// Provides utilities for applying transformations to values in a functional style.
extension ObjectExtensions<T extends Object> on T {
  /// Apply function [op] to this value and return the result.
  ///
  /// This is useful for chaining operations and avoiding temporary variables.
  /// Also known as the "let" operation in Kotlin or "tap" in other languages.
  ///
  /// **Parameters:**
  /// - `op`: Function that transforms this value into a result of type `R`
  ///
  /// **Returns:** The result of calling `op` with this value
  ///
  /// Example:
  /// ```dart
  /// final length = 'hello world'
  ///     .let((s) => s.split(' '))
  ///     .let((words) => words.length); // Returns: 2
  ///
  /// // Instead of:
  /// final text = 'hello world';
  /// final words = text.split(' ');
  /// final length = words.length;
  /// ```
  R let<R>(R Function(T) op) => op(this);
}
