# dart_node_ws

WebSocket bindings for Dart on Node.js. Build real-time servers entirely in Dart.

## Getting Started

```dart
import 'package:dart_node_ws/dart_node_ws.dart';
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = express();
  final server = app.listen(3000);

  final wss = WebSocketServer(server: server);

  wss.on('connection', (ws) {
    ws.on('message', (data) {
      ws.send('Echo: $data');
    });
  });

  print('WebSocket server on ws://localhost:3000');
}
```

## Run

```bash
dart compile js -o server.js lib/main.dart
node server.js
```

## Part of dart_node

[GitHub](https://github.com/MelbourneDeveloper/dart_node)
