/// Tests for dart_node_core package.
@TestOn('node')
library;

import 'dart:js_interop';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);

  group('requireModule', () {
    test('loads fs module', () {
      final fs = requireModule('fs');
      expect(fs.isA<JSObject>(), isTrue);
    });

    test('loads path module', () {
      final pathModule = requireModule('path');
      expect(pathModule.isA<JSObject>(), isTrue);
    });

    test('loads crypto module', () {
      final crypto = requireModule('crypto');
      expect(crypto.isA<JSObject>(), isTrue);
    });
  });

  group('require function', () {
    test('is available from global context', () {
      expect(require.isA<JSFunction>(), isTrue);
    });
  });

  group('console', () {
    test('is available from global context', () {
      expect(console.isA<JSObject>(), isTrue);
    });

    test('consoleLog does not throw', () {
      expect(() => consoleLog('test message'), returnsNormally);
    });
  });

  group('getGlobal', () {
    test('returns process object', () {
      final process = getGlobal('process');
      expect(process, isNotNull);
      expect(process!.isA<JSObject>(), isTrue);
    });

    test('returns null for non-existent global', () {
      final nonExistent = getGlobal('__non_existent_global_12345__');
      expect(nonExistent, isNull);
    });
  });

  group('NullableExtensions', () {
    test('match calls some for non-null value', () {
      const value = 'hello';
      final result = value.match(some: (v) => 'got: $v', none: () => 'nothing');
      expect(result, equals('got: hello'));
    });

    test('match calls none for null value', () {
      const String? value = null;
      final result = value.match(some: (v) => 'got: $v', none: () => 'nothing');
      expect(result, equals('nothing'));
    });
  });

  group('ObjectExtensions', () {
    test('let applies function to value', () {
      final result = 'hello'.let((s) => s.toUpperCase());
      expect(result, equals('HELLO'));
    });

    test('let chains transformations', () {
      final result = 5.let((n) => n * 2).let((n) => n + 1);
      expect(result, equals(11));
    });
  });

  group('withRetry', () {
    test('returns success on first attempt', () {
      var attempts = 0;
      final result = withRetry(defaultRetryPolicy, (e) => true, () {
        attempts++;
        return const Success<int, String>(42);
      });
      expect(result, isA<Success<int, String>>());
      expect((result as Success<int, String>).value, equals(42));
      expect(attempts, equals(1));
    });

    test('retries on retryable error', () {
      var attempts = 0;
      final result = withRetry(
        (maxAttempts: 3, baseDelayMs: 1, backoffMultiplier: 1.0),
        (e) => e.contains('transient'),
        () {
          attempts++;
          if (attempts < 3) {
            return const Error<int, String>('transient error');
          }
          return const Success<int, String>(42);
        },
      );
      expect(result, isA<Success<int, String>>());
      expect(attempts, equals(3));
    });

    test('does not retry on non-retryable error', () {
      var attempts = 0;
      final result = withRetry(
        defaultRetryPolicy,
        (e) => e.contains('transient'),
        () {
          attempts++;
          return const Error<int, String>('permanent error');
        },
      );
      expect(result, isA<Error<int, String>>());
      expect(attempts, equals(1));
    });

    test('stops after max attempts', () {
      var attempts = 0;
      final result = withRetry(
        (maxAttempts: 3, baseDelayMs: 1, backoffMultiplier: 1.0),
        (e) => true,
        () {
          attempts++;
          return const Error<int, String>('always fails');
        },
      );
      expect(result, isA<Error<int, String>>());
      expect(attempts, equals(3));
    });

    test('calls onRetry callback', () {
      final retryLog = <(int, String, int)>[];
      withRetry(
        (maxAttempts: 3, baseDelayMs: 10, backoffMultiplier: 2.0),
        (e) => true,
        () => const Error<int, String>('error'),
        onRetry: (attempt, error, delayMs) {
          retryLog.add((attempt, error, delayMs));
        },
      );
      expect(retryLog.length, equals(2));
      expect(retryLog[0].$1, equals(1));
      expect(retryLog[0].$3, equals(10));
      expect(retryLog[1].$1, equals(2));
      expect(retryLog[1].$3, equals(20));
    });
  });

  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));
}
