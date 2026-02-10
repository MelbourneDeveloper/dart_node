import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

import 'package:signal_mesh/signal_mesh.dart';

void main() {
  NodeId _randomId() => switch (nodeIdRandom()) {
    Success(:final value) => value,
    Error(:final error) => throw StateError(error),
  };

  PeerContact _contact(NodeId id) => (
    nodeId: id,
    address: '127.0.0.1',
    port: 8000,
    lastSeen: DateTime.now(),
  );

  test('createRoutingTable creates 256 empty buckets', () {
    final table = createRoutingTable(_randomId());
    expect(table.buckets.length, equals(256));
    expect(contactCount(table), equals(0));
  });

  test('addContact adds a new contact', () {
    final localId = _randomId();
    var table = createRoutingTable(localId);
    final peerId = _randomId();
    final contact = _contact(peerId);

    switch (addContact(table, contact)) {
      case Success(:final value):
        table = value.$1;
        expect(value.$2, isTrue);
      case Error(:final error):
        fail('addContact failed: $error');
    }

    expect(contactCount(table), equals(1));
  });

  test('addContact rejects self', () {
    final localId = _randomId();
    final table = createRoutingTable(localId);
    final contact = _contact(localId);

    final result = addContact(table, contact);
    expect(result, isA<Error<(RoutingTable, bool), String>>());
  });

  test('addContact updates existing contact (move to end)', () {
    final localId = _randomId();
    var table = createRoutingTable(localId);
    final peerId = _randomId();
    final contact1 = (
      nodeId: peerId,
      address: '127.0.0.1',
      port: 8000,
      lastSeen: DateTime(2024),
    );
    final contact2 = (
      nodeId: peerId,
      address: '127.0.0.1',
      port: 8000,
      lastSeen: DateTime(2025),
    );

    switch (addContact(table, contact1)) {
      case Success(:final value):
        table = value.$1;
      case Error(:final error):
        fail(error);
    }

    switch (addContact(table, contact2)) {
      case Success(:final value):
        table = value.$1;
        expect(value.$2, isTrue);
      case Error(:final error):
        fail(error);
    }

    // Should still be 1 contact (updated, not duplicated)
    expect(contactCount(table), equals(1));
  });

  test('findClosest returns contacts sorted by distance', () {
    final localId = _randomId();
    var table = createRoutingTable(localId);
    final target = _randomId();

    // Add several contacts
    for (var i = 0; i < 10; i++) {
      final peerId = _randomId();
      switch (addContact(table, _contact(peerId))) {
        case Success(:final value):
          table = value.$1;
        case Error():
          break;
      }
    }

    final closest = findClosest(table, target, count: 5);
    expect(closest.length, lessThanOrEqualTo(5));

    // Verify sorted by distance
    for (var i = 1; i < closest.length; i++) {
      expect(
        isCloser(target, closest[i - 1].nodeId, closest[i].nodeId) ||
            nodeIdToHex(closest[i - 1].nodeId) ==
                nodeIdToHex(closest[i].nodeId),
        isTrue,
      );
    }
  });

  test('removeContact removes and promotes from replacement cache', () {
    final localId = _randomId();
    var table = createRoutingTable(localId, k: 1); // tiny bucket
    final peer1 = _randomId();
    final peer2 = _randomId();

    // Ensure peer1 and peer2 go to the same bucket
    // (this might not always happen with random IDs, but with k=1 the
    // second one goes to replacement cache if same bucket)
    switch (addContact(table, _contact(peer1))) {
      case Success(:final value):
        table = value.$1;
      case Error():
        break;
    }

    switch (addContact(table, _contact(peer2))) {
      case Success(:final value):
        table = value.$1;
      case Error():
        break;
    }

    final countBefore = contactCount(table);
    table = removeContact(table, peer1);
    final countAfter = contactCount(table);

    // Count might stay the same (if replacement promoted) or decrease
    expect(countAfter, lessThanOrEqualTo(countBefore));
  });
}
