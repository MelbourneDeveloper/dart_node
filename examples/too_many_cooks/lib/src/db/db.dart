/// Database operations for Too Many Cooks.
library;

import 'dart:js_interop';

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_better_sqlite3/dart_node_better_sqlite3.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks/src/config.dart';
import 'package:too_many_cooks/src/db/schema.dart';
import 'package:too_many_cooks/src/types.dart';

@JS('require')
external JSObject _require(String module);

extension type _Fs(JSObject _) implements JSObject {
  external bool existsSync(String path);
  external void mkdirSync(String path, _MkdirOptions options);
}

extension type _MkdirOptions._(JSObject _) implements JSObject {
  external factory _MkdirOptions({bool recursive});
}

extension type _Path(JSObject _) implements JSObject {
  external String dirname(String path);
}

final _Fs _fs = _Fs(_require('fs'));
final _Path _path = _Path(_require('path'));

/// SQLite-specific retryable errors.
bool _isSqliteRetryable(String error) =>
    error.contains('disk I/O error') ||
    error.contains('database is locked') ||
    error.contains('SQLITE_BUSY');

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
  )
  acquireLock,
  Result<void, DbError> Function(
    String filePath,
    String agentName,
    String agentKey,
  )
  releaseLock,
  Result<void, DbError> Function(
    String filePath,
    String agentName,
    String agentKey,
  )
  forceReleaseLock,
  Result<FileLock?, DbError> Function(String filePath) queryLock,
  Result<List<FileLock>, DbError> Function() listLocks,
  Result<void, DbError> Function(
    String filePath,
    String agentName,
    String agentKey,
    int timeoutMs,
  )
  renewLock,
  Result<String, DbError> Function(
    String fromAgent,
    String fromKey,
    String toAgent,
    String content,
  )
  sendMessage,
  Result<List<Message>, DbError> Function(
    String agentName,
    String agentKey, {
    bool unreadOnly,
  })
  getMessages,
  Result<void, DbError> Function(
    String messageId,
    String agentName,
    String agentKey,
  )
  markRead,
  Result<void, DbError> Function(
    String agentName,
    String agentKey,
    String goal,
    String currentTask,
  )
  updatePlan,
  Result<AgentPlan?, DbError> Function(String agentName) getPlan,
  Result<List<AgentPlan>, DbError> Function() listPlans,
  Result<List<Message>, DbError> Function() listAllMessages,
  Result<void, DbError> Function() close,
  // Admin operations (no auth required - for VSCode extension)
  Result<void, DbError> Function(String filePath) adminDeleteLock,
  Result<void, DbError> Function(String agentName) adminDeleteAgent,
  Result<AgentRegistration, DbError> Function(String agentName) adminResetKey,
});

/// Create database instance with retry policy.
Result<TooManyCooksDb, String> createDb(
  TooManyCooksConfig config, {
  Logger? logger,
  RetryPolicy retryPolicy = defaultRetryPolicy,
}) {
  final log = logger?.child({'component': 'db'}) ?? _noOpLogger()
    ..info('Opening database at ${config.dbPath}');

  return withRetry(
    retryPolicy,
    _isSqliteRetryable,
    () => _tryCreateDb(config, log),
    onRetry: (attempt, error, delayMs) => log.warn(
      'Attempt $attempt failed (retryable): $error. '
      'Retrying in ${delayMs}ms...',
    ),
  );
}

Result<TooManyCooksDb, String> _tryCreateDb(
  TooManyCooksConfig config,
  Logger log,
) {
  // Ensure parent directory exists for the database file
  final dbDir = _path.dirname(config.dbPath);
  if (!_fs.existsSync(dbDir)) {
    log.info('Creating database directory: $dbDir');
    try {
      _fs.mkdirSync(dbDir, _MkdirOptions(recursive: true));
    } on Object catch (e) {
      return Error('Failed to create database directory: $e');
    }
  }

  final dbResult = openDatabase(config.dbPath);
  return switch (dbResult) {
    Success(:final value) => switch (_initSchema(value, log)) {
      Success(:final value) => Success(_createDbOps(value, config, log)),
      Error(:final error) => Error<TooManyCooksDb, String>(error),
    },
    Error(:final error) => Error<TooManyCooksDb, String>(error),
  };
}

Logger _noOpLogger() => createLoggerWithContext(createLoggingContext());

Result<Database, String> _initSchema(Database db, Logger log) {
  log.debug('Initializing database schema');
  final result = db.exec(createTablesSql);
  return switch (result) {
    Success() => () {
      log.debug('Schema initialized successfully');
      return Success<Database, String>(db);
    }(),
    Error(:final error) => () {
      log.error('Schema initialization failed: $error');
      return Error<Database, String>(error);
    }(),
  };
}

TooManyCooksDb _createDbOps(
  Database db,
  TooManyCooksConfig config,
  Logger log,
) => (
  register: (name) => _register(db, log, name),
  authenticate: (name, key) => _authenticate(db, log, name, key),
  listAgents: () => _listAgents(db, log),
  acquireLock: (path, name, key, reason, timeout) =>
      _acquireLock(db, log, path, name, key, reason, timeout),
  releaseLock: (path, name, key) => _releaseLock(db, log, path, name, key),
  forceReleaseLock: (path, name, key) =>
      _forceReleaseLock(db, log, path, name, key),
  queryLock: (path) => _queryLock(db, log, path),
  listLocks: () => _listLocks(db, log),
  renewLock: (path, name, key, timeout) =>
      _renewLock(db, log, path, name, key, timeout),
  sendMessage: (from, key, to, content) =>
      _sendMessage(db, log, from, key, to, content, config.maxMessageLength),
  getMessages: (name, key, {unreadOnly = true}) =>
      _getMessages(db, log, name, key, unreadOnly: unreadOnly),
  markRead: (id, name, key) => _markRead(db, log, id, name, key),
  updatePlan: (name, key, goal, task) =>
      _updatePlan(db, log, name, key, goal, task, config.maxPlanLength),
  getPlan: (name) => _getPlan(db, log, name),
  listPlans: () => _listPlans(db, log),
  listAllMessages: () => _listAllMessages(db, log),
  close: () {
    log.info('Closing database');
    return switch (db.close()) {
      Success() => const Success(null),
      Error(:final error) => Error((code: errDatabase, message: error)),
    };
  },
  adminDeleteLock: (path) => _adminDeleteLock(db, log, path),
  adminDeleteAgent: (name) => _adminDeleteAgent(db, log, name),
  adminResetKey: (name) => _adminResetKey(db, log, name),
);

extension type _Crypto(JSObject _) implements JSObject {
  external JSUint8Array randomBytes(int size);
}

// requireModule returns JSAny which must be cast to JSObject for extension type
// ignore: no_casts
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
      Success(:final value) when value.changes == 0 => const Error((
        code: errUnauthorized,
        message: 'Invalid credentials',
      )),
      Success() => const Success(null),
      Error(:final error) => Error((code: errDatabase, message: error)),
    },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<AgentRegistration, DbError> _register(
  Database db,
  Logger log,
  String name,
) {
  log.debug('Registering agent: $name');
  if (name.isEmpty || name.length > 50) {
    log.warn('Registration failed: invalid name length');
    return const Error((
      code: errValidation,
      message: 'Name must be 1-50 chars',
    ));
  }
  final key = _generateKey();
  final now = _now();
  final stmtResult = db.prepare('''
    INSERT INTO identity (agent_name, agent_key, registered_at, last_active)
    VALUES (?, ?, ?, ?)
  ''');
  if (stmtResult case Error(:final error)) {
    log.error('Registration failed: $error');
    return Error((code: errDatabase, message: error));
  }
  final stmt = (stmtResult as Success<Statement, String>).value;
  final runResult = stmt.run([name, key, now, now]);
  if (runResult case Error(:final error)) {
    if (error.contains('UNIQUE')) {
      log.warn('Registration failed: name already exists');
      return const Error((
        code: errValidation,
        message: 'Name already registered',
      ));
    }
    log.error('Registration failed: $error');
    return Error((code: errDatabase, message: error));
  }
  log.info('Agent registered: $name');
  return Success((agentName: name, agentKey: key));
}

Result<AgentIdentity, DbError> _authenticate(
  Database db,
  Logger log,
  String name,
  String key,
) {
  log.debug('Authenticating agent: $name');
  final authResult = _authAndUpdate(db, name, key);
  if (authResult case Error(:final error)) {
    log.warn('Authentication failed for $name');
    return Error(error);
  }
  return _getAgent(db, name);
}

Result<AgentIdentity, DbError> _getAgent(Database db, String name) {
  final stmtResult = db.prepare('''
    SELECT agent_name, registered_at, last_active FROM identity
    WHERE agent_name = ?
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.get([name])) {
      Success(:final value) when value == null => const Error((
        code: errNotFound,
        message: 'Agent not found',
      )),
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

Result<List<AgentIdentity>, DbError> _listAgents(Database db, Logger log) {
  log.debug('Listing all agents');
  final stmtResult = db.prepare(
    'SELECT agent_name, registered_at, last_active FROM identity',
  );
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
  Logger log,
  String filePath,
  String agentName,
  String agentKey,
  String? reason,
  int timeoutMs,
) {
  log.debug('Acquiring lock on $filePath for $agentName');
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final now = _now();
  final expiresAt = now + timeoutMs;

  // Check existing lock
  final existing = _queryLock(db, log, filePath);
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
    final delStmtResult = db.prepare('DELETE FROM locks WHERE file_path = ?');
    if (delStmtResult case Error(:final error)) {
      return Error((code: errDatabase, message: error));
    }
    final delStmt = (delStmtResult as Success<Statement, String>).value;
    final delResult = delStmt.run([filePath]);
    if (delResult case Error(:final error)) {
      return Error((code: errDatabase, message: error));
    }
  }

  final stmtResult = db.prepare('''
    INSERT INTO locks (file_path, agent_name, acquired_at, expires_at, reason)
    VALUES (?, ?, ?, ?, ?)
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([
      filePath,
      agentName,
      now,
      expiresAt,
      reason,
    ])) {
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
      Error(:final error) =>
        error.contains('UNIQUE')
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
  Logger log,
  String filePath,
  String agentName,
  String agentKey,
) {
  log.debug('Releasing lock on $filePath for $agentName');
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final stmtResult = db.prepare('''
    DELETE FROM locks WHERE file_path = ? AND agent_name = ?
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([filePath, agentName])) {
      Success(:final value) when value.changes == 0 => const Error((
        code: errNotFound,
        message: 'Lock not held by you',
      )),
      Success() => const Success(null),
      Error(:final error) => Error((code: errDatabase, message: error)),
    },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<void, DbError> _forceReleaseLock(
  Database db,
  Logger log,
  String filePath,
  String agentName,
  String agentKey,
) {
  log.debug('Force releasing lock on $filePath for $agentName');
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final existing = _queryLock(db, log, filePath);
  return switch (existing) {
    Error(:final error) => Error(error),
    Success(:final value) when value == null => const Error((
      code: errNotFound,
      message: 'No lock exists',
    )),
    Success(:final value) when value!.expiresAt > _now() => Error((
      code: errLockHeld,
      message: 'Lock not expired, held by ${value.agentName}',
    )),
    Success() => _deleteExpiredLock(db, filePath),
  };
}

Result<void, DbError> _deleteExpiredLock(Database db, String filePath) {
  final stmtResult = db.prepare('DELETE FROM locks WHERE file_path = ?');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([filePath])) {
      Success() => const Success(null),
      Error(:final error) => Error((code: errDatabase, message: error)),
    },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<FileLock?, DbError> _queryLock(
  Database db,
  Logger log,
  String filePath,
) {
  log.trace('Querying lock for $filePath');
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

Result<List<FileLock>, DbError> _listLocks(Database db, Logger log) {
  log.trace('Listing all locks');
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
  Logger log,
  String filePath,
  String agentName,
  String agentKey,
  int timeoutMs,
) {
  log.debug('Renewing lock on $filePath for $agentName');
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final newExpiry = _now() + timeoutMs;
  final stmtResult = db.prepare('''
    UPDATE locks SET expires_at = ?, version = version + 1
    WHERE file_path = ? AND agent_name = ?
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([
      newExpiry,
      filePath,
      agentName,
    ])) {
      Success(:final value) when value.changes == 0 => const Error((
        code: errNotFound,
        message: 'Lock not held by you',
      )),
      Success() => const Success(null),
      Error(:final error) => Error((code: errDatabase, message: error)),
    },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<String, DbError> _sendMessage(
  Database db,
  Logger log,
  String fromAgent,
  String fromKey,
  String toAgent,
  String content,
  int maxLen,
) {
  log.debug('Sending message from $fromAgent to $toAgent');
  final authResult = _authAndUpdate(db, fromAgent, fromKey);
  if (authResult case Error(:final error)) return Error(error);

  if (content.length > maxLen) {
    return Error((
      code: errValidation,
      message: 'Content exceeds $maxLen chars',
    ));
  }

  final id = _generateKey().substring(0, 16);
  final now = _now();
  final stmtResult = db.prepare('''
    INSERT INTO messages (id, from_agent, to_agent, content, created_at)
    VALUES (?, ?, ?, ?, ?)
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([
      id,
      fromAgent,
      toAgent,
      content,
      now,
    ])) {
      Success() => Success(id),
      Error(:final error) => Error((code: errDatabase, message: error)),
    },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<List<Message>, DbError> _getMessages(
  Database db,
  Logger log,
  String agentName,
  String agentKey, {
  required bool unreadOnly,
}) {
  log.trace('Getting messages for $agentName (unreadOnly: $unreadOnly)');
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
      Success(:final value) => () {
        final messageList = value
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
            .toList();
        // Auto-mark fetched messages as read (agent proved identity with key)
        _autoMarkRead(db, log, agentName, messageList);
        return Success<List<Message>, DbError>(messageList);
      }(),
      Error(:final error) => Error<List<Message>, DbError>((
        code: errDatabase,
        message: error,
      )),
    },
    Error(:final error) => Error<List<Message>, DbError>((
      code: errDatabase,
      message: error,
    )),
  };
}

void _autoMarkRead(
  Database db,
  Logger log,
  String agentName,
  List<Message> messageList,
) {
  final unreadIds = messageList
      .where((m) => m.readAt == null)
      .map((m) => m.id)
      .toList();
  if (unreadIds.isEmpty) return;

  final now = _now();
  final stmtResult = db.prepare('''
    UPDATE messages SET read_at = ?
    WHERE id = ? AND to_agent = ? AND read_at IS NULL
  ''');
  if (stmtResult case Error(:final error)) {
    log.warn('Failed to auto-mark messages read: $error');
    return;
  }
  final stmt = (stmtResult as Success<Statement, String>).value;
  for (final id in unreadIds) {
    final result = stmt.run([now, id, agentName]);
    if (result case Error(:final error)) {
      log.warn('Failed to mark message $id as read: $error');
    }
  }
  log.debug('Auto-marked ${unreadIds.length} messages as read for $agentName');
}

Result<void, DbError> _markRead(
  Database db,
  Logger log,
  String messageId,
  String agentName,
  String agentKey,
) {
  log.trace('Marking message $messageId as read for $agentName');
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  final stmtResult = db.prepare('''
    UPDATE messages SET read_at = ?
    WHERE id = ? AND to_agent = ?
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([
      _now(),
      messageId,
      agentName,
    ])) {
      Success(:final value) when value.changes == 0 => const Error((
        code: errNotFound,
        message: 'Message not found',
      )),
      Success() => const Success(null),
      Error(:final error) => Error((code: errDatabase, message: error)),
    },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<void, DbError> _updatePlan(
  Database db,
  Logger log,
  String agentName,
  String agentKey,
  String goal,
  String currentTask,
  int maxLen,
) {
  log.debug('Updating plan for $agentName');
  final authResult = _authAndUpdate(db, agentName, agentKey);
  if (authResult case Error(:final error)) return Error(error);

  if (goal.length > maxLen || currentTask.length > maxLen) {
    return Error((code: errValidation, message: 'Fields exceed $maxLen chars'));
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
    Success(:final value) => switch (value.run([
      agentName,
      goal,
      currentTask,
      _now(),
    ])) {
      Success() => const Success(null),
      Error(:final error) => Error((code: errDatabase, message: error)),
    },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<AgentPlan?, DbError> _getPlan(
  Database db,
  Logger log,
  String agentName,
) {
  log.trace('Getting plan for $agentName');
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

Result<List<AgentPlan>, DbError> _listPlans(Database db, Logger log) {
  log.trace('Listing all plans');
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

Result<List<Message>, DbError> _listAllMessages(Database db, Logger log) {
  log.trace('Listing all messages');
  final stmtResult = db.prepare(
    'SELECT * FROM messages ORDER BY created_at DESC',
  );
  return switch (stmtResult) {
    Success(:final value) => switch (value.all()) {
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

// === Admin Operations (no auth required) ===

Result<void, DbError> _adminDeleteLock(
  Database db,
  Logger log,
  String filePath,
) {
  log.warn('Admin deleting lock on $filePath');
  final stmtResult = db.prepare('DELETE FROM locks WHERE file_path = ?');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([filePath])) {
      Success(:final value) when value.changes == 0 => const Error((
        code: errNotFound,
        message: 'Lock not found',
      )),
      Success() => const Success(null),
      Error(:final error) => Error((code: errDatabase, message: error)),
    },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<void, DbError> _adminDeleteAgent(
  Database db,
  Logger log,
  String agentName,
) {
  log.warn('Admin deleting agent $agentName');
  // Delete agent's locks, messages, plans, then identity
  final deleteLocks = db.prepare('DELETE FROM locks WHERE agent_name = ?');
  final deleteMessages = db.prepare(
    'DELETE FROM messages WHERE from_agent = ? OR to_agent = ?',
  );
  final deletePlans = db.prepare('DELETE FROM plans WHERE agent_name = ?');
  final deleteIdentity = db.prepare(
    'DELETE FROM identity WHERE agent_name = ?',
  );

  // Check all prepared successfully
  for (final stmtResult in [deleteLocks, deleteMessages, deletePlans]) {
    if (stmtResult case Error(:final error)) {
      return Error((code: errDatabase, message: error));
    }
  }
  if (deleteIdentity case Error(:final error)) {
    return Error((code: errDatabase, message: error));
  }

  // Run the deletes
  final locksStmt = (deleteLocks as Success<Statement, String>).value;
  final msgsStmt = (deleteMessages as Success<Statement, String>).value;
  final plansStmt = (deletePlans as Success<Statement, String>).value;
  final idStmt = (deleteIdentity as Success<Statement, String>).value;

  if (locksStmt.run([agentName]) case Error(:final error)) {
    return Error((code: errDatabase, message: error));
  }
  if (msgsStmt.run([agentName, agentName]) case Error(:final error)) {
    return Error((code: errDatabase, message: error));
  }
  if (plansStmt.run([agentName]) case Error(:final error)) {
    return Error((code: errDatabase, message: error));
  }

  return switch (idStmt.run([agentName])) {
    Success(:final value) when value.changes == 0 => const Error((
      code: errNotFound,
      message: 'Agent not found',
    )),
    Success() => const Success(null),
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}

Result<AgentRegistration, DbError> _adminResetKey(
  Database db,
  Logger log,
  String agentName,
) {
  log.warn('Admin resetting key for agent $agentName');

  // Release all locks held by this agent since old key is now invalid
  final deleteLocks = db.prepare('DELETE FROM locks WHERE agent_name = ?');
  switch (deleteLocks) {
    case Success(:final value):
      final result = value.run([agentName]);
      switch (result) {
        case Success(:final value):
          if (value.changes > 0) {
            log.warn('Released ${value.changes} locks for agent $agentName');
          }
        case Error(:final error):
          log.warn('Failed to release locks: $error');
      }
    case Error(:final error):
      log.warn('Failed to prepare lock deletion: $error');
  }

  final newKey = _generateKey();
  final now = _now();
  final stmtResult = db.prepare('''
    UPDATE identity SET agent_key = ?, last_active = ?
    WHERE agent_name = ?
  ''');
  return switch (stmtResult) {
    Success(:final value) => switch (value.run([newKey, now, agentName])) {
      Success(:final value) when value.changes == 0 => const Error((
        code: errNotFound,
        message: 'Agent not found',
      )),
      Success() => Success((agentName: agentName, agentKey: newKey)),
      Error(:final error) => Error((code: errDatabase, message: error)),
    },
    Error(:final error) => Error((code: errDatabase, message: error)),
  };
}
