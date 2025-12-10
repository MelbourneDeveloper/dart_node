import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_logging/dart_logging.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/types.dart';

void main() {
  // late is required for setUp/tearDown pattern in test files
  // ignore: no_late
  late TooManyCooksDb db;
  // late is required for setUp/tearDown pattern in test files
  // ignore: no_late
  late String testDbPath;
  final logger = createLoggerWithContext(
    createLoggingContext(
      transports: [logTransport(logToConsole)],
      minimumLogLevel: LogLevel.debug,
    ),
  );

  setUpAll(_deleteAllTestDbs);

  setUp(() {
    testDbPath = '.test_${DateTime.now().millisecondsSinceEpoch}.db';
    final config = (
      dbPath: testDbPath,
      lockTimeoutMs: 1000,
      maxMessageLength: 200,
      maxPlanLength: 100,
    );
    logger.info('Creating test database: $testDbPath');
    final result = createDb(config, logger: logger);
    expect(result, isA<Success<TooManyCooksDb, String>>());
    db = switch (result) {
      Success(:final value) => value,
      Error() => throw StateError('DB creation failed'),
    };
  });

  tearDown(() {
    logger.info('Closing and deleting test database: $testDbPath');
    db.close();
    _deleteDbFile(testDbPath);
  });

  group('Identity', () {
    test('register creates agent with key', () {
      final result = db.register('agent1');
      expect(result, isA<Success<AgentRegistration, DbError>>());
      final reg = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      expect(reg.agentName, 'agent1');
      expect(reg.agentKey.length, 64);
    });

    test('register rejects duplicate names', () {
      db.register('agent1');
      final result = db.register('agent1');
      expect(result, isA<Error<AgentRegistration, DbError>>());
      final err = (result as Error<AgentRegistration, DbError>).error;
      expect(err.code, errValidation);
    });

    test('register rejects empty name', () {
      final result = db.register('');
      expect(result, isA<Error<AgentRegistration, DbError>>());
    });

    test('authenticate succeeds with valid credentials', () {
      final regResult = db.register('agent1');
      final reg = (regResult as Success<AgentRegistration, DbError>).value;
      final result = db.authenticate(reg.agentName, reg.agentKey);
      expect(result, isA<Success<AgentIdentity, DbError>>());
    });

    test('authenticate fails with wrong key', () {
      db.register('agent1');
      final result = db.authenticate('agent1', 'wrongkey');
      expect(result, isA<Error<AgentIdentity, DbError>>());
      final err = (result as Error<AgentIdentity, DbError>).error;
      expect(err.code, errUnauthorized);
    });

    test('listAgents returns all agents', () {
      db.register('agent1');
      db.register('agent2');
      final result = db.listAgents();
      expect(result, isA<Success<List<AgentIdentity>, DbError>>());
      final agents = (result as Success<List<AgentIdentity>, DbError>).value;
      expect(agents.length, 2);
    });
  });

  group('Locks', () {
    late AgentRegistration agent1;
    late AgentRegistration agent2;

    setUp(() {
      final r1 = db.register('agent1') as Success<AgentRegistration, DbError>;
      final r2 = db.register('agent2') as Success<AgentRegistration, DbError>;
      agent1 = r1.value;
      agent2 = r2.value;
    });

    test('acquireLock succeeds on free file', () {
      final result = db.acquireLock(
        '/path/file.dart',
        agent1.agentName,
        agent1.agentKey,
        'editing',
        1000,
      );
      expect(result, isA<Success<LockResult, DbError>>());
      final lockResult = (result as Success<LockResult, DbError>).value;
      expect(lockResult.acquired, true);
      expect(lockResult.lock?.agentName, 'agent1');
    });

    test('acquireLock fails if already held', () {
      db.acquireLock(
        '/path/file.dart',
        agent1.agentName,
        agent1.agentKey,
        null,
        10000,
      );
      final result = db.acquireLock(
        '/path/file.dart',
        agent2.agentName,
        agent2.agentKey,
        null,
        1000,
      );
      expect(result, isA<Success<LockResult, DbError>>());
      final lockResult = (result as Success<LockResult, DbError>).value;
      expect(lockResult.acquired, false);
      expect(lockResult.error, contains('agent1'));
    });

    test('releaseLock succeeds for owner', () {
      db.acquireLock(
        '/path/file.dart',
        agent1.agentName,
        agent1.agentKey,
        null,
        1000,
      );
      final result =
          db.releaseLock('/path/file.dart', agent1.agentName, agent1.agentKey);
      expect(result, isA<Success<void, DbError>>());
    });

    test('releaseLock fails for non-owner', () {
      db.acquireLock(
        '/path/file.dart',
        agent1.agentName,
        agent1.agentKey,
        null,
        10000,
      );
      final result =
          db.releaseLock('/path/file.dart', agent2.agentName, agent2.agentKey);
      expect(result, isA<Error<void, DbError>>());
    });

    test('forceReleaseLock fails on non-expired lock', () {
      db.acquireLock(
        '/path/file.dart',
        agent1.agentName,
        agent1.agentKey,
        null,
        100000,
      );
      final result = db.forceReleaseLock(
        '/path/file.dart',
        agent2.agentName,
        agent2.agentKey,
      );
      expect(result, isA<Error<void, DbError>>());
      final err = (result as Error<void, DbError>).error;
      expect(err.code, errLockHeld);
    });

    test('queryLock returns null for unlocked file', () {
      final result = db.queryLock('/path/file.dart');
      expect(result, isA<Success<FileLock?, DbError>>());
      final lock = (result as Success<FileLock?, DbError>).value;
      expect(lock, isNull);
    });

    test('listLocks returns all locks', () {
      db.acquireLock('/a.dart', agent1.agentName, agent1.agentKey, null, 1000);
      db.acquireLock('/b.dart', agent2.agentName, agent2.agentKey, null, 1000);
      final result = db.listLocks();
      expect(result, isA<Success<List<FileLock>, DbError>>());
      final locks = (result as Success<List<FileLock>, DbError>).value;
      expect(locks.length, 2);
    });

    test('renewLock extends expiration', () {
      db.acquireLock(
        '/path/file.dart',
        agent1.agentName,
        agent1.agentKey,
        null,
        1000,
      );
      final beforeResult =
          db.queryLock('/path/file.dart') as Success<FileLock?, DbError>;
      final before = beforeResult.value!;
      db.renewLock('/path/file.dart', agent1.agentName, agent1.agentKey, 5000);
      final afterResult =
          db.queryLock('/path/file.dart') as Success<FileLock?, DbError>;
      final after = afterResult.value!;
      expect(after.expiresAt, greaterThan(before.expiresAt));
    });
  });

  group('Messages', () {
    late AgentRegistration agent1;
    late AgentRegistration agent2;

    setUp(() {
      final r1 = db.register('agent1') as Success<AgentRegistration, DbError>;
      final r2 = db.register('agent2') as Success<AgentRegistration, DbError>;
      agent1 = r1.value;
      agent2 = r2.value;
    });

    test('sendMessage creates message', () {
      final result = db.sendMessage(
        agent1.agentName,
        agent1.agentKey,
        agent2.agentName,
        'Hello!',
      );
      expect(result, isA<Success<String, DbError>>());
    });

    test('sendMessage rejects too long content', () {
      final longContent = 'x' * 300;
      final result = db.sendMessage(
        agent1.agentName,
        agent1.agentKey,
        agent2.agentName,
        longContent,
      );
      expect(result, isA<Error<String, DbError>>());
    });

    test('getMessages returns messages for recipient', () {
      db.sendMessage(
        agent1.agentName,
        agent1.agentKey,
        agent2.agentName,
        'Hello!',
      );
      final result = db.getMessages(agent2.agentName, agent2.agentKey);
      expect(result, isA<Success<List<Message>, DbError>>());
      final messages = (result as Success<List<Message>, DbError>).value;
      expect(messages.length, 1);
      expect(messages.first.content, 'Hello!');
    });

    test('broadcast messages reach all agents', () {
      db.sendMessage(agent1.agentName, agent1.agentKey, '*', 'Broadcast!');
      final result = db.getMessages(agent2.agentName, agent2.agentKey);
      final messages = (result as Success<List<Message>, DbError>).value;
      expect(messages.length, 1);
    });

    test('markRead updates read_at', () {
      db.sendMessage(
        agent1.agentName,
        agent1.agentKey,
        agent2.agentName,
        'Hello!',
      );
      final messages = (db.getMessages(agent2.agentName, agent2.agentKey)
              as Success<List<Message>, DbError>)
          .value;
      final msgId = messages.first.id;
      db.markRead(msgId, agent2.agentName, agent2.agentKey);
      final unread =
          db.getMessages(agent2.agentName, agent2.agentKey, unreadOnly: true);
      expect(
        (unread as Success<List<Message>, DbError>).value.length,
        0,
      );
    });
  });

  group('Plans', () {
    late AgentRegistration agent1;

    setUp(() {
      final r = db.register('agent1') as Success<AgentRegistration, DbError>;
      agent1 = r.value;
    });

    test('updatePlan creates plan', () {
      final result = db.updatePlan(
        agent1.agentName,
        agent1.agentKey,
        'Fix bugs',
        'Reviewing code',
      );
      expect(result, isA<Success<void, DbError>>());
    });

    test('updatePlan rejects too long fields', () {
      final longText = 'x' * 200;
      final result = db.updatePlan(
        agent1.agentName,
        agent1.agentKey,
        longText,
        'task',
      );
      expect(result, isA<Error<void, DbError>>());
    });

    test('getPlan returns agent plan', () {
      db.updatePlan(
        agent1.agentName,
        agent1.agentKey,
        'Fix bugs',
        'Reviewing',
      );
      final result = db.getPlan(agent1.agentName);
      expect(result, isA<Success<AgentPlan?, DbError>>());
      final plan = (result as Success<AgentPlan?, DbError>).value;
      expect(plan?.goal, 'Fix bugs');
    });

    test('getPlan returns null for no plan', () {
      final result = db.getPlan('nonexistent');
      expect((result as Success<AgentPlan?, DbError>).value, isNull);
    });

    test('listPlans returns all plans', () {
      db.updatePlan(agent1.agentName, agent1.agentKey, 'Goal', 'Task');
      final result = db.listPlans();
      expect(result, isA<Success<List<AgentPlan>, DbError>>());
      final plans = (result as Success<List<AgentPlan>, DbError>).value;
      expect(plans.length, 1);
    });
  });

  group('Retry Policy', () {
    test('createDb uses default retry policy', () {
      // Default policy should succeed on valid path
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '.test_retry_default_$ts.db';
      final config = (
        dbPath: path,
        lockTimeoutMs: 1000,
        maxMessageLength: 200,
        maxPlanLength: 100,
      );
      final result = createDb(config, logger: logger);
      expect(result, isA<Success<TooManyCooksDb, String>>());
      (result as Success<TooManyCooksDb, String>).value.close();
      _deleteDbFile(path);
    });

    test('createDb accepts custom retry policy', () {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '.test_retry_custom_$ts.db';
      final config = (
        dbPath: path,
        lockTimeoutMs: 1000,
        maxMessageLength: 200,
        maxPlanLength: 100,
      );
      const customPolicy = (
        maxAttempts: 5,
        baseDelayMs: 10,
        backoffMultiplier: 1.5,
      );
      final result = createDb(
        config,
        logger: logger,
        retryPolicy: customPolicy,
      );
      expect(result, isA<Success<TooManyCooksDb, String>>());
      (result as Success<TooManyCooksDb, String>).value.close();
      _deleteDbFile(path);
    });

    test('retry policy does not retry non-retryable errors', () {
      // Invalid path should fail immediately without retry
      const config = (
        dbPath: '/nonexistent/path/that/does/not/exist/db.sqlite',
        lockTimeoutMs: 1000,
        maxMessageLength: 200,
        maxPlanLength: 100,
      );
      const fastPolicy = (
        maxAttempts: 5,
        baseDelayMs: 1,
        backoffMultiplier: 1.0,
      );
      final start = DateTime.now();
      final result = createDb(
        config,
        logger: logger,
        retryPolicy: fastPolicy,
      );
      final elapsed = DateTime.now().difference(start);
      expect(result, isA<Error<TooManyCooksDb, String>>());
      // Should be fast - no retries on path errors (not I/O errors)
      expect(elapsed.inMilliseconds, lessThan(500));
    });

    test('default retry policy constants are correct', () {
      expect(defaultRetryPolicy.maxAttempts, 3);
      expect(defaultRetryPolicy.baseDelayMs, 50);
      expect(defaultRetryPolicy.backoffMultiplier, 2.0);
    });

    test('concurrent db creation succeeds with retry', () {
      // Simulate concurrent access by creating multiple DBs rapidly
      final paths = <String>[];
      final dbs = <TooManyCooksDb>[];

      for (var i = 0; i < 5; i++) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final path = '.test_concurrent_${ts}_$i.db';
        paths.add(path);
        final config = (
          dbPath: path,
          lockTimeoutMs: 1000,
          maxMessageLength: 200,
          maxPlanLength: 100,
        );
        final result = createDb(config, logger: logger);
        expect(
          result,
          isA<Success<TooManyCooksDb, String>>(),
          reason: 'DB $i should succeed',
        );
        dbs.add((result as Success<TooManyCooksDb, String>).value);
      }

      // Verify all DBs work
      for (var i = 0; i < dbs.length; i++) {
        final reg = dbs[i].register('agent_$i');
        expect(
          reg,
          isA<Success<AgentRegistration, DbError>>(),
          reason: 'Registration in DB $i should succeed',
        );
      }

      // Cleanup
      for (var i = 0; i < dbs.length; i++) {
        dbs[i].close();
        _deleteDbFile(paths[i]);
      }
    });
  });
}

/// Delete all test database files before running tests.
void _deleteAllTestDbs() {
  final fs = requireModule('fs') as JSObject;
  final readdirSync = fs['readdirSync']! as JSFunction;
  final unlinkSync = fs['unlinkSync']! as JSFunction;

  final files =
      (readdirSync.callAsFunction(fs, '.'.toJS)! as JSArray).toDart;
  for (final file in files) {
    final fileName = (file! as JSString).toDart;
    if (fileName.startsWith('.test_') && fileName.endsWith('.db') ||
        fileName.startsWith('.test_') && fileName.contains('.db-')) {
      unlinkSync.callAsFunction(fs, fileName.toJS);
    }
  }

  // Also delete main db files
  for (final dbFile in [
    '.too_many_cooks.db',
    '.too_many_cooks.db-wal',
    '.too_many_cooks.db-shm',
  ]) {
    final existsSync = fs['existsSync']! as JSFunction;
    final exists =
        (existsSync.callAsFunction(fs, dbFile.toJS) as JSBoolean?)?.toDart ??
            false;
    if (exists) {
      unlinkSync.callAsFunction(fs, dbFile.toJS);
    }
  }
}

/// Delete a specific database file and its WAL/SHM files.
void _deleteDbFile(String path) {
  final fs = requireModule('fs') as JSObject;
  final unlinkSync = fs['unlinkSync']! as JSFunction;
  final existsSync = fs['existsSync']! as JSFunction;

  for (final suffix in ['', '-wal', '-shm']) {
    final filePath = '$path$suffix';
    final exists =
        (existsSync.callAsFunction(fs, filePath.toJS) as JSBoolean?)?.toDart ??
            false;
    if (exists) {
      unlinkSync.callAsFunction(fs, filePath.toJS);
    }
  }
}
