/// Database operations for Too Many Cooks.
library;

import 'dart:js_interop';

import 'package:dart_node_better_sqlite3/dart_node_better_sqlite3.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/config.dart';
import 'package:too_many_cooks/src/db/schema.dart';
import 'package:too_many_cooks/src/types.dart';

/// Data access layer typeclass.
typedef TooManyCooksDb = ({
  Result<AgentRegistration, DbError> Function(String agentName) register,
  Result<AgentIdentity, DbError> Function(String agentName, String agentKey)
      authenticate,
  Result<List<AgentIdentity>, DbError> Function() listAgents,
  Result<LockResult, DbError> Function(
    String filePath,
    String agentName,
    String agentKey,
    String? reason,
    int timeoutMs,
  ) acquireLock,
  Result<void, DbError> Function(
    String filePath,
    String agentName,
    String agentKey,
  ) releaseLock,
  Result<void, DbError> Function(
    String filePath,
    String agentName,
    String agentKey,
  ) forceReleaseLock,
  Result<FileLock?, DbError> Function(String filePath) queryLock,
  Result<List<FileLock>, DbError> Function() listLocks,
  Result<void, DbError> Function(
    String filePath,
    String agentName,
    String agentKey,
    int timeoutMs,
  ) renewLock,
  Result<String, DbError> Function(
    String fromAgent,
    String fromKey,
    String toAgent,
    String content,
  ) sendMessage,
  Result<List<Message>, DbError> Function(
    String agentName,
    String agentKey, {
    bool unreadOnly,
  }) getMessages,
  Result<void, DbError> Function(
    String messageId,
    String agentName,
    String agentKey,
  ) markRead,
  Result<void, DbError> Function(
    String agentName,
    String agentKey,
    String goal,
    String currentTask,
  ) updatePlan,
  Result<AgentPlan?, DbError> Function(String agentName) getPlan,
  Result<List<AgentPlan>, DbError> Function() listPlans,
  Result<void, DbError> Function() close,
});

/// Create database instance.
Result<TooManyCooksDb, String> createDb(TooManyCooksConfig config) {
  final dbResult = openDatabase(config.dbPath);
  return switch (dbResult) {
    Success(:final value) => switch (_initSchema(value)) {
        Success(:final value) => Success(_createDbOps(value, config)),
        Error(:final error) => Error(error),
      },
    Error(:final error) => Error(error),
  };
}

Result<Database, String> _initSchema(Database db) {
  final result = db.exec(createTablesSql);
  return switch (result) {
    Success() => Success(db),
    Error(:final error) => Error(error),
  };
}

TooManyCooksDb _createDbOps(Database db, TooManyCooksConfig config) => (
      register: (name) => _register(db, name),
      authenticate: (name, key) => _authenticate(db, name, key),
      listAgents: () => _listAgents(db),
      acquireLock: (path, name, key, reason, timeout) =>
          _acquireLock(db, path, name, key, reason, timeout),
      releaseLock: (path, name, key) => _releaseLock(db, path, name, key),
      forceReleaseLock: (path, name, key) =>
          _forceReleaseLock(db, path, name, key),
      queryLock: (path) => _queryLock(db, path),
      listLocks: () => _listLocks(db),
      renewLock: (path, name, key, timeout) =>
          _renewLock(db, path, name, key, timeout),
      sendMessage: (from, key, to, content) =>
          _sendMessage(db, from, key, to, content, config.maxMessageLength),
      getMessages: (name, key, {unreadOnly = true}) =>
          _getMessages(db, name, key, unreadOnly: unreadOnly),
      markRead: (id, name, key) => _markRead(db, id, name, key),
      updatePlan: (name, key, goal, task) =>
          _updatePlan(db, name, key, goal, task, config.maxPlanLength),
      getPlan: (name) => _getPlan(db, name),
      listPlans: () => _listPlans(db),
      close: () => switch (db.close()) {
        Success() => const Success(null),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    );

extension type _Crypto(JSObject _) implements JSObject {
  external JSUint8Array randomBytes(int size);
}

final _Crypto _crypto = _Crypto(requireModule('crypto') as JSObject);

String _generateKey() {
  final bytes = _crypto.randomBytes(32).toDart;
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

int _now() => DateTime.now().millisecondsSinceEpoch;

Result<void, DbError> _authAndUpdate(
  Database db,
  String agentName,
  String agentKey,
) {
  final stmtResult = db.prepare('''
    UPDATE identity SET last_active = ? WHERE agent_name = ? AND agent_key = ?
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([_now(), agentName, agentKey])) {
        Success(:final value) when value.changes == 0 =>
          const Error((code: errUnauthorized, message: 'Invalid credentials')),
        Success() => const Success(null),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<AgentRegistration, DbError> _register(Database db, String name) {
  if (name.isEmpty || name.length > 50) {
    return const Error(
      (code: errValidation, message: 'Name must be 1-50 chars'),
    );
  }
  final key = _generateKey();
  final now = _now();
  final stmtResult = db.prepare('''
    INSERT INTO identity (agent_name, agent_key, registered_at, last_active)
    VALUES (?, ?, ?, ?)
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([name, key, now, now])) {
        Success() => Success((agentName: name, agentKey: key)),
        Error(:final error) => error.contains('UNIQUE')
            ? const Error(
                (code: errValidation, message: 'Name already registered'))
            : Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<AgentIdentity, DbError> _authenticate(
  Database db,
  String name,
  String key,
) {
  final authResult = _authAndUpdate(db, name, key);
  return switch (authResult) {
    Success() => _getAgent(db, name),
    Error(:final error) => Error(error),
  };
}

Result<AgentIdentity, DbError> _getAgent(Database db, String name) {
  final stmtResult = db.prepare('''
    SELECT agent_name, registered_at, last_active FROM identity
    WHERE agent_name = ?
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.get([name])) {
        Success(:final value) when value == null =>
          const Error((code: errNotFound, message: 'Agent not found')),
        Success(:final value) => Success((
            agentName: value!['agent_name']! as String,
            registeredAt: value['registered_at']! as int,
            lastActive: value['last_active']! as int,
          )),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<List<AgentIdentity>, DbError> _listAgents(Database db) {
  final stmtResult =
      db.prepare('SELECT agent_name, registered_at, last_active FROM identity');
  return switch (stmtResult) {
    Success(:final value) => switch (value.all()) {
        Success(:final value) => Success(
            value
                .map(
                  (r) => (
                    agentName: r['agent_name']! as String,
                    registeredAt: r['registered_at']! as int,
                    lastActive: r['last_active']! as int,
                  ),
                )
                .toList(),
          ),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<LockResult, DbError> _acquireLock(
  Database db,
  String filePath,
  String agentName,
  String agentKey,
  String? reason,
  int timeoutMs,
) {
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final now = _now();
  final expiresAt = now + timeoutMs;

  // Check existing lock
  final existing = _queryLock(db, filePath);
  if (existing case Error(:final error)) return Error(error);
  if (existing case Success(:final value) when value != null) {
    if (value.expiresAt > now) {
      return Success((
        acquired: false,
        lock: null,
        error: 'Held by ${value.agentName} until ${value.expiresAt}',
      ));
    }
    // Expired - delete it
    final delResult =
        db.exec("DELETE FROM locks WHERE file_path = '$filePath'");
    if (delResult case Error(:final error)) {
      return Error((code: errDatabase, message: error));
    }
  }

  final stmtResult = db.prepare('''
    INSERT INTO locks (file_path, agent_name, acquired_at, expires_at, reason)
    VALUES (?, ?, ?, ?, ?)
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (
          value.run([filePath, agentName, now, expiresAt, reason])) {
        Success() => Success((
            acquired: true,
            lock: (
              filePath: filePath,
              agentName: agentName,
              acquiredAt: now,
              expiresAt: expiresAt,
              reason: reason,
              version: 1,
            ),
            error: null,
          )),
        Error(:final error) => error.contains('UNIQUE')
            ? const Success((
                acquired: false,
                lock: null,
                error: 'Lock race condition',
              ))
            : Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<void, DbError> _releaseLock(
  Database db,
  String filePath,
  String agentName,
  String agentKey,
) {
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final stmtResult = db.prepare('''
    DELETE FROM locks WHERE file_path = ? AND agent_name = ?
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([filePath, agentName])) {
        Success(:final value) when value.changes == 0 =>
          const Error((code: errNotFound, message: 'Lock not held by you')),
        Success() => const Success(null),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<void, DbError> _forceReleaseLock(
  Database db,
  String filePath,
  String agentName,
  String agentKey,
) {
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final existing = _queryLock(db, filePath);
  return switch (existing) {
    Error(:final error) => Error(error),
    Success(:final value) when value == null =>
      const Error((code: errNotFound, message: 'No lock exists')),
    Success(:final value) when value!.expiresAt > _now() => Error((
        code: errLockHeld,
        message: 'Lock not expired, held by ${value.agentName}',
      )),
    Success() => switch (
          db.exec("DELETE FROM locks WHERE file_path = '$filePath'")) {
        Success() => const Success(null),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
  };
}

Result<FileLock?, DbError> _queryLock(Database db, String filePath) {
  final stmtResult = db.prepare('SELECT * FROM locks WHERE file_path = ?');
  return switch (stmtResult) {
    Success(:final value) => switch (value.get([filePath])) {
        Success(:final value) when value == null => const Success(null),
        Success(:final value) => Success((
            filePath: value!['file_path']! as String,
            agentName: value['agent_name']! as String,
            acquiredAt: value['acquired_at']! as int,
            expiresAt: value['expires_at']! as int,
            reason: value['reason'] as String?,
            version: value['version']! as int,
          )),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<List<FileLock>, DbError> _listLocks(Database db) {
  final stmtResult = db.prepare('SELECT * FROM locks');
  return switch (stmtResult) {
    Success(:final value) => switch (value.all()) {
        Success(:final value) => Success(
            value
                .map(
                  (r) => (
                    filePath: r['file_path']! as String,
                    agentName: r['agent_name']! as String,
                    acquiredAt: r['acquired_at']! as int,
                    expiresAt: r['expires_at']! as int,
                    reason: r['reason'] as String?,
                    version: r['version']! as int,
                  ),
                )
                .toList(),
          ),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<void, DbError> _renewLock(
  Database db,
  String filePath,
  String agentName,
  String agentKey,
  int timeoutMs,
) {
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final newExpiry = _now() + timeoutMs;
  final stmtResult = db.prepare('''
    UPDATE locks SET expires_at = ?, version = version + 1
    WHERE file_path = ? AND agent_name = ?
  ''');
  return switch (stmtResult) {
    Success(:final value) =>
      switch (value.run([newExpiry, filePath, agentName])) {
        Success(:final value) when value.changes == 0 =>
          const Error((code: errNotFound, message: 'Lock not held by you')),
        Success() => const Success(null),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<String, DbError> _sendMessage(
  Database db,
  String fromAgent,
  String fromKey,
  String toAgent,
  String content,
  int maxLen,
) {
  final authResult = _authAndUpdate(db, fromAgent, fromKey);
  if (authResult case Error(:final error)) return Error(error);

  if (content.length > maxLen) {
    return Error(
      (code: errValidation, message: 'Content exceeds $maxLen chars'),
    );
  }

  final id = _generateKey().substring(0, 16);
  final now = _now();
  final stmtResult = db.prepare('''
    INSERT INTO messages (id, from_agent, to_agent, content, created_at)
    VALUES (?, ?, ?, ?, ?)
  ''');
  return switch (stmtResult) {
    Success(:final value) =>
      switch (value.run([id, fromAgent, toAgent, content, now])) {
        Success() => Success(id),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<List<Message>, DbError> _getMessages(
  Database db,
  String agentName,
  String agentKey, {
  required bool unreadOnly,
}) {
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final sql = unreadOnly
      ? '''
SELECT * FROM messages WHERE (to_agent = ? OR to_agent = '*')
AND read_at IS NULL ORDER BY created_at DESC'''
      : '''
SELECT * FROM messages WHERE (to_agent = ? OR to_agent = '*')
ORDER BY created_at DESC''';
  final stmtResult = db.prepare(sql);
  return switch (stmtResult) {
    Success(:final value) => switch (value.all([agentName])) {
        Success(:final value) => Success(
            value
                .map(
                  (r) => (
                    id: r['id']! as String,
                    fromAgent: r['from_agent']! as String,
                    toAgent: r['to_agent']! as String,
                    content: r['content']! as String,
                    createdAt: r['created_at']! as int,
                    readAt: r['read_at'] as int?,
                  ),
                )
                .toList(),
          ),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<void, DbError> _markRead(
  Database db,
  String messageId,
  String agentName,
  String agentKey,
) {
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final stmtResult = db.prepare('''
    UPDATE messages SET read_at = ?
    WHERE id = ? AND (to_agent = ? OR to_agent = '*')
  ''');
  return switch (stmtResult) {
    Success(:final value) =>
      switch (value.run([_now(), messageId, agentName])) {
        Success(:final value) when value.changes == 0 =>
          const Error((code: errNotFound, message: 'Message not found')),
        Success() => const Success(null),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<void, DbError> _updatePlan(
  Database db,
  String agentName,
  String agentKey,
  String goal,
  String currentTask,
  int maxLen,
) {
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  if (goal.length > maxLen || currentTask.length > maxLen) {
    return Error(
      (code: errValidation, message: 'Fields exceed $maxLen chars'),
    );
  }

  final stmtResult = db.prepare('''
    INSERT INTO plans (agent_name, goal, current_task, updated_at)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(agent_name) DO UPDATE SET
      goal = excluded.goal,
      current_task = excluded.current_task,
      updated_at = excluded.updated_at
  ''');
  return switch (stmtResult) {
    Success(:final value) =>
      switch (value.run([agentName, goal, currentTask, _now()])) {
        Success() => const Success(null),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<AgentPlan?, DbError> _getPlan(Database db, String agentName) {
  final stmtResult = db.prepare('SELECT * FROM plans WHERE agent_name = ?');
  return switch (stmtResult) {
    Success(:final value) => switch (value.get([agentName])) {
        Success(:final value) when value == null => const Success(null),
        Success(:final value) => Success((
            agentName: value!['agent_name']! as String,
            goal: value['goal']! as String,
            currentTask: value['current_task']! as String,
            updatedAt: value['updated_at']! as int,
          )),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<List<AgentPlan>, DbError> _listPlans(Database db) {
  final stmtResult = db.prepare('SELECT * FROM plans');
  return switch (stmtResult) {
    Success(:final value) => switch (value.all()) {
        Success(:final value) => Success(
            value
                .map(
                  (r) => (
                    agentName: r['agent_name']! as String,
                    goal: r['goal']! as String,
                    currentTask: r['current_task']! as String,
                    updatedAt: r['updated_at']! as int,
                  ),
                )
                .toList(),
          ),
        Error(:final error) => Error((code: errDatabase, message: error)),
      },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}
