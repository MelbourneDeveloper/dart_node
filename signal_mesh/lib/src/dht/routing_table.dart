import 'dart:typed_data';

import 'package:nadz/nadz.dart';

import 'node_id.dart';

/// Contact information for a known peer in the DHT.
typedef PeerContact = ({
  NodeId nodeId,
  String address,
  int port,
  DateTime lastSeen,
});

/// A k-bucket holds up to k contacts at the same XOR distance range.
typedef KBucket = ({
  List<PeerContact> contacts,
  List<PeerContact> replacementCache,
});

/// Kademlia routing table: 256 k-buckets indexed by XOR distance.
typedef RoutingTable = ({
  NodeId localId,
  int k,
  List<KBucket> buckets,
});

/// Default replication parameter (number of closest nodes to query).
const defaultK = 20;

/// Default concurrency parameter for parallel lookups.
const defaultAlpha = 3;

/// Creates a new empty routing table for the given local node.
RoutingTable createRoutingTable(NodeId localId, {int k = defaultK}) => (
  localId: localId,
  k: k,
  buckets: List.generate(
    256,
    (_) => (contacts: <PeerContact>[], replacementCache: <PeerContact>[]),
  ),
);

/// Adds or updates a peer contact in the routing table.
/// Returns the updated table and whether the contact was added.
Result<(RoutingTable, bool), String> addContact(
  RoutingTable table,
  PeerContact contact,
) {
  final idx = bucketIndex(table.localId, contact.nodeId);
  if (idx < 0) return Error('Cannot add self to routing table');

  final bucket = table.buckets[idx];
  final existingIdx = bucket.contacts.indexWhere(
    (c) => _nodeIdsEqual(c.nodeId, contact.nodeId),
  );

  // Already exists - move to end (most recently seen)
  if (existingIdx >= 0) {
    final updatedContacts = List<PeerContact>.from(bucket.contacts)
      ..removeAt(existingIdx)
      ..add(contact);
    final newBuckets = List<KBucket>.from(table.buckets);
    newBuckets[idx] = (
      contacts: updatedContacts,
      replacementCache: bucket.replacementCache,
    );
    return Success((
      (localId: table.localId, k: table.k, buckets: newBuckets),
      true,
    ));
  }

  // Bucket not full - add directly
  if (bucket.contacts.length < table.k) {
    final updatedContacts = List<PeerContact>.from(bucket.contacts)
      ..add(contact);
    final newBuckets = List<KBucket>.from(table.buckets);
    newBuckets[idx] = (
      contacts: updatedContacts,
      replacementCache: bucket.replacementCache,
    );
    return Success((
      (localId: table.localId, k: table.k, buckets: newBuckets),
      true,
    ));
  }

  // Bucket full - add to replacement cache
  final updatedCache = List<PeerContact>.from(bucket.replacementCache);
  final cacheIdx = updatedCache.indexWhere(
    (c) => _nodeIdsEqual(c.nodeId, contact.nodeId),
  );
  if (cacheIdx >= 0) updatedCache.removeAt(cacheIdx);
  updatedCache.add(contact);

  // Cap replacement cache at 2*k
  while (updatedCache.length > table.k * 2) {
    updatedCache.removeAt(0);
  }

  final newBuckets = List<KBucket>.from(table.buckets);
  newBuckets[idx] = (
    contacts: bucket.contacts,
    replacementCache: updatedCache,
  );
  return Success((
    (localId: table.localId, k: table.k, buckets: newBuckets),
    false,
  ));
}

/// Removes a peer from the routing table and promotes from replacement cache.
RoutingTable removeContact(RoutingTable table, NodeId nodeId) {
  final idx = bucketIndex(table.localId, nodeId);
  if (idx < 0) return table;

  final bucket = table.buckets[idx];
  final contactIdx = bucket.contacts.indexWhere(
    (c) => _nodeIdsEqual(c.nodeId, nodeId),
  );

  if (contactIdx < 0) return table;

  final updatedContacts = List<PeerContact>.from(bucket.contacts)
    ..removeAt(contactIdx);

  // Promote from replacement cache if available
  final updatedCache = List<PeerContact>.from(bucket.replacementCache);
  if (updatedCache.isNotEmpty) {
    updatedContacts.add(updatedCache.removeLast());
  }

  final newBuckets = List<KBucket>.from(table.buckets);
  newBuckets[idx] = (
    contacts: updatedContacts,
    replacementCache: updatedCache,
  );

  return (localId: table.localId, k: table.k, buckets: newBuckets);
}

/// Finds the k closest contacts to a target NodeId.
List<PeerContact> findClosest(
  RoutingTable table,
  NodeId target, {
  int? count,
}) {
  final k = count ?? table.k;
  final allContacts =
      table.buckets.expand((bucket) => bucket.contacts).toList();

  allContacts.sort((a, b) {
    final distA = xorDistance(target, a.nodeId);
    final distB = xorDistance(target, b.nodeId);
    return _compareDistances(distA, distB);
  });

  return allContacts.take(k).toList();
}

/// Returns total number of known contacts.
int contactCount(RoutingTable table) =>
    table.buckets.fold(0, (sum, b) => sum + b.contacts.length);

int _compareDistances(Uint8List a, Uint8List b) {
  for (var i = 0; i < 32; i++) {
    if (a[i] < b[i]) return -1;
    if (a[i] > b[i]) return 1;
  }
  return 0;
}

bool _nodeIdsEqual(NodeId a, NodeId b) {
  for (var i = 0; i < 32; i++) {
    if (a.bytes[i] != b.bytes[i]) return false;
  }
  return true;
}
