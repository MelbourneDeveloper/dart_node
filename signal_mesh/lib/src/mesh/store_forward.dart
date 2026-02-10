import 'dart:typed_data';

import 'package:nadz/nadz.dart';

import '../dht/node_id.dart';
import '../protocol/message.dart';

/// A message queued for offline delivery.
typedef QueuedMessage = ({
  WireMessage message,
  int deliveryAttempts,
  DateTime queuedAt,
  DateTime? lastAttempt,
});

/// Store-and-forward queue for offline peers.
/// Each node maintains queues for its direct contacts.
typedef MessageQueue = ({
  Map<String, List<QueuedMessage>> queues,
  int maxQueueSize,
  int maxTtlSeconds,
});

/// Creates an empty message queue.
MessageQueue createMessageQueue({
  int maxQueueSize = 1000,
  int maxTtlSeconds = 86400 * 7, // 7 days
}) => (
  queues: <String, List<QueuedMessage>>{},
  maxQueueSize: maxQueueSize,
  maxTtlSeconds: maxTtlSeconds,
);

/// Enqueues a message for later delivery to an offline peer.
Result<MessageQueue, String> enqueueMessage(
  MessageQueue queue,
  NodeId recipient,
  WireMessage message,
) {
  final key = nodeIdToHex(recipient);
  final peerQueue = List<QueuedMessage>.from(queue.queues[key] ?? []);

  // Check queue size limit
  if (peerQueue.length >= queue.maxQueueSize) {
    // Remove oldest message to make room
    peerQueue.removeAt(0);
  }

  peerQueue.add((
    message: message,
    deliveryAttempts: 0,
    queuedAt: DateTime.now(),
    lastAttempt: null,
  ));

  final updatedQueues = Map<String, List<QueuedMessage>>.from(queue.queues)
    ..[key] = peerQueue;

  return Success((
    queues: updatedQueues,
    maxQueueSize: queue.maxQueueSize,
    maxTtlSeconds: queue.maxTtlSeconds,
  ));
}

/// Dequeues all pending messages for a peer that just came online.
(MessageQueue, List<WireMessage>) dequeueMessages(
  MessageQueue queue,
  NodeId recipient,
) {
  final key = nodeIdToHex(recipient);
  final peerQueue = queue.queues[key] ?? [];

  if (peerQueue.isEmpty) return (queue, []);

  final now = DateTime.now();
  final validMessages = peerQueue
      .where((qm) {
        final age = now.difference(qm.queuedAt).inSeconds;
        return age < queue.maxTtlSeconds;
      })
      .map((qm) => qm.message)
      .toList();

  final updatedQueues = Map<String, List<QueuedMessage>>.from(queue.queues)
    ..remove(key);

  return (
    (
      queues: updatedQueues,
      maxQueueSize: queue.maxQueueSize,
      maxTtlSeconds: queue.maxTtlSeconds,
    ),
    validMessages,
  );
}

/// Returns the number of queued messages for a specific peer.
int queuedCount(MessageQueue queue, NodeId recipient) =>
    queue.queues[nodeIdToHex(recipient)]?.length ?? 0;

/// Returns the total number of queued messages across all peers.
int totalQueued(MessageQueue queue) =>
    queue.queues.values.fold(0, (sum, q) => sum + q.length);

/// Cleans expired messages from all queues.
MessageQueue cleanExpiredMessages(MessageQueue queue) {
  final now = DateTime.now();
  final cleaned = <String, List<QueuedMessage>>{};

  for (final entry in queue.queues.entries) {
    final validMessages = entry.value.where((qm) {
      final age = now.difference(qm.queuedAt).inSeconds;
      return age < queue.maxTtlSeconds;
    }).toList();
    if (validMessages.isNotEmpty) {
      cleaned[entry.key] = validMessages;
    }
  }

  return (
    queues: cleaned,
    maxQueueSize: queue.maxQueueSize,
    maxTtlSeconds: queue.maxTtlSeconds,
  );
}

/// Marks a queued message as having had a delivery attempt.
MessageQueue markDeliveryAttempt(
  MessageQueue queue,
  NodeId recipient,
  String messageId,
) {
  final key = nodeIdToHex(recipient);
  final peerQueue = queue.queues[key];
  if (peerQueue == null) return queue;

  final updated = peerQueue.map((qm) {
    if (qm.message.id != messageId) return qm;
    return (
      message: qm.message,
      deliveryAttempts: qm.deliveryAttempts + 1,
      queuedAt: qm.queuedAt,
      lastAttempt: DateTime.now(),
    );
  }).toList();

  final updatedQueues = Map<String, List<QueuedMessage>>.from(queue.queues)
    ..[key] = updated;

  return (
    queues: updatedQueues,
    maxQueueSize: queue.maxQueueSize,
    maxTtlSeconds: queue.maxTtlSeconds,
  );
}
