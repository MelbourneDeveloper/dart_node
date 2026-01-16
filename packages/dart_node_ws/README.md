
`dart_node_ws` provides type-safe WebSocket bindings for Node.js, enabling real-time bidirectional communication in your Dart applications.

## Installation

```yaml
dependencies:
  dart_node_ws: ^0.11.0-beta
```

Also install the ws package via npm:

```bash
npm install ws
```

## Quick Start

### WebSocket Server

```dart
import 'package:dart_node_ws/dart_node_ws.dart';

void main() {
  final server = createWebSocketServer(port: 8080);

  server.on('connection', (WebSocketClient client) {
    print('Client connected');

    client.on('message', (data) {
      print('Received: $data');

      // Echo back
      client.send('You said: $data');
    });

    client.on('close', () {
      print('Client disconnected');
    });

    // Send welcome message
    client.send('Welcome to the WebSocket server!');
  });

  print('WebSocket server running on port 8080');
}
```

### Integrating with Express

```dart
import 'package:dart_node_express/dart_node_express.dart';
import 'package:dart_node_ws/dart_node_ws.dart';

void main() {
  final app = express();

  // HTTP routes still work
  app.get('/', handler((req, res) {
    res.send('HTTP server with WebSocket support');
  }));

  final httpServer = app.listen(3000);

  // Attach WebSocket server to the HTTP server
  final wss = createWebSocketServer(server: httpServer);

  wss.onConnection((WebSocketClient client) {
    // Handle WebSocket connections
  });
}
```

## WebSocket Server API

### Creating a Server

```dart
// Standalone server on a port
final server = createWebSocketServer(port: 8080);

// Attached to an existing HTTP server
final server = createWebSocketServer(server: httpServer);

// With path filtering
final server = createWebSocketServer(
  server: httpServer,
  path: '/ws',  // Only accept connections to /ws
);
```

### Server Events

```dart
server.on('connection', (WebSocketClient client, Request req) {
  // New client connected
  // req contains the HTTP upgrade request
  print('Connection from ${req.headers['origin']}');
});

server.on('error', (error) {
  print('Server error: $error');
});

server.on('close', () {
  print('Server closed');
});
```

### Broadcasting to All Clients

```dart
void broadcast(String message) {
  for (final client in server.clients) {
    if (client.readyState == WebSocket.OPEN) {
      client.send(message);
    }
  }
}
```

## WebSocket Client API

### Client Events

```dart
client.on('message', (data) {
  // Handle incoming message
  // data can be String or Buffer
});

client.on('close', (code, reason) {
  print('Closed with code $code: $reason');
});

client.on('error', (error) {
  print('Client error: $error');
});

client.on('ping', (data) {
  // Ping received (pong sent automatically)
});

client.on('pong', (data) {
  // Pong received (response to our ping)
});
```

### Sending Messages

```dart
// Send text
client.send('Hello, client!');

// Send JSON
client.send(jsonEncode({'type': 'update', 'data': someData}));

// Send binary data
client.send(Uint8List.fromList([0x01, 0x02, 0x03]));
```

### Client State

```dart
// Check connection state
if (client.readyState == WebSocket.OPEN) {
  client.send('Connected!');
}

// States: CONNECTING, OPEN, CLOSING, CLOSED
```

### Closing Connection

```dart
// Close gracefully
client.close();

// Close with code and reason
client.close(1000, 'Normal closure');
```

## Chat Server Example

```dart
import 'package:dart_node_ws/dart_node_ws.dart';
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = express();

  final httpServer = app.listen(3000, () {
    print('Server running on http://localhost:3000');
  });

  // WebSocket server
  final wss = createWebSocketServer(server: httpServer);
  final clients = <String, WebSocketClient>{};

  wss.on('connection', (WebSocketClient client) {
    String? username;

    client.on('message', (data) {
      final message = jsonDecode(data);

      switch (message['type']) {
        case 'join':
          username = message['username'];
          clients[username!] = client;
          broadcast({
            'type': 'system',
            'text': '$username joined the chat',
          });
          break;

        case 'message':
          if (username != null) {
            broadcast({
              'type': 'message',
              'username': username,
              'text': message['text'],
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
          break;
      }
    });

    client.on('close', () {
      if (username != null) {
        clients.remove(username);
        broadcast({
          'type': 'system',
          'text': '$username left the chat',
        });
      }
    });
  });

  void broadcast(Map<String, dynamic> message) {
    final json = jsonEncode(message);
    for (final client in clients.values) {
      if (client.readyState == WebSocket.OPEN) {
        client.send(json);
      }
    }
  }
}
```

## Real-time Dashboard Example

```dart
import 'dart:async';
import 'package:dart_node_ws/dart_node_ws.dart';

void main() {
  final server = createWebSocketServer(port: 8080);
  final subscribers = <WebSocketClient>{};

  // Simulate real-time data updates
  Timer.periodic(Duration(seconds: 1), (_) {
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'cpu': Random().nextDouble() * 100,
      'memory': Random().nextDouble() * 100,
      'requests': Random().nextInt(1000),
    };

    final json = jsonEncode(data);
    for (final client in subscribers) {
      if (client.readyState == WebSocket.OPEN) {
        client.send(json);
      }
    }
  });

  server.on('connection', (WebSocketClient client) {
    print('Dashboard client connected');
    subscribers.add(client);

    // Send initial state
    client.send(jsonEncode({
      'type': 'init',
      'serverTime': DateTime.now().toIso8601String(),
    }));

    client.on('close', () {
      subscribers.remove(client);
      print('Dashboard client disconnected');
    });
  });

  print('Dashboard WebSocket server on port 8080');
}
```

## Error Handling

```dart
server.on('connection', (WebSocketClient client) {
  client.on('message', (data) {
    try {
      final message = jsonDecode(data);
      // Process message...
    } catch (e) {
      client.send(jsonEncode({
        'error': 'Invalid message format',
      }));
    }
  });

  client.on('error', (error) {
    print('Client error: $error');
    // Don't crash the server
  });
});

server.on('error', (error) {
  print('Server error: $error');
  // Handle server-level errors
});
```

## API Reference

See the [full API documentation](/api/dart_node_ws/) for all available functions and types.
