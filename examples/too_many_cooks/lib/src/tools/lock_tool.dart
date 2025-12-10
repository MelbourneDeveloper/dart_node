/// Lock tool - file lock management.
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/config.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/notifications.dart';
import 'package:too_many_cooks/src/types.dart';

/// Input schema for lock tool.
const lockInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'action': {
      'type': 'string',
      'enum': ['acquire', 'release', 'force_release', 'renew', 'query', 'list'],
      'description': 'Lock action to perform',
    },
    'agent_name': {
      'type': 'string',
      'description': 'Your agent name (required for acquire/release/renew)',
    },
    'agent_key': {
      'type': 'string',
      'description': 'Your secret key (required for acquire/release/renew)',
    },
    'file_path': {
      'type': 'string',
      'description': 'File path to lock (required except for list)',
    },
    'reason': {
      'type': 'string',
      'description': 'Why you need this lock (optional, for acquire)',
    },
  },
  'required': ['action'],
};

/// Tool config for lock.
const lockToolConfig = (
  title: 'File Lock',
  description:
      'Manage file locks: acquire, release, force_release, renew, '
      'query, list. REQUIRED: action. For acquire/release/renew: file_path, '
      'agent_name, agent_key. For query: file_path. '
      'Example acquire: {"action":"acquire","file_path":"/path/file.dart",'
      ' "agent_name":"me","agent_key":"xxx","reason":"editing"}',
  inputSchema: lockInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create lock tool handler.
ToolCallback createLockHandler(
  TooManyCooksDb db,
  TooManyCooksConfig config,
  NotificationEmitter emitter,
  Logger logger,
) => (args, meta) async {
  final actionArg = args['action'];
  if (actionArg == null || actionArg is! String) {
    return (
      content: <Object>[
        textContent('{"error":"missing_parameter: action is required"}'),
      ],
      isError: true,
    );
  }
  final action = actionArg;
  final agentName = args['agent_name'] as String?;
  final agentKey = args['agent_key'] as String?;
  final filePath = args['file_path'] as String?;
  final reason = args['reason'] as String?;
  final log = logger.child({
    'tool': 'lock',
    'action': action,
    'filePath': ?filePath,
  });

  return switch (action) {
    'acquire' => _acquire(
      db,
      emitter,
      log,
      filePath,
      agentName,
      agentKey,
      reason,
      config.lockTimeoutMs,
    ),
    'release' => _release(db, emitter, log, filePath, agentName, agentKey),
    'force_release' => _forceRelease(
      db,
      emitter,
      log,
      filePath,
      agentName,
      agentKey,
    ),
    'renew' => _renew(
      db,
      emitter,
      log,
      filePath,
      agentName,
      agentKey,
      config.lockTimeoutMs,
    ),
    'query' => _query(db, filePath),
    'list' => _list(db),
    _ => (
      content: <Object>[textContent('{"error":"Unknown action: $action"}')],
      isError: true,
    ),
  };
};

CallToolResult _acquire(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger log,
  String? filePath,
  String? agentName,
  String? agentKey,
  String? reason,
  int timeoutMs,
) {
  if (filePath == null || agentName == null || agentKey == null) {
    return (
      content: <Object>[
        textContent(
          '{"error":"acquire requires file_path, agent_name, agent_key"}',
        ),
      ],
      isError: true,
    );
  }
  final result = db.acquireLock(
    filePath,
    agentName,
    agentKey,
    reason,
    timeoutMs,
  );
  return switch (result) {
    Success(:final value) when value.acquired => () {
      emitter.emit(eventLockAcquired, {
        'file_path': filePath,
        'agent_name': agentName,
        'expires_at': value.lock!.expiresAt,
        'reason': reason,
      });
      log.info('Lock acquired on $filePath by $agentName');
      return (
        content: <Object>[textContent(_lockResultJson(value))],
        isError: false,
      );
    }(),
    Success(:final value) => (
      content: <Object>[textContent(_lockResultJson(value))],
      isError: true,
    ),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _release(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger log,
  String? filePath,
  String? agentName,
  String? agentKey,
) {
  if (filePath == null || agentName == null || agentKey == null) {
    return (
      content: <Object>[
        textContent(
          '{"error":"release requires file_path, agent_name, agent_key"}',
        ),
      ],
      isError: true,
    );
  }
  return switch (db.releaseLock(filePath, agentName, agentKey)) {
    Success() => () {
      emitter.emit(eventLockReleased, {
        'file_path': filePath,
        'agent_name': agentName,
      });
      log.info('Lock released on $filePath by $agentName');
      return (
        content: <Object>[textContent('{"released":true}')],
        isError: false,
      );
    }(),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _forceRelease(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger log,
  String? filePath,
  String? agentName,
  String? agentKey,
) {
  if (filePath == null || agentName == null || agentKey == null) {
    return (
      content: <Object>[
        textContent(
          '{"error":"force_release requires '
          'file_path, agent_name, agent_key"}',
        ),
      ],
      isError: true,
    );
  }
  return switch (db.forceReleaseLock(filePath, agentName, agentKey)) {
    Success() => () {
      emitter.emit(eventLockReleased, {
        'file_path': filePath,
        'agent_name': agentName,
        'force': true,
      });
      log.warn('Lock force-released on $filePath by $agentName');
      return (
        content: <Object>[textContent('{"released":true}')],
        isError: false,
      );
    }(),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _renew(
  TooManyCooksDb db,
  NotificationEmitter emitter,
  Logger log,
  String? filePath,
  String? agentName,
  String? agentKey,
  int timeoutMs,
) {
  if (filePath == null || agentName == null || agentKey == null) {
    return (
      content: <Object>[
        textContent(
          '{"error":"renew requires file_path, agent_name, agent_key"}',
        ),
      ],
      isError: true,
    );
  }
  return switch (db.renewLock(filePath, agentName, agentKey, timeoutMs)) {
    Success() => () {
      final newExpiresAt = DateTime.now().millisecondsSinceEpoch + timeoutMs;
      emitter.emit(eventLockRenewed, {
        'file_path': filePath,
        'agent_name': agentName,
        'expires_at': newExpiresAt,
      });
      log.debug('Lock renewed on $filePath by $agentName');
      return (
        content: <Object>[textContent('{"renewed":true}')],
        isError: false,
      );
    }(),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _query(TooManyCooksDb db, String? filePath) {
  if (filePath == null) {
    return (
      content: <Object>[textContent('{"error":"query requires file_path"}')],
      isError: true,
    );
  }
  return switch (db.queryLock(filePath)) {
    Success(:final value) when value == null => (
      content: <Object>[textContent('{"locked":false}')],
      isError: false,
    ),
    Success(:final value) => (
      content: <Object>[
        textContent('{"locked":true,"lock":${_lockJson(value!)}}'),
      ],
      isError: false,
    ),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _list(TooManyCooksDb db) => switch (db.listLocks()) {
  Success(:final value) => (
    content: <Object>[
      textContent('{"locks":[${value.map(_lockJson).join(',')}]}'),
    ],
    isError: false,
  ),
  Error(:final error) => _errorResult(error),
};

String _lockJson(FileLock l) =>
    '{"file_path":"${l.filePath}",'
    '"agent_name":"${l.agentName}",'
    '"expires_at":${l.expiresAt}'
    '${l.reason != null ? ',"reason":"${l.reason}"' : ''}}';

String _lockResultJson(LockResult r) => r.acquired
    ? '{"acquired":true,"lock":${_lockJson(r.lock!)}}'
    : '{"acquired":false,"error":"${r.error}"}';

CallToolResult _errorResult(DbError e) => (
  content: <Object>[textContent('{"error":"${e.code}: ${e.message}"}')],
  isError: true,
);
