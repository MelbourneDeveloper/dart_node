/// Task priority
enum TaskPriority {
  low,
  medium,
  high;

  static TaskPriority fromString(String? s) => switch (s) {
    'low' => TaskPriority.low,
    'high' => TaskPriority.high,
    _ => TaskPriority.medium,
  };
}

/// Task entity - immutable record
typedef Task = ({
  String id,
  String userId,
  String title,
  String? description,
  bool completed,
  TaskPriority priority,
  DateTime createdAt,
  DateTime updatedAt,
});

extension TaskExtension on Task {
  Task copyWith({
    String? title,
    String? description,
    bool? completed,
    TaskPriority? priority,
    DateTime? updatedAt,
  }) => (
    id: id,
    userId: userId,
    title: title ?? this.title,
    description: description ?? this.description,
    completed: completed ?? this.completed,
    priority: priority ?? this.priority,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    ...description != null ? {'description': description} : <String, dynamic>{},
    'completed': completed,
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// Data for creating a task
typedef CreateTaskData = ({String title, String? description});

/// Data for updating a task
typedef UpdateTaskData = ({
  String? title,
  String? description,
  bool? completed,
});
