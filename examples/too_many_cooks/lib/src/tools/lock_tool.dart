/// Lock tool - file lock management.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';

import '../config.dart';
import '../db/db.dart';
import '../types.dart';

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
  description: 'Manage file locks: acquire, release, force_release, '
      'renew, query, list',
  inputSchema: lockInputSchema,
  outputSchema: null,
  annotations: null,
);

/// Create lock tool handler.
ToolCallback createLockHandler(TooManyCooksDb db, TooManyCooksConfig config) =>
    (args, meta) async {
      final action = args['action']! as String;
      final agentName = args['agent_name'] as String?;
      final agentKey = args['agent_key'] as String?;
      final filePath = args['file_path'] as String?;
      final reason = args['reason'] as String?;

      return switch (action) {
        'acquire' => _acquire(
            db,
            filePath,
            agentName,
            agentKey,
            reason,
            config.lockTimeoutMs,
          ),
        'release' => _release(db, filePath, agentName, agentKey),
        'force_release' => _forceRelease(db, filePath, agentName, agentKey),
        'renew' => _renew(db, filePath, agentName, agentKey, config.lockTimeoutMs),
        'query' => _query(db, filePath),
        'list' => _list(db),
        _ => (
            content: <Object>[
              (type: 'text', text: '{"error":"Unknown action: $action"}'),
            ],
            isError: true,
          ),
      };
    };

CallToolResult _acquire(
  TooManyCooksDb db,
  String? filePath,
  String? agentName,
  String? agentKey,
  String? reason,
  int timeoutMs,
) {
  if (filePath == null || agentName == null || agentKey == null) {
    return (
      content: <Object>[
        (
          type: 'text',
          text: '{"error":"acquire requires file_path, agent_name, agent_key"}',
        ),
      ],
      isError: true,
    );
  }
  return switch (db.acquireLock(filePath, agentName, agentKey, reason, timeoutMs)) {
    Success(:final value) => (
        content: <Object>[
          (type: 'text', text: _lockResultJson(value)),
        ],
        isError: !value.acquired,
      ),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _release(
  TooManyCooksDb db,
  String? filePath,
  String? agentName,
  String? agentKey,
) {
  if (filePath == null || agentName == null || agentKey == null) {
    return (
      content: <Object>[
        (
          type: 'text',
          text: '{"error":"release requires file_path, agent_name, agent_key"}',
        ),
      ],
      isError: true,
    );
  }
  return switch (db.releaseLock(filePath, agentName, agentKey)) {
    Success(_) => (
        content: <Object>[(type: 'text', text: '{"released":true}')],
        isError: false,
      ),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _forceRelease(
  TooManyCooksDb db,
  String? filePath,
  String? agentName,
  String? agentKey,
) {
  if (filePath == null || agentName == null || agentKey == null) {
    return (
      content: <Object>[
        (
          type: 'text',
          text:
              '{"error":"force_release requires file_path, agent_name, agent_key"}',
        ),
      ],
      isError: true,
    );
  }
  return switch (db.forceReleaseLock(filePath, agentName, agentKey)) {
    Success(_) => (
        content: <Object>[(type: 'text', text: '{"released":true}')],
        isError: false,
      ),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _renew(
  TooManyCooksDb db,
  String? filePath,
  String? agentName,
  String? agentKey,
  int timeoutMs,
) {
  if (filePath == null || agentName == null || agentKey == null) {
    return (
      content: <Object>[
        (
          type: 'text',
          text: '{"error":"renew requires file_path, agent_name, agent_key"}',
        ),
      ],
      isError: true,
    );
  }
  return switch (db.renewLock(filePath, agentName, agentKey, timeoutMs)) {
    Success(_) => (
        content: <Object>[(type: 'text', text: '{"renewed":true}')],
        isError: false,
      ),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _query(TooManyCooksDb db, String? filePath) {
  if (filePath == null) {
    return (
      content: <Object>[
        (type: 'text', text: '{"error":"query requires file_path"}'),
      ],
      isError: true,
    );
  }
  return switch (db.queryLock(filePath)) {
    Success(:final value) when value == null => (
        content: <Object>[(type: 'text', text: '{"locked":false}')],
        isError: false,
      ),
    Success(:final value) => (
        content: <Object>[
          (type: 'text', text: '{"locked":true,"lock":${_lockJson(value!)}}'),
        ],
        isError: false,
      ),
    Error(:final error) => _errorResult(error),
  };
}

CallToolResult _list(TooManyCooksDb db) => switch (db.listLocks()) {
      Success(:final value) => (
          content: <Object>[
            (
              type: 'text',
              text: '{"locks":[${value.map(_lockJson).join(',')}]}',
            ),
          ],
          isError: false,
        ),
      Error(:final error) => _errorResult(error),
    };

String _lockJson(FileLock l) => '{"file_path":"${l.filePath}",'
    '"agent_name":"${l.agentName}",'
    '"expires_at":${l.expiresAt}'
    '${l.reason != null ? ',"reason":"${l.reason}"' : ''}}';

String _lockResultJson(LockResult r) => r.acquired
    ? '{"acquired":true,"lock":${_lockJson(r.lock!)}}'
    : '{"acquired":false,"error":"${r.error}"}';

CallToolResult _errorResult(DbError e) => (
      content: <Object>[
        (type: 'text', text: '{"error":"${e.code}: ${e.message}"}'),
      ],
      isError: true,
    );
