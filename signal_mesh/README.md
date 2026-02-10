# signal_mesh

Peer-to-peer encrypted mesh messenger in Dart. No central server.

## Architecture

```
Phone Numbers ──→ Attestation Nodes (stateless, anyone can run)
                         │
                    ┌────┴────┐
                    │ Identity │
                    └────┬────┘
                         │
┌────────────────────────┼────────────────────────┐
│                    Mesh Node                     │
│                                                  │
│  ┌──────────┐  ┌───────────┐  ┌──────────────┐ │
│  │ Kademlia │  │  Session   │  │   Store &    │ │
│  │   DHT    │  │ (X3DH +   │  │   Forward    │ │
│  │          │  │  Double    │  │              │ │
│  │ - Peer   │  │  Ratchet)  │  │ - Offline    │ │
│  │   disc.  │  │            │  │   delivery   │ │
│  │ - k-v    │  │ - E2E enc  │  │ - TTL-based  │ │
│  │   store  │  │ - Forward  │  │ - Per-peer   │ │
│  │          │  │   secrecy  │  │   queues     │ │
│  └────┬─────┘  └─────┬─────┘  └──────┬───────┘ │
│       └───────────────┼───────────────┘         │
│                       │                          │
│              ┌────────┴────────┐                 │
│              │    Transport    │                 │
│              │  TCP / WS / BLE │                 │
│              └─────────────────┘                 │
└──────────────────────────────────────────────────┘
```

## Key Decisions

| Concern | Approach |
|---|---|
| Peer discovery | Kademlia DHT (XOR distance, k-buckets) |
| Encryption | Signal Protocol (X3DH + Double Ratchet) |
| Identity | Phone numbers via decentralized attestation nodes |
| Offline messages | Store-and-forward with TTL |
| NAT traversal | Relay nodes + hole punching (planned) |
| Local discovery | mDNS (planned) |

## Minimal Infrastructure

Even fully P2P, some minimal stateless infrastructure is needed:

- **Bootstrap nodes** - Help new peers join the DHT. Stateless. Anyone can run one.
- **Attestation nodes** - Verify phone numbers via SMS, sign credentials. Stateless.
- **Relay nodes** - Help peers behind NATs connect. Optional.

None of these store messages, user data, or keys.

## Modules

- `crypto/` - X25519 key generation, X3DH key agreement, Double Ratchet
- `dht/` - Kademlia DHT (NodeId, routing table, iterative lookup)
- `transport/` - Pluggable transport layer (in-memory for testing, WebSocket for production)
- `identity/` - Peer identity, phone number attestation
- `protocol/` - Wire protocol (message types, serialization)
- `mesh/` - Mesh node orchestration, store-and-forward

## Usage

```dart
import 'package:signal_mesh/signal_mesh.dart';

// Create a mesh node
final transport = createInMemoryTransport((host: '127.0.0.1', port: 8000));
final nodeResult = await createMeshNode(
  localAddress: (host: '127.0.0.1', port: 8000),
  transport: transport,
  config: defaultConfig(phoneNumber: '+61412345678'),
);

// Listen for messages
switch (nodeResult) {
  case Success(:final value):
    value.onMessage((sender, plaintext) {
      print('From ${nodeIdShort(sender)}: ${String.fromCharCodes(plaintext)}');
    });
  case Error(:final error):
    print('Failed: $error');
}
```

## Dependencies

- `cryptography` - X25519, Ed25519, AES-GCM, HKDF, HMAC
- `nadz` - Result types (no exceptions)
- `dart_node_core` / `dart_node_ws` - Node.js WebSocket transport
