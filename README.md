# dart_node

Write your entire stack in Dart: React web apps, React Native mobile apps with Expo, and Node.js Express backends.

📚 **[Documentation & Website](https://melbournedeveloper.github.io/dart_node/)**

![React and React Native](images/dart_node.gif)

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

## Packages

| Package | Description | 
|---------|-------------|
| [dart_node_core](packages/dart_node_core) | Core JS interop utilities 
| [dart_node_express](packages/dart_node_express) | Express.js bindings 
| [dart_node_ws](packages/dart_node_ws) | WebSocket bindings 
| [dart_node_react](packages/dart_node_react) | React bindings 
| [dart_node_react_native](packages/dart_node_react_native) | React Native bindings |

## Example Quick Start

**Web + Backend:**
```bash
./run_dev.sh
```
Open http://localhost:8080/web/

**Mobile:** Use VSCode launch config `Mobile: Build & Run (Expo)`

```mermaid
graph LR
    B[Backend<br/>Express/Node]
    F[Frontend<br/>React Web]
    M[Mobile<br/>React Native]

    F -->|HTTP| B
    M -->|HTTP| B
```

- **Backend**: Express server on port 3000 (Dart → Node.js)
- **Frontend**: React app on port 8080 (Dart → Browser JS)
- **Mobile**: Expo app (Dart → React Native)

## License

BSD 3-Clause License. Copyright (c) 2025, Christian Findlay.
