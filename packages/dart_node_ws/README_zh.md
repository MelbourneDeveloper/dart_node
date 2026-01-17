# dart_node_ws

类型安全的 Node.js WebSocket 绑定，为您的 Dart 应用程序提供实时双向通信能力。

## 安装

```yaml
dependencies:
  dart_node_ws: ^0.11.0-beta
```

通过 npm 安装 ws 包：

```bash
npm install ws
```

## 快速开始

### WebSocket 服务器

```dart
import 'package:dart_node_ws/dart_node_ws.dart';

void main() {
  final server = createWebSocketServer(port: 8080);

  server.onConnection((client, url) {
    print('Client connected from $url');

    client.onMessage((message) {
      print('Received: ${message.text}');
      // 回显消息
      client.send('You said: ${message.text}');
    });

    client.onClose((data) {
      print('Client disconnected: ${data.code} ${data.reason}');
    });

    // 发送欢迎消息
    client.send('Welcome to the WebSocket server!');
  });

  print('WebSocket server running on port 8080');
}
```

## WebSocket 服务器 API

### 创建服务器

```dart
// 在指定端口创建独立服务器
final server = createWebSocketServer(port: 8080);
```

### 服务器事件

```dart
server.onConnection((WebSocketClient client, String? url) {
  // 新客户端已连接
  // url 包含请求 URL（例如 '/ws?token=abc'）
  print('Connection from $url');
});
```

### 关闭服务器

```dart
server.close(() {
  print('Server closed');
});
```

## WebSocket 客户端 API

### 客户端事件

```dart
client.onMessage((WebSocketMessage message) {
  // message.text - 字符串内容
  // message.bytes - 二进制数据（如适用）
  print('Received: ${message.text}');
});

client.onClose((CloseEventData data) {
  // data.code - 关闭代码（1000 = 正常关闭）
  // data.reason - 关闭原因
  print('Closed with code ${data.code}: ${data.reason}');
});

client.onError((WebSocketError error) {
  print('Client error: ${error.message}');
});
```

### 发送消息

```dart
// 发送文本
client.send('Hello, client!');

// 发送 JSON（自动序列化）
client.sendJson({'type': 'update', 'data': someData});
```

### 客户端状态

```dart
// 检查连接是否打开
if (client.isOpen) {
  client.send('Connected!');
}

// 可以设置 userId 用于识别
client.userId = 'user123';
```

### 关闭连接

```dart
// 使用默认代码关闭（1000 = 正常关闭）
client.close();

// 使用自定义代码和原因关闭
client.close(1000, 'Normal closure');
```

## 关闭代码

标准 WebSocket 关闭代码：
- `1000`：正常关闭
- `1001`：离开（服务器关闭）
- `1002`：协议错误
- `1006`：异常关闭（无关闭帧）
- `1011`：内部错误
- `3000-3999`：库/框架代码
- `4000-4999`：私有使用代码

## 聊天服务器示例

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

## 实时仪表板示例

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dart_node_ws/dart_node_ws.dart';

void main() {
  final server = createWebSocketServer(port: 8080);
  final subscribers = <WebSocketClient>{};

  // 模拟实时数据更新
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

    // 发送初始状态
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

## 错误处理

```dart
server.onConnection((client, url) {
  client.onMessage((message) {
    try {
      final data = jsonDecode(message.text ?? '{}');
      // 处理消息...
    } catch (e) {
      client.sendJson({'error': 'Invalid message format'});
    }
  });

  client.onError((error) {
    print('Client error: ${error.message}');
    // 不要让服务器崩溃
  });
});
```

## 源代码

源代码可在 [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_ws) 上获取。
