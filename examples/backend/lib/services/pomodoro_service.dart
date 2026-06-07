import 'package:shared/models/pomodoro.dart';

/// In-memory pomodoro session storage and operations
class PomodoroService {
  final Map<String, PomodoroSession> _sessions = {};
  int _nextId = 1;

  /// Create a new pomodoro session (not started)
  PomodoroSession create({
    required String userId,
    required String title,
    int duration = 25,
    int breakDuration = 5,
    String? linkedTaskId,
  }) {
    final id = 'pomodoro_${_nextId++}';
    final now = DateTime.now();
    final session = (
      id: id,
      userId: userId,
      title: title,
      duration: duration,
      breakDuration: breakDuration,
      startedAt: null,
      completedAt: null,
      linkedTaskId: linkedTaskId,
      createdAt: now,
      updatedAt: now,
    );
    _sessions[id] = session;
    return session;
  }

  /// Start a session
  PomodoroSession? start(String id) {
    final session = _sessions[id];
    if (session == null) return null;
    final now = DateTime.now();
    return _updateSession(session, startedAt: now, updatedAt: now);
  }

  /// Find session by ID
  PomodoroSession? findById(String id) => _sessions[id];

  /// Get active session for a user
  PomodoroSession? getActiveSession(String userId) => _sessions.values
      .where((s) => s.userId == userId && s.completedAt == null)
      .firstOrNull;

  /// Find all sessions for a user
  List<PomodoroSession> findByUser(String userId) =>
      _sessions.values.where((s) => s.userId == userId).toList();

  /// Delete a session
  bool delete(String id) => _sessions.remove(id) != null;

  /// Pause a session
  PomodoroSession? pauseSession(String id) {
    final session = _sessions[id];
    return session == null
        ? null
        : _updateSession(session, updatedAt: DateTime.now());
  }

  /// Resume a session
  PomodoroSession? resumeSession(String id) {
    final session = _sessions[id];
    return session == null
        ? null
        : _updateSession(session, updatedAt: DateTime.now());
  }

  /// Complete a session
  PomodoroSession? completeSession(String id) {
    final session = _sessions[id];
    if (session == null) return null;
    final now = DateTime.now();
    return _updateSession(session, completedAt: now, updatedAt: now);
  }

  PomodoroSession _updateSession(
    PomodoroSession session, {
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    final updated = session.copyWith(
      startedAt: startedAt,
      completedAt: completedAt,
      updatedAt: updatedAt,
    );
    _sessions[session.id] = updated;
    return updated;
  }
}
