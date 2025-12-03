import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';

/// Build stats display for task list
DivElement buildStats(List<JSObject> tasks) {
  final total = tasks.length;
  final completed = tasks
      .where((t) => (t['completed'] as JSBoolean?)?.toDart ?? false)
      .length;
  final pct = total > 0 ? (completed / total * 100).round() : 0;
  return div(
    className: 'stats',
    children: [
      span('$completed/$total completed', className: 'stat-text'),
      div(
        className: 'progress-bar',
        child: div(
          className: 'progress-fill',
          props: {'style': {'width': '$pct%'}.jsify()},
        ),
      ),
    ],
  );
}

/// Build task list or empty state
List<ReactElement> buildTaskList(
  List<JSObject> tasks,
  void Function(String, bool) onToggle,
  void Function(String) onDelete,
) =>
    tasks.isEmpty
        ? [
            div(
              className: 'empty-state',
              children: [
                pEl('No tasks yet. Add one above!', className: 'empty-text'),
              ],
            ),
          ]
        : tasks.map((task) => buildTaskItem(task, onToggle, onDelete)).toList();

/// Build a single task item
DivElement buildTaskItem(
  JSObject task,
  void Function(String, bool) onToggle,
  void Function(String) onDelete,
) {
  final id = (task['id'] as JSString?)?.toDart ?? '';
  final title = (task['title'] as JSString?)?.toDart ?? '';
  final description = (task['description'] as JSString?)?.toDart;
  final completed = (task['completed'] as JSBoolean?)?.toDart ?? false;
  final checkClass = completed ? 'task-checkbox completed' : 'task-checkbox';
  final titleClass = completed ? 'task-title completed' : 'task-title';
  final itemClass = completed ? 'task-item completed' : 'task-item';

  return div(
    className: itemClass,
    children: [
      div(
        className: checkClass,
        props: {'onClick': ((JSAny? _) => onToggle(id, completed)).toJS},
        child: completed ? span('\u2713', className: 'check-icon') : span(''),
      ),
      div(
        className: 'task-content',
        children: [
          span(title, className: titleClass),
          if (description != null && description.isNotEmpty)
            span(description, className: 'task-desc')
          else
            span(''),
        ],
      ),
      button(
        text: '\u00D7',
        className: 'btn-delete',
        onClick: () => onDelete(id),
      ),
    ],
  );
}

/// Handle incoming WebSocket task events using functional updater
void handleTaskEvent(
  String? type,
  JSObject task,
  StateHookJSArray<JSObject> tasksState,
) {
  final taskId = (task['id'] as JSString?)?.toDart;

  tasksState.setWithUpdater(
    (current) => switch (type) {
      'task_created' => [...current, task],
      'task_updated' => current.map((t) {
          final id = (t['id'] as JSString?)?.toDart;
          return (id == taskId) ? task : t;
        }).toList(),
      'task_deleted' => current.where((t) {
          final id = (t['id'] as JSString?)?.toDart;
          return id != taskId;
        }).toList(),
      _ => current,
    },
  );
}
