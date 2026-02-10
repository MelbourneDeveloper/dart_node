import 'dart:typed_data';

import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

import 'package:signal_mesh/signal_mesh.dart';

void main() {
  test('nodeIdFromBytes rejects wrong length', () {
    final result = nodeIdFromBytes(Uint8List(16));
    expect(result, isA<Error<NodeId, String>>());
  });

  test('nodeIdFromBytes accepts 32 bytes', () {
    final result = nodeIdFromBytes(Uint8List(32));
    switch (result) {
      case Success(:final value):
        expect(value.bytes.length, equals(32));
      case Error(:final error):
        fail('Expected success, got error: $error');
    }
  });

  test('nodeIdRandom produces unique IDs', () {
    final a = switch (nodeIdRandom()) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    final b = switch (nodeIdRandom()) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    expect(nodeIdToHex(a), isNot(equals(nodeIdToHex(b))));
  });

  test('xorDistance is symmetric', () {
    final a = switch (nodeIdRandom()) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    final b = switch (nodeIdRandom()) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    final dAB = xorDistance(a, b);
    final dBA = xorDistance(b, a);
    for (var i = 0; i < 32; i++) {
      expect(dAB[i], equals(dBA[i]));
    }
  });

  test('xorDistance to self is zero', () {
    final a = switch (nodeIdRandom()) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    final d = xorDistance(a, a);
    for (var i = 0; i < 32; i++) {
      expect(d[i], equals(0));
    }
  });

  test('bucketIndex returns -1 for identical nodes', () {
    final a = switch (nodeIdRandom()) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    expect(bucketIndex(a, a), equals(-1));
  });

  test('bucketIndex returns valid range for different nodes', () {
    final a = switch (nodeIdRandom()) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    final b = switch (nodeIdRandom()) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    final idx = bucketIndex(a, b);
    expect(idx, greaterThanOrEqualTo(0));
    expect(idx, lessThan(256));
  });

  test('isCloser correctly identifies closer node', () {
    // Manually construct nodes where distance is predictable
    final target = nodeIdFromBytes(Uint8List(32));
    final close = nodeIdFromBytes(
      Uint8List(32)..[31] = 1,
    );
    final far = nodeIdFromBytes(
      Uint8List(32)..[0] = 0xFF,
    );

    switch ((target, close, far)) {
      case (
          Success(value: final t),
          Success(value: final c),
          Success(value: final f),
        ):
        expect(isCloser(t, c, f), isTrue);
        expect(isCloser(t, f, c), isFalse);
      default:
        fail('Failed to create test node IDs');
    }
  });

  test('nodeIdToHex produces 64 char hex string', () {
    final id = switch (nodeIdRandom()) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    final hex = nodeIdToHex(id);
    expect(hex.length, equals(64));
    expect(hex, matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('nodeIdShort produces 8 char prefix', () {
    final id = switch (nodeIdRandom()) {
      Success(:final value) => value,
      Error(:final error) => throw StateError(error),
    };
    final short = nodeIdShort(id);
    expect(short.length, equals(8));
    expect(nodeIdToHex(id).startsWith(short), isTrue);
  });
}
