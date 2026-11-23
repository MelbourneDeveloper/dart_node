/// Result type aliases for TypeScript/React developers.
///
/// Provides `Ok` and `Err` as familiar aliases for `Success` and `Error`.
library;

import 'package:nadz/nadz.dart';

/// Creates a success result (alias for Success).
/// Familiar to TypeScript/Rust developers.
Result<T, E> Ok<T, E>(T value) => Success<T, E>(value);

/// Creates an error result (alias for Error).
/// Familiar to TypeScript/Rust developers.
Result<T, E> Err<T, E>(E error) => Error<T, E>(error);
