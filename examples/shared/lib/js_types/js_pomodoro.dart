import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Type-safe wrapper for JS pomodoro session objects
extension type JSPomodoroSession._(JSObject _) implements JSObject {
  /// Wrap a JSObject as a JSPomodoroSession
  factory JSPomodoroSession.fromJS(JSObject js) = JSPomodoroSession._;

  /// Get the session ID safely
  String get id => switch (_['id']) {
    final JSString s => s.toDart,
    _ => '',
  };

  /// Get the session title safely
  String get title => switch (_['title']) {
    final JSString s => s.toDart,
    _ => '',
  };

  /// Get the duration in minutes safely
  int get duration => switch (_['duration']) {
    final JSNumber n => n.toDartInt,
    _ => 25,
  };

  /// Get the break duration in minutes safely
  int get breakDuration => switch (_['breakDuration']) {
    final JSNumber n => n.toDartInt,
    _ => 5,
  };

  /// Get the user ID safely
  String get userId => switch (_['userId']) {
    final JSString s => s.toDart,
    _ => '',
  };

  /// Get the linked task ID safely
  String? get linkedTaskId => switch (_['linkedTaskId']) {
    final JSString s => s.toDart,
    _ => null,
  };

  /// Get the startedAt timestamp safely
  String? get startedAt => switch (_['startedAt']) {
    final JSString s => s.toDart,
    _ => null,
  };

  /// Get the completedAt timestamp safely
  String? get completedAt => switch (_['completedAt']) {
    final JSString s => s.toDart,
    _ => null,
  };

  /// Create a copy with updated fields
  JSPomodoroSession copyWith({
    String? title,
    int? duration,
    int? breakDuration,
    String? startedAt,
    String? completedAt,
    String? linkedTaskId,
  }) {
    final newSession = JSObject();
    for (final key in _getObjectKeys(_)) {
      newSession.setProperty(key.toJS, _[key]);
    }

    if (title != null) newSession.setProperty('title'.toJS, title.toJS);
    if (duration != null) newSession.setProperty('duration'.toJS, duration.toJS);
    if (breakDuration != null) newSession.setProperty('breakDuration'.toJS, breakDuration.toJS);
    if (startedAt != null) newSession.setProperty('startedAt'.toJS, startedAt.toJS);
    if (completedAt != null) newSession.setProperty('completedAt'.toJS, completedAt.toJS);
    if (linkedTaskId != null) newSession.setProperty('linkedTaskId'.toJS, linkedTaskId.toJS);

    return JSPomodoroSession._(newSession);
  }
}

/// Type-safe wrapper for JS pomodoro event objects
extension type JSPomodoroEvent._(JSObject _) implements JSObject {
  /// Wrap a JSObject as a JSPomodoroEvent
  factory JSPomodoroEvent.fromJS(JSObject js) = JSPomodoroEvent._;

  /// Get the event type safely
  String get type => switch (_['type']) {
    final JSString s => s.toDart,
    _ => 'tick',
  };

  /// Get the session ID safely
  String get sessionId => switch (_['sessionId']) {
    final JSString s => s.toDart,
    _ => '',
  };

  /// Get remaining seconds safely
  int get remainingSeconds => switch (_['remainingSeconds']) {
    final JSNumber n => n.toDartInt,
    _ => 0,
  };

  /// Get the state safely
  String get state => switch (_['state']) {
    final JSString s => s.toDart,
    _ => 'idle',
  };
}

/// Get object keys for iteration
List<String> _getObjectKeys(JSObject obj) {
  final keys = _objectKeys(obj);
  final result = <String>[];
  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    if (key case final JSString s) {
      result.add(s.toDart);
    }
  }
  return result;
}

@JS('Object.keys')
external JSArray _objectKeys(JSObject obj);

/// Add session only if it doesn't already exist (by ID)
/// Prevents duplicates when both HTTP and WebSocket add the same session
List<JSPomodoroSession> addSessionIfNotExists(
  List<JSPomodoroSession> sessions,
  JSPomodoroSession newSession,
) {
  final exists = sessions.any((s) => s.id == newSession.id);
  return exists ? sessions : [...sessions, newSession];
}

/// Check if a session with the given ID exists in the list
bool sessionExists(List<JSPomodoroSession> sessions, String? id) {
  if (id == null) return false;
  return sessions.any((s) => s.id == id);
}

/// Update a session in the list by ID
List<JSPomodoroSession> updateSessionById(
  List<JSPomodoroSession> sessions,
  JSPomodoroSession updated,
) => sessions.map((s) => s.id == updated.id ? updated : s).toList();

/// Remove a session from the list by ID
List<JSPomodoroSession> removeSessionById(
  List<JSPomodoroSession> sessions,
  String id,
) => sessions.where((s) => s.id != id).toList();

/// Handle incoming WebSocket session events
List<JSPomodoroSession> handleSessionEvent(
  String? type,
  JSPomodoroSession session,
  List<JSPomodoroSession> current,
) => switch (type) {
  'session_created' => addSessionIfNotExists(current, session),
  'session_updated' => updateSessionById(current, session),
  'session_deleted' => removeSessionById(current, session.id),
  _ => current,
};

/// Format seconds as MM:SS for display
String formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

/// Get display text for pomodoro state
String stateDisplayText(String state) => switch (state) {
  'working' => 'Working',
  'onBreak' => 'Break Time',
  'paused' => 'Paused',
  _ => 'Ready',
};

/// Get color for pomodoro state
String stateColor(String state) => switch (state) {
  'working' => '#22c55e',
  'onBreak' => '#3b82f6',
  'paused' => '#f59e0b',
  _ => '#6b7280',
};
