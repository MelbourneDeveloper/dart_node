import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Type-safe wrapper for JS task objects
extension type JSTask._(JSObject _) implements JSObject {
  /// Wrap a JSObject as a JSTask
  factory JSTask.fromJS(JSObject js) = JSTask._;

  /// Get the task ID safely
  String get id => switch (_['id']) {
    final JSString s => s.toDart,
    _ => '',
  };

  /// Get the task title safely
  String get title => switch (_['title']) {
    final JSString s => s.toDart,
    _ => '',
  };

  /// Get the task description safely
  String? get description => switch (_['description']) {
    final JSString s => s.toDart,
    _ => null,
  };

  /// Get the completed status safely
  bool get completed => switch (_['completed']) {
    final JSBoolean b => b.toDart,
    _ => false,
  };

  /// Create a copy with updated completed status
  JSTask withCompleted(bool value) {
    final newTask = JSObject();
    for (final key in _getObjectKeys(_)) {
      newTask.setProperty(key.toJS, _[key]);
    }
    newTask.setProperty('completed'.toJS, value.toJS);
    return JSTask._(newTask);
  }
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

/// Add task only if it doesn't already exist (by ID)
/// Prevents duplicates when both HTTP and WebSocket add the same task
List<JSTask> addTaskIfNotExists(List<JSTask> tasks, JSTask newTask) {
  final exists = tasks.any((t) => t.id == newTask.id);
  return exists ? tasks : [...tasks, newTask];
}

/// Check if a task with the given ID exists in the list
bool taskExists(List<JSTask> tasks, String? id) {
  if (id == null) return false;
  return tasks.any((t) => t.id == id);
}

/// Update a task in the list by ID
List<JSTask> updateTaskById(List<JSTask> tasks, JSTask updated) =>
    tasks.map((t) => t.id == updated.id ? updated : t).toList();

/// Remove a task from the list by ID
List<JSTask> removeTaskById(List<JSTask> tasks, String id) =>
    tasks.where((t) => t.id != id).toList();

/// Handle incoming WebSocket task events
List<JSTask> handleTaskEvent(String? type, JSTask task, List<JSTask> current) =>
    switch (type) {
      'task_created' => addTaskIfNotExists(current, task),
      'task_updated' => updateTaskById(current, task),
      'task_deleted' => removeTaskById(current, task.id),
      _ => current,
    };
