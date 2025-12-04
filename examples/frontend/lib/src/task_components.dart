import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:shared/js_types/js_types.dart';

/// Build stats display for task list
DivElement buildStats(List<JSTask> tasks) {
  final total = tasks.length;
  final completed = tasks.where((t) => t.completed).length;
  final pct = total > 0 ? (completed / total * 100).round() : 0;
  return div(
    className: 'stats',
    children: [
      span('$completed/$total completed', className: 'stat-text'),
      div(
        className: 'progress-bar',
        child: div(
          className: 'progress-fill',
          props: {
            'style': {'width': '$pct%'}.jsify(),
          },
        ),
      ),
    ],
  );
}

/// Build task list or empty state
List<ReactElement> buildTaskList(
  List<JSTask> tasks,
  void Function(String, bool) onToggle,
  void Function(String) onDelete,
) => tasks.isEmpty
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
  JSTask task,
  void Function(String, bool) onToggle,
  void Function(String) onDelete,
) {
  final checkClass = task.completed
      ? 'task-checkbox completed'
      : 'task-checkbox';
  final titleClass = task.completed ? 'task-title completed' : 'task-title';
  final itemClass = task.completed ? 'task-item completed' : 'task-item';
  final description = task.description;

  return div(
    className: itemClass,
    children: [
      div(
        className: checkClass,
        props: {
          'onClick': ((JSAny? _) => onToggle(task.id, task.completed)).toJS,
        },
        child: task.completed
            ? span('\u2713', className: 'check-icon')
            : span(''),
      ),
      div(
        className: 'task-content',
        children: [
          span(task.title, className: titleClass),
          if (description != null && description.isNotEmpty)
            span(description, className: 'task-desc')
          else
            span(''),
        ],
      ),
      button(
        text: '\u00D7',
        className: 'btn-delete',
        onClick: () => onDelete(task.id),
      ),
    ],
  );
}
