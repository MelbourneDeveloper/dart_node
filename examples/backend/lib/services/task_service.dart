import 'package:nadz/nadz.dart';
import 'package:shared/models/task.dart';

/// In-memory task storage and operations
class TaskService {
  final Map<String, Task> _tasks = {};
  int _nextId = 1;

  /// Create a new task
  Task create({
    required String userId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
  }) {
    final id = 'task_${_nextId++}';
    final now = DateTime.now();
    final task = (
      id: id,
      userId: userId,
      title: title,
      description: description,
      completed: false,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
    _tasks[id] = task;
    return task;
  }

  /// Find task by ID
  Task? findById(String id) => _tasks[id];

  /// Find all tasks for a user
  List<Task> findByUser(String userId) =>
      _tasks.values.where((t) => t.userId == userId).toList();

  /// Update a task - returns Error if task not found
  Result<Task, String> update(
    String id, {
    String? title,
    String? description,
    bool? completed,
    TaskPriority? priority,
  }) {
    final task = _tasks[id];
    if (task == null) {
      return const Error('Task not found');
    }

    final updated = task.copyWith(
      title: title,
      description: description,
      completed: completed,
      priority: priority,
      updatedAt: DateTime.now(),
    );
    _tasks[id] = updated;
    return Success(updated);
  }

  /// Delete a task - returns Error if task not found
  Result<void, String> delete(String id) {
    final removed = _tasks.remove(id);
    return (removed != null)
        ? const Success(null)
        : const Error('Task not found');
  }
}
