import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

import 'package:signal_mesh/signal_mesh.dart';

void main() {
  NodeId _randomId() => switch (nodeIdRandom()) {
    Success(:final value) => value,
    Error(:final error) => throw StateError(error),
  };

  test('createMessageQueue starts empty', () {
    final queue = createMessageQueue();
    expect(totalQueued(queue), equals(0));
  });

  test('enqueueMessage adds message to queue', () {
    var queue = createMessageQueue();
    final recipient = _randomId();
    final msg = createWireMessage(
      type: MessageType.chat,
      sender: _randomId(),
      recipient: recipient,
      payload: {'text': 'offline msg'},
    );

    switch (enqueueMessage(queue, recipient, msg)) {
      case Success(:final value):
        queue = value;
      case Error(:final error):
        fail(error);
    }

    expect(queuedCount(queue, recipient), equals(1));
    expect(totalQueued(queue), equals(1));
  });

  test('dequeueMessages returns all pending and clears queue', () {
    var queue = createMessageQueue();
    final recipient = _randomId();

    for (var i = 0; i < 3; i++) {
      final msg = createWireMessage(
        type: MessageType.chat,
        sender: _randomId(),
        recipient: recipient,
        payload: {'index': i},
      );
      switch (enqueueMessage(queue, recipient, msg)) {
        case Success(:final value):
          queue = value;
        case Error(:final error):
          fail(error);
      }
    }

    expect(totalQueued(queue), equals(3));

    final (updatedQueue, messages) = dequeueMessages(queue, recipient);
    expect(messages.length, equals(3));
    expect(totalQueued(updatedQueue), equals(0));
  });

  test('dequeueMessages returns empty for unknown peer', () {
    final queue = createMessageQueue();
    final (_, messages) = dequeueMessages(queue, _randomId());
    expect(messages, isEmpty);
  });

  test('enqueueMessage evicts oldest when queue full', () {
    var queue = createMessageQueue(maxQueueSize: 2);
    final recipient = _randomId();

    for (var i = 0; i < 3; i++) {
      final msg = createWireMessage(
        type: MessageType.chat,
        sender: _randomId(),
        payload: {'index': i},
      );
      switch (enqueueMessage(queue, recipient, msg)) {
        case Success(:final value):
          queue = value;
        case Error(:final error):
          fail(error);
      }
    }

    // Queue capped at 2
    expect(queuedCount(queue, recipient), equals(2));
  });

  test('cleanExpiredMessages removes old messages', () {
    var queue = createMessageQueue(maxTtlSeconds: 0); // instant expiry
    final recipient = _randomId();
    final msg = createWireMessage(
      type: MessageType.chat,
      sender: _randomId(),
      payload: {},
    );

    switch (enqueueMessage(queue, recipient, msg)) {
      case Success(:final value):
        queue = value;
      case Error(:final error):
        fail(error);
    }

    expect(totalQueued(queue), equals(1));
    queue = cleanExpiredMessages(queue);
    expect(totalQueued(queue), equals(0));
  });

  test('markDeliveryAttempt increments attempt count', () {
    var queue = createMessageQueue();
    final recipient = _randomId();
    final msg = createWireMessage(
      type: MessageType.chat,
      sender: _randomId(),
      payload: {},
    );

    switch (enqueueMessage(queue, recipient, msg)) {
      case Success(:final value):
        queue = value;
      case Error(:final error):
        fail(error);
    }

    queue = markDeliveryAttempt(queue, recipient, msg.id);

    final peerQueue = queue.queues[nodeIdToHex(recipient)];
    expect(peerQueue, isNotNull);
    expect(peerQueue?.first.deliveryAttempts, equals(1));
    expect(peerQueue?.first.lastAttempt, isNotNull);
  });

  test('multiple recipients maintain separate queues', () {
    var queue = createMessageQueue();
    final r1 = _randomId();
    final r2 = _randomId();

    for (var i = 0; i < 2; i++) {
      final msg = createWireMessage(
        type: MessageType.chat,
        sender: _randomId(),
        payload: {},
      );
      switch (enqueueMessage(queue, r1, msg)) {
        case Success(:final value):
          queue = value;
        case Error(:final error):
          fail(error);
      }
    }

    final msg = createWireMessage(
      type: MessageType.chat,
      sender: _randomId(),
      payload: {},
    );
    switch (enqueueMessage(queue, r2, msg)) {
      case Success(:final value):
        queue = value;
      case Error(:final error):
        fail(error);
    }

    expect(queuedCount(queue, r1), equals(2));
    expect(queuedCount(queue, r2), equals(1));
    expect(totalQueued(queue), equals(3));
  });
}
