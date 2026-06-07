import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

import 'package:signal_mesh/signal_mesh.dart';

void main() {
  NodeId _randomId() => switch (nodeIdRandom()) {
    Success(:final value) => value,
    Error(:final error) => throw StateError(error),
  };

  test('createKademliaState creates empty DHT', () {
    final state = createKademliaState(_randomId());
    expect(contactCount(state.routingTable), equals(0));
    expect(state.storage, isEmpty);
  });

  test('handleFindNode adds sender to routing table', () {
    final localId = _randomId();
    var state = createKademliaState(localId);
    final senderId = _randomId();

    final request = (
      sender: senderId,
      target: _randomId(),
      senderAddress: '127.0.0.1',
      senderPort: 9000,
    );

    switch (handleFindNode(state, request)) {
      case Success(:final value):
        state = value.$1;
        expect(contactCount(state.routingTable), equals(1));
      case Error(:final error):
        fail('handleFindNode failed: $error');
    }
  });

  test('handleFindNode returns closest contacts', () {
    final localId = _randomId();
    var state = createKademliaState(localId);

    // Populate with some contacts
    for (var i = 0; i < 5; i++) {
      final request = (
        sender: _randomId(),
        target: localId,
        senderAddress: '127.0.0.1',
        senderPort: 9000 + i,
      );
      switch (handleFindNode(state, request)) {
        case Success(:final value):
          state = value.$1;
        case Error():
          break;
      }
    }

    final target = _randomId();
    final request = (
      sender: _randomId(),
      target: target,
      senderAddress: '127.0.0.1',
      senderPort: 8000,
    );

    switch (handleFindNode(state, request)) {
      case Success(:final value):
        final response = value.$2;
        expect(response.closestNodes, isNotEmpty);
      case Error(:final error):
        fail(error);
    }
  });

  test('handleStore stores value with TTL', () {
    final localId = _randomId();
    var state = createKademliaState(localId);
    final key = _randomId();

    final request = (
      sender: _randomId(),
      key: key,
      value: [1, 2, 3, 4, 5],
      ttlSeconds: 3600,
      senderAddress: '127.0.0.1',
      senderPort: 9000,
    );

    switch (handleStore(state, request)) {
      case Success(:final value):
        state = value;
        expect(state.storage, isNotEmpty);
        final stored = state.storage[nodeIdToHex(key)];
        expect(stored, isNotNull);
        expect(stored?.value, equals([1, 2, 3, 4, 5]));
      case Error(:final error):
        fail(error);
    }
  });

  test('handleFindValue returns stored value', () {
    final localId = _randomId();
    var state = createKademliaState(localId);
    final key = _randomId();

    // Store a value first
    final storeReq = (
      sender: _randomId(),
      key: key,
      value: [10, 20, 30],
      ttlSeconds: 3600,
      senderAddress: '127.0.0.1',
      senderPort: 9000,
    );
    switch (handleStore(state, storeReq)) {
      case Success(:final value):
        state = value;
      case Error(:final error):
        fail(error);
    }

    // Now look it up
    final findReq = (
      sender: _randomId(),
      target: key,
      senderAddress: '127.0.0.1',
      senderPort: 9001,
    );

    switch (handleFindValue(state, key, findReq)) {
      case Success(:final value):
        final response = value.$2;
        expect(response.value, equals([10, 20, 30]));
        expect(response.closestNodes, isNull);
      case Error(:final error):
        fail(error);
    }
  });

  test('handleFindValue returns closest nodes when value not found', () {
    final localId = _randomId();
    var state = createKademliaState(localId);

    // Add some peers
    for (var i = 0; i < 3; i++) {
      final req = (
        sender: _randomId(),
        target: localId,
        senderAddress: '127.0.0.1',
        senderPort: 9000 + i,
      );
      switch (handleFindNode(state, req)) {
        case Success(:final value):
          state = value.$1;
        case Error():
          break;
      }
    }

    final key = _randomId();
    final findReq = (
      sender: _randomId(),
      target: key,
      senderAddress: '127.0.0.1',
      senderPort: 9010,
    );

    switch (handleFindValue(state, key, findReq)) {
      case Success(:final value):
        final response = value.$2;
        expect(response.value, isNull);
        expect(response.closestNodes, isNotNull);
      case Error(:final error):
        fail(error);
    }
  });

  test('cleanExpired removes old entries', () {
    final localId = _randomId();
    var state = createKademliaState(localId);
    final key = _randomId();

    // Store with 0 second TTL (already expired)
    final storeReq = (
      sender: _randomId(),
      key: key,
      value: [1],
      ttlSeconds: 0,
      senderAddress: '127.0.0.1',
      senderPort: 9000,
    );
    switch (handleStore(state, storeReq)) {
      case Success(:final value):
        state = value;
      case Error(:final error):
        fail(error);
    }

    expect(state.storage, isNotEmpty);
    state = cleanExpired(state);
    expect(state.storage, isEmpty);
  });

  test('iterativeFindNode converges on closest nodes', () async {
    final localId = _randomId();
    var state = createKademliaState(localId);

    // Populate with contacts
    for (var i = 0; i < 10; i++) {
      final req = (
        sender: _randomId(),
        target: localId,
        senderAddress: '127.0.0.1',
        senderPort: 9000 + i,
      );
      switch (handleFindNode(state, req)) {
        case Success(:final value):
          state = value.$1;
        case Error():
          break;
      }
    }

    final target = _randomId();
    final results = await iterativeFindNode(
      state,
      target,
      sendFindNode: (_, __) async => null, // no network
    );

    expect(results, isNotEmpty);
    expect(results.length, lessThanOrEqualTo(defaultK));
  });
}
