/// Retry policy for transient errors.
library;

import 'package:nadz/nadz.dart';

/// Retry policy configuration.
typedef RetryPolicy = ({
  int maxAttempts,
  int baseDelayMs,
  double backoffMultiplier,
});

/// Default retry policy: 3 attempts, 50ms base, 2x backoff.
const defaultRetryPolicy = (
  maxAttempts: 3,
  baseDelayMs: 50,
  backoffMultiplier: 2.0,
);

/// Execute operation with retry on transient errors.
///
/// [policy] - Retry configuration
/// [isRetryable] - Function to determine if an error is retryable
/// [operation] - The operation to execute
/// [onRetry] - Optional callback when a retry occurs (for logging)
Result<T, String> withRetry<T>(
  RetryPolicy policy,
  bool Function(String error) isRetryable,
  Result<T, String> Function() operation, {
  void Function(int attempt, String error, int delayMs)? onRetry,
}) {
  var lastError = '';
  var delayMs = policy.baseDelayMs;

  for (var attempt = 1; attempt <= policy.maxAttempts; attempt++) {
    final result = operation();
    if (result case Success()) return result;
    if (result case Error(:final error)) {
      lastError = error;
      if (!isRetryable(error) || attempt == policy.maxAttempts) {
        return result;
      }
      onRetry?.call(attempt, error, delayMs);
      _sleepSync(delayMs);
      delayMs = (delayMs * policy.backoffMultiplier).round();
    }
  }
  return Error(lastError);
}

void _sleepSync(int ms) {
  final end = DateTime.now().millisecondsSinceEpoch + ms;
  while (DateTime.now().millisecondsSinceEpoch < end) {
    // Busy wait - synchronous delay for retry
  }
}
