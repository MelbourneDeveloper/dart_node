# dart_node_react_native

React Native bindings for Dart. Build mobile apps with Expo entirely in Dart with full type safety and native performance.

Write your entire stack in Dart: React web apps, React Native mobile apps with Expo, and Node.js Express backends.

## Package Architecture

```mermaid
graph TD
    B[dart_node_express] --> A[dart_node_core]
    C[dart_node_ws] --> A
    D[dart_node_react] --> A
    E[dart_node_react_native] --> D
    B -.-> F[express npm]
    C -.-> G[ws npm]
    D -.-> H[react npm]
    E -.-> I[react-native npm]
```

Part of the [dart_node](https://github.com/MelbourneDeveloper/dart_node) package family.
