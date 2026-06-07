import 'dart:async';
import 'dart:convert';

import 'package:backend/services/token_service.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_ws/dart_node_ws.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/models/task.dart';

/// Event types for task changes
enum TaskEventType {
  /// Task created
  created,

  /// Task updated
  updated,

  /// Task deleted
  deleted,
}

/// Event types for Pomodoro session changes
enum PomodoroEventType {
  /// Session started
  started,

  /// Session paused
  paused,

  /// Session resumed
  resumed,

  /// Timer tick (every second)
  tick,

  /// Session completed
  completed,
}

/// Pomodoro session state
enum PomodoroState {
  /// Working period
  working,

  /// Break period
  onBreak,
}

/// Pomodoro session data
typedef PomodoroSession = ({
  String sessionId,
  String roomId,
  int remainingSeconds,
  PomodoroState state,
  bool isPaused,
  DateTime startedAt,
});

/// WebSocket service for real-time task updates and Pomodoro sync
class WebSocketService {
  /// Creates a WebSocket service with the given token service
  WebSocketService(this._tokenService);

  final TokenService _tokenService;
  final Map<String, List<WebSocketClient>> _clientsByUser = {};
  final Map<String, List<WebSocketClient>> _clientsByRoom = {};
  final Map<String, PomodoroSession> _activeSessions = {};
  final Map<String, Timer> _sessionTimers = {};
  WebSocketServer? _server;

  /// Start the WebSocket server
  void start({required int port}) {
    _server = createWebSocketServer(port: port);
    _server?.onConnection(_handleConnection);
    consoleLog('WebSocket server running on ws://localhost:$port');
  }

  void _handleConnection(WebSocketClient client, String? url) {
    final token = _extractToken(url);
    if (token == null) {
      client.close(4001, 'Unauthorized');
      return;
    }

    switch (_tokenService.verify(token)) {
      case Error(:final error):
        client.close(4001, error.message);
      case Success(:final value):
        client.userId = value.userId;
        _addClient(value.userId, client);
        client.onClose((_) => _removeClient(value.userId, client));
        client.onError((_) => _removeClient(value.userId, client));
        consoleLog('WebSocket client connected: ${value.userId}');
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

  /// Join a Pomodoro room
  void joinRoom(String userId, String roomId) {
    final clients = _clientsByUser[userId];
    switch (clients) {
      case null:
        break;
      case final c:
        _clientsByRoom.putIfAbsent(roomId, () => []).addAll(c);
        consoleLog('User $userId joined Pomodoro room $roomId');
    }
  }

  /// Leave a Pomodoro room
  void leaveRoom(String userId, String roomId) {
    final clients = _clientsByUser[userId];
    switch (clients) {
      case null:
        break;
      case final c:
        final roomClients = _clientsByRoom[roomId];
        switch (roomClients) {
          case null:
            break;
          case final rc:
            c.forEach(rc.remove);
        }
        switch (_clientsByRoom[roomId]?.isEmpty ?? true) {
          case true:
            _clientsByRoom.remove(roomId);
          case false:
            break;
        }
        consoleLog('User $userId left Pomodoro room $roomId');
    }
  }

  /// Start a Pomodoro session in a room
  void startPomodoroSession({
    required String sessionId,
    required String roomId,
    required int durationSeconds,
    required PomodoroState state,
  }) {
    final session = (
      sessionId: sessionId,
      roomId: roomId,
      remainingSeconds: durationSeconds,
      state: state,
      isPaused: false,
      startedAt: DateTime.now(),
    );

    _activeSessions[sessionId] = session;
    _broadcastToRoom(roomId, PomodoroEventType.started, session);
    _startSessionTimer(sessionId);
    consoleLog('Pomodoro session $sessionId started in room $roomId');
  }

  /// Pause a Pomodoro session
  void pausePomodoroSession(String sessionId) {
    final session = _activeSessions[sessionId];
    switch (session) {
      case null:
        consoleLog('Session $sessionId not found');
        return;
      case final s when s.isPaused:
        return;
      case final s:
        final updatedSession = (
          sessionId: s.sessionId,
          roomId: s.roomId,
          remainingSeconds: s.remainingSeconds,
          state: s.state,
          isPaused: true,
          startedAt: s.startedAt,
        );
        _activeSessions[sessionId] = updatedSession;
        _stopSessionTimer(sessionId);
        _broadcastToRoom(s.roomId, PomodoroEventType.paused, updatedSession);
        consoleLog('Pomodoro session $sessionId paused');
    }
  }

  /// Resume a Pomodoro session
  void resumePomodoroSession(String sessionId) {
    final session = _activeSessions[sessionId];
    switch (session) {
      case null:
        consoleLog('Session $sessionId not found');
        return;
      case final s when !s.isPaused:
        return;
      case final s:
        final updatedSession = (
          sessionId: s.sessionId,
          roomId: s.roomId,
          remainingSeconds: s.remainingSeconds,
          state: s.state,
          isPaused: false,
          startedAt: s.startedAt,
        );
        _activeSessions[sessionId] = updatedSession;
        _startSessionTimer(sessionId);
        _broadcastToRoom(s.roomId, PomodoroEventType.resumed, updatedSession);
        consoleLog('Pomodoro session $sessionId resumed');
    }
  }

  void _startSessionTimer(String sessionId) {
    _sessionTimers[sessionId] = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickSession(sessionId),
    );
  }

  void _stopSessionTimer(String sessionId) {
    _sessionTimers[sessionId]?.cancel();
    _sessionTimers.remove(sessionId);
  }

  void _tickSession(String sessionId) {
    final session = _activeSessions[sessionId];
    switch (session) {
      case null:
        _stopSessionTimer(sessionId);
        return;
      case final s when s.isPaused:
        return;
      case final s when s.remainingSeconds <= 0:
        _completeSession(sessionId);
        return;
      case final s:
        final updatedSession = (
          sessionId: s.sessionId,
          roomId: s.roomId,
          remainingSeconds: s.remainingSeconds - 1,
          state: s.state,
          isPaused: s.isPaused,
          startedAt: s.startedAt,
        );
        _activeSessions[sessionId] = updatedSession;
        _broadcastToRoom(s.roomId, PomodoroEventType.tick, updatedSession);
    }
  }

  void _completeSession(String sessionId) {
    final session = _activeSessions[sessionId];
    switch (session) {
      case null:
        return;
      case final s:
        _stopSessionTimer(sessionId);
        _broadcastToRoom(s.roomId, PomodoroEventType.completed, s);
        _activeSessions.remove(sessionId);
        consoleLog('Pomodoro session $sessionId completed');
    }
  }

  void _broadcastToRoom(
    String roomId,
    PomodoroEventType type,
    PomodoroSession session,
  ) {
    final clients = _clientsByRoom[roomId];
    switch (clients) {
      case null:
        break;
      case final c:
        final message = jsonEncode({
          'type': 'pomodoro_${type.name}',
          'data': {
            'sessionId': session.sessionId,
            'roomId': session.roomId,
            'remainingSeconds': session.remainingSeconds,
            'state': session.state.name,
            'isPaused': session.isPaused,
            'startedAt': session.startedAt.toIso8601String(),
          },
        });
        for (final client in c) {
          switch (client.isOpen) {
            case true:
              client.send(message);
            case false:
              break;
          }
        }
    }
  }

  /// Stop the WebSocket server
  void stop() {
    for (final timer in _sessionTimers.values) {
      timer.cancel();
    }
    _sessionTimers.clear();
    _activeSessions.clear();
    _clientsByRoom.clear();
    _server?.close();
  }
}
