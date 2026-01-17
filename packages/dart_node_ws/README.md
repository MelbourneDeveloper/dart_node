# dart_node_ws

Type-safe WebSocket bindings for Node.js, enabling real-time bidirectional communication in your Dart applications.

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

  server.onConnection((client, url) {
    print('Client connected from $url');

    client.onMessage((message) {
      print('Received: ${message.text}');
      // Echo back
      client.send('You said: ${message.text}');
    });

    client.onClose((data) {
      print('Client disconnected: ${data.code} ${data.reason}');
    });

    // Send welcome message
    client.send('Welcome to the WebSocket server!');
  });

  print('WebSocket server running on port 8080');
}
```

## WebSocket Server API

### Creating a Server

```dart
// Standalone server on a port
final server = createWebSocketServer(port: 8080);
```

### Server Events

```dart
server.onConnection((WebSocketClient client, String? url) {
  // New client connected
  // url contains the request URL (e.g., '/ws?token=abc')
  print('Connection from $url');
});
```

### Closing the Server

```dart
server.close(() {
  print('Server closed');
});
```

## WebSocket Client API

### Client Events

```dart
client.onMessage((WebSocketMessage message) {
  // message.text - string content
  // message.bytes - binary data (if applicable)
  print('Received: ${message.text}');
});

client.onClose((CloseEventData data) {
  // data.code - close code (1000 = normal)
  // data.reason - close reason
  print('Closed with code ${data.code}: ${data.reason}');
});

client.onError((WebSocketError error) {
  print('Client error: ${error.message}');
});
```

### Sending Messages

```dart
// Send text
client.send('Hello, client!');

// Send JSON (automatically serialized)
client.sendJson({'type': 'update', 'data': someData});
```

### Client State

```dart
// Check if connection is open
if (client.isOpen) {
  client.send('Connected!');
}

// userId can be set for identification
client.userId = 'user123';
```

### Closing Connection

```dart
// Close with default code (1000 = normal)
client.close();

// Close with custom code and reason
client.close(1000, 'Normal closure');
```

## Close Codes

Standard WebSocket close codes:
- `1000`: Normal closure
- `1001`: Going away (server shutdown)
- `1002`: Protocol error
- `1006`: Abnormal closure (no close frame)
- `1011`: Internal error
- `3000-3999`: Library/framework codes
- `4000-4999`: Private use codes

## Chat Server Example

```dart
import 'dart:convert';
import 'package:dart_node_ws/dart_node_ws.dart';

void main() {
  final server = createWebSocketServer(port: 8080);
  final clients = <String, WebSocketClient>{};

  server.onConnection((client, url) {
    String? username;

    client.onMessage((message) {
      final data = jsonDecode(message.text ?? '{}');

      switch (data['type']) {
        case 'join':
          username = data['username'];
          client.userId = username;
          clients[username!] = client;
          broadcast(clients, {
            'type': 'system',
            'text': '$username joined the chat',
          });

        case 'message':
          if (username != null) {
            broadcast(clients, {
              'type': 'message',
              'username': username,
              'text': data['text'],
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
      }
    });

    client.onClose((data) {
      if (username != null) {
        clients.remove(username);
        broadcast(clients, {
          'type': 'system',
          'text': '$username left the chat',
        });
      }
    });
  });

  print('Chat server running on port 8080');
}

void broadcast(Map<String, WebSocketClient> clients, Map<String, dynamic> message) {
  final json = jsonEncode(message);
  for (final client in clients.values) {
    if (client.isOpen) {
      client.send(json);
    }
  }
}
```

## Real-time Dashboard Example

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
      if (client.isOpen) {
        client.send(json);
      }
    }
  });

  server.onConnection((client, url) {
    print('Dashboard client connected');
    subscribers.add(client);

    // Send initial state
    client.sendJson({
      'type': 'init',
      'serverTime': DateTime.now().toIso8601String(),
    });

    client.onClose((data) {
      subscribers.remove(client);
      print('Dashboard client disconnected');
    });
  });

  print('Dashboard WebSocket server on port 8080');
}
```

## Error Handling

```dart
server.onConnection((client, url) {
  client.onMessage((message) {
    try {
      final data = jsonDecode(message.text ?? '{}');
      // Process message...
    } catch (e) {
      client.sendJson({'error': 'Invalid message format'});
    }
  });

  client.onError((error) {
    print('Client error: ${error.message}');
    // Don't crash the server
  });
});
```

## Source Code

The source code is available on [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_ws).
