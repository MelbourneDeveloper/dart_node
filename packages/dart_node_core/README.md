# dart_node_core

Core JS interop utilities for Dart-to-JavaScript compilation. This package provides the foundation for building React, React Native, and Express.js applications entirely in Dart.

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

Part of the [dart_node](https://github.com/user/dart_node) package family.
