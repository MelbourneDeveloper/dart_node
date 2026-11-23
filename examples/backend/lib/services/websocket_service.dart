import 'dart:convert';

import 'package:backend/services/token_service.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_ws/dart_node_ws.dart';
import 'package:shared/models/task.dart';

/// Event types for task changes
enum TaskEventType { created, updated, deleted }

/// WebSocket service for real-time task updates
class WebSocketService {
  WebSocketService(this._tokenService);

  final TokenService _tokenService;
  final Map<String, List<WebSocketClient>> _clientsByUser = {};
  WebSocketServer? _server;

  /// Start the WebSocket server
  void start({required int port}) {
    _server = createWebSocketServer(port: port);
    _server?.onConnection(_handleConnection);
    consoleLog('WebSocket server running on ws://localhost:$port');
  }

  void _handleConnection(WebSocketClient client, String? url) {
    final token = _extractToken(url);
    final payload = (token != null) ? _tokenService.verify(token) : null;

    switch (payload) {
      case null:
        client.close(4001, 'Unauthorized');
        return;
      case final p:
        client.userId = p.userId;
        _addClient(p.userId, client);
        client.onClose((_) => _removeClient(p.userId, client));
        client.onError((_) => _removeClient(p.userId, client));
        consoleLog('WebSocket client connected: ${p.userId}');
    }
  }

  String? _extractToken(String? url) {
    final uri = (url != null) ? Uri.tryParse('http://localhost$url') : null;
    return uri?.queryParameters['token'];
  }

  void _addClient(String userId, WebSocketClient client) {
    _clientsByUser.putIfAbsent(userId, () => []).add(client);
  }

  void _removeClient(String userId, WebSocketClient client) {
    _clientsByUser[userId]?.remove(client);
    switch (_clientsByUser[userId]?.isEmpty ?? true) {
      case true:
        _clientsByUser.remove(userId);
      case false:
        break;
    }
  }

  /// Notify a user about a task change
  void notifyTaskChange(String userId, TaskEventType type, Task task) {
    final clients = _clientsByUser[userId];
    switch (clients) {
      case null:
        break;
      case final c:
        _broadcastToClients(c, type, task);
    }
  }

  void _broadcastToClients(
    List<WebSocketClient> clients,
    TaskEventType type,
    Task task,
  ) {
    final message = jsonEncode({
      'type': 'task_${type.name}',
      'data': task.toJson(),
    });
    for (final client in clients) {
      switch (client.isOpen) {
        case true:
          client.send(message);
        case false:
          break;
      }
    }
  }

  /// Stop the WebSocket server
  void stop() => _server?.close();
}
