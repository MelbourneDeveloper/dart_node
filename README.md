# dart_node

Write your entire stack in Dart: React web apps, React Native mobile apps with Expo, and Node.js Express backends.

## Package Architecture

```mermaid
graph TD
    A[dart_node_core] --> B[dart_node_express]
    A --> C[dart_node_node]
    A --> D[dart_node_react]
    D --> E[dart_node_react_native]
    B -.-> F[express npm]
    D -.-> G[react npm]
    E -.-> H[react-native npm]
```

## Packages

| Package | Description | Version |
|---------|-------------|---------|
| [dart_node_core](packages/dart_node_core) | Core JS interop utilities | 0.1.0-beta |
| [dart_node_express](packages/dart_node_express) | Express.js bindings | 0.1.0-beta |
| [dart_node_node](packages/dart_node_node) | Node.js API bindings | 0.1.0-beta |
| [dart_node_react](packages/dart_node_react) | React bindings | 0.1.0-beta |
| [dart_node_react_native](packages/dart_node_react_native) | React Native bindings | 0.1.0-beta |

## Quick Start

```bash
./run_dev.sh
```

Then open http://localhost:8080/web/

## What's Running

- **Backend**: Express server on port 3000 (Dart compiled to Node.js)
- **Frontend**: React app on port 8080 (Dart compiled to browser JS)

## License

BSD 3-Clause License. Copyright (c) 2025, Christian Findlay.
