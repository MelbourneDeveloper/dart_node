/// Pomodoro session state enum
enum PomodoroState {
  idle,
  working,
  onBreak,
  paused;

  static PomodoroState fromString(String? s) => switch (s) {
    'working' => PomodoroState.working,
    'onBreak' => PomodoroState.onBreak,
    'paused' => PomodoroState.paused,
    _ => PomodoroState.idle,
  };
}

/// Pomodoro event type for WebSocket events
enum PomodoroEventType {
  started,
  paused,
  resumed,
  completed,
  tick;

  static PomodoroEventType fromString(String? s) => switch (s) {
    'started' => PomodoroEventType.started,
    'paused' => PomodoroEventType.paused,
    'resumed' => PomodoroEventType.resumed,
    'completed' => PomodoroEventType.completed,
    'tick' => PomodoroEventType.tick,
    _ => PomodoroEventType.tick,
  };
}

/// Pomodoro session - immutable record
typedef PomodoroSession = ({
  String id,
  String title,
  int duration,
  int breakDuration,
  DateTime? startedAt,
  DateTime? completedAt,
  String userId,
  String? linkedTaskId,
  DateTime createdAt,
  DateTime updatedAt,
});

extension PomodoroSessionExtension on PomodoroSession {
  PomodoroSession copyWith({
    String? title,
    int? duration,
    int? breakDuration,
    DateTime? startedAt,
    DateTime? completedAt,
    String? linkedTaskId,
    DateTime? updatedAt,
  }) => (
    id: id,
    title: title ?? this.title,
    duration: duration ?? this.duration,
    breakDuration: breakDuration ?? this.breakDuration,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    userId: userId,
    linkedTaskId: linkedTaskId ?? this.linkedTaskId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'duration': duration,
    'breakDuration': breakDuration,
    ...startedAt != null ? {'startedAt': startedAt!.toIso8601String()} : <String, dynamic>{},
    ...completedAt != null ? {'completedAt': completedAt!.toIso8601String()} : <String, dynamic>{},
    'userId': userId,
    ...linkedTaskId != null ? {'linkedTaskId': linkedTaskId} : <String, dynamic>{},
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// Pomodoro event for WebSocket events - immutable record
typedef PomodoroEvent = ({
  PomodoroEventType type,
  String sessionId,
  int remainingSeconds,
  PomodoroState state,
});

extension PomodoroEventExtension on PomodoroEvent {
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'sessionId': sessionId,
    'remainingSeconds': remainingSeconds,
    'state': state.name,
  };
}

/// Data for creating a pomodoro session
typedef CreatePomodoroSessionData = ({
  String title,
  int? duration,
  int? breakDuration,
  String? linkedTaskId,
});

/// Data for updating a pomodoro session
typedef UpdatePomodoroSessionData = ({
  String? title,
  int? duration,
  int? breakDuration,
  DateTime? startedAt,
  DateTime? completedAt,
  String? linkedTaskId,
});
