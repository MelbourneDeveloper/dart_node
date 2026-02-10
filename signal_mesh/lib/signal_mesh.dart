/// Peer-to-peer encrypted mesh messenger.
///
/// No central server. Kademlia DHT for peer discovery.
/// Double Ratchet for E2E encryption. Phone numbers as identifiers.
library;

export 'src/crypto/key_pair.dart';
export 'src/crypto/double_ratchet.dart';
export 'src/crypto/x3dh.dart';
export 'src/dht/kademlia.dart';
export 'src/dht/node_id.dart';
export 'src/dht/routing_table.dart';
export 'src/transport/peer_connection.dart';
export 'src/transport/transport.dart';
export 'src/identity/phone_attestation.dart';
export 'src/identity/peer_identity.dart';
export 'src/protocol/message.dart';
export 'src/protocol/session.dart';
export 'src/mesh/mesh_node.dart';
export 'src/mesh/store_forward.dart';
