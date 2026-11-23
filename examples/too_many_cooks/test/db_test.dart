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
      final err = switch (result) {
        Error(:final error) => error,
        Success() => throw StateError('Expected error'),
      };
      expect(err.code, errValidation);
    });

    test('register rejects empty name', () {
      final result = db.register('');
      expect(result, isA<Error<AgentRegistration, DbError>>());
    });

    test('authenticate succeeds with valid credentials', () {
      final regResult = db.register('agent1');
      final reg = switch (regResult) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      final result = db.authenticate(reg.agentName, reg.agentKey);
      expect(result, isA<Success<AgentIdentity, DbError>>());
    });

    test('authenticate fails with wrong key', () {
      db.register('agent1');
      final result = db.authenticate('agent1', 'wrongkey');
      expect(result, isA<Error<AgentIdentity, DbError>>());
      final err = switch (result) {
        Error(:final error) => error,
        Success() => throw StateError('Expected error'),
      };
      expect(err.code, errUnauthorized);
    });

    test('listAgents returns all agents', () {
      db.register('agent1');
      db.register('agent2');
      final result = db.listAgents();
      expect(result, isA<Success<List<AgentIdentity>, DbError>>());
      final agents = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      expect(agents.length, 2);
    });
  });

  group('Locks', () {
    // late is required for setUp/tearDown pattern in test files
    // ignore: no_late
    late AgentRegistration agent1;
    // late is required for setUp/tearDown pattern in test files
    // ignore: no_late
    late AgentRegistration agent2;

    setUp(() {
      final r1 = db.register('agent1');
      final r2 = db.register('agent2');
      agent1 = switch (r1) {
        Success(:final value) => value,
        Error() => throw StateError('Registration failed'),
      };
      agent2 = switch (r2) {
        Success(:final value) => value,
        Error() => throw StateError('Registration failed'),
      };
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
      final lockResult = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
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
      final lockResult = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
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
      final result = db.releaseLock(
        '/path/file.dart',
        agent1.agentName,
        agent1.agentKey,
      );
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
      final result = db.releaseLock(
        '/path/file.dart',
        agent2.agentName,
        agent2.agentKey,
      );
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
      final err = switch (result) {
        Error(:final error) => error,
        Success() => throw StateError('Expected error'),
      };
      expect(err.code, errLockHeld);
    });

    test('queryLock returns null for unlocked file', () {
      final result = db.queryLock('/path/file.dart');
      expect(result, isA<Success<FileLock?, DbError>>());
      final lock = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      expect(lock, isNull);
    });

    test('listLocks returns all locks', () {
      db.acquireLock('/a.dart', agent1.agentName, agent1.agentKey, null, 1000);
      db.acquireLock('/b.dart', agent2.agentName, agent2.agentKey, null, 1000);
      final result = db.listLocks();
      expect(result, isA<Success<List<FileLock>, DbError>>());
      final locks = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
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
      final beforeResult = db.queryLock('/path/file.dart');
      final before = switch (beforeResult) {
        Success(:final value) => value!,
        Error() => throw StateError('Expected success'),
      };
      db.renewLock('/path/file.dart', agent1.agentName, agent1.agentKey, 5000);
      final afterResult = db.queryLock('/path/file.dart');
      final after = switch (afterResult) {
        Success(:final value) => value!,
        Error() => throw StateError('Expected success'),
      };
      expect(after.expiresAt, greaterThan(before.expiresAt));
    });

    test('acquireLock succeeds on expired lock', () async {
      // Create lock with very short timeout (10ms)
      db.acquireLock(
        '/path/expire.dart',
        agent1.agentName,
        agent1.agentKey,
        null,
        10, // 10ms timeout
      );

      // Wait for lock to expire
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Agent2 should be able to acquire the expired lock
      final result = db.acquireLock(
        '/path/expire.dart',
        agent2.agentName,
        agent2.agentKey,
        'taking over expired lock',
        1000,
      );
      expect(result, isA<Success<LockResult, DbError>>());
      final lockResult = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      expect(lockResult.acquired, true);
      expect(lockResult.lock?.agentName, 'agent2');
    });

    test('forceReleaseLock succeeds on expired lock', () async {
      // Create lock with very short timeout (10ms)
      db.acquireLock(
        '/path/force.dart',
        agent1.agentName,
        agent1.agentKey,
        null,
        10, // 10ms timeout
      );

      // Wait for lock to expire
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Agent2 should be able to force release the expired lock
      final result = db.forceReleaseLock(
        '/path/force.dart',
        agent2.agentName,
        agent2.agentKey,
      );
      expect(result, isA<Success<void, DbError>>());

      // Verify lock is gone
      final query = db.queryLock('/path/force.dart');
      final lock = switch (query) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      expect(lock, isNull);
    });

    test('forceReleaseLock on non-existent lock fails', () {
      final result = db.forceReleaseLock(
        '/path/nonexistent.dart',
        agent1.agentName,
        agent1.agentKey,
      );
      expect(result, isA<Error<void, DbError>>());
      final err = switch (result) {
        Error(:final error) => error,
        Success() => throw StateError('Expected error'),
      };
      expect(err.code, errNotFound);
    });
  });

  group('Messages', () {
    // late is required for setUp/tearDown pattern in test files
    // ignore: no_late
    late AgentRegistration agent1;
    // late is required for setUp/tearDown pattern in test files
    // ignore: no_late
    late AgentRegistration agent2;

    setUp(() {
      final r1 = db.register('agent1');
      final r2 = db.register('agent2');
      agent1 = switch (r1) {
        Success(:final value) => value,
        Error() => throw StateError('Registration failed'),
      };
      agent2 = switch (r2) {
        Success(:final value) => value,
        Error() => throw StateError('Registration failed'),
      };
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
      final messages = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      expect(messages.length, 1);
      expect(messages.first.content, 'Hello!');
    });

    test('broadcast messages reach all agents', () {
      db.sendMessage(agent1.agentName, agent1.agentKey, '*', 'Broadcast!');
      final result = db.getMessages(agent2.agentName, agent2.agentKey);
      final messages = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      expect(messages.length, 1);
    });

    test('markRead updates read_at', () {
      db.sendMessage(
        agent1.agentName,
        agent1.agentKey,
        agent2.agentName,
        'Hello!',
      );
      final messagesResult = db.getMessages(agent2.agentName, agent2.agentKey);
      final messages = switch (messagesResult) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      final msgId = messages.first.id;
      db.markRead(msgId, agent2.agentName, agent2.agentKey);
      final unread = db.getMessages(
        agent2.agentName,
        agent2.agentKey,
        unreadOnly: true,
      );
      final unreadMessages = switch (unread) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      expect(unreadMessages.length, 0);
    });
  });

  group('Plans', () {
    // late is required for setUp/tearDown pattern in test files
    // ignore: no_late
    late AgentRegistration agent1;

    setUp(() {
      final r = db.register('agent1');
      agent1 = switch (r) {
        Success(:final value) => value,
        Error() => throw StateError('Registration failed'),
      };
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
      db.updatePlan(agent1.agentName, agent1.agentKey, 'Fix bugs', 'Reviewing');
      final result = db.getPlan(agent1.agentName);
      expect(result, isA<Success<AgentPlan?, DbError>>());
      final plan = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      expect(plan?.goal, 'Fix bugs');
    });

    test('getPlan returns null for no plan', () {
      final result = db.getPlan('nonexistent');
      final plan = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
      expect(plan, isNull);
    });

    test('listPlans returns all plans', () {
      db.updatePlan(agent1.agentName, agent1.agentKey, 'Goal', 'Task');
      final result = db.listPlans();
      expect(result, isA<Success<List<AgentPlan>, DbError>>());
      final plans = switch (result) {
        Success(:final value) => value,
        Error() => throw StateError('Expected success'),
      };
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
      switch (result) {
        case Success(:final value):
          value.close();
        case Error():
          break;
      }
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
      switch (result) {
        case Success(:final value):
          value.close();
        case Error():
          break;
      }
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
      final result = createDb(config, logger: logger, retryPolicy: fastPolicy);
      final elapsed = DateTime.now().difference(start);
      expect(result, isA<Error<TooManyCooksDb, String>>());
      // Should be fast - no retries on path errors (not I/O errors)
      expect(elapsed.inMilliseconds, lessThan(1000));
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
        switch (result) {
          case Success(:final value):
            dbs.add(value);
          case Error():
            throw StateError('DB $i creation failed');
        }
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
  final fs = requireModule('fs');
  if (fs case final JSObject fsObj) {
    final readdirSync = fsObj['readdirSync'];
    final unlinkSync = fsObj['unlinkSync'];

    if ((readdirSync, unlinkSync) case (
      final JSFunction readdir,
      final JSFunction unlink,
    )) {
      final filesResult = readdir.callAsFunction(fsObj, '.'.toJS);
      if (filesResult case final JSArray files) {
        for (final file in files.toDart) {
          if (file case final JSString jsFileName) {
            final fileName = jsFileName.toDart;
            if (fileName.startsWith('.test_') && fileName.endsWith('.db') ||
                fileName.startsWith('.test_') && fileName.contains('.db-')) {
              unlink.callAsFunction(fsObj, fileName.toJS);
            }
          }
        }
      }

      // Also delete main db files
      final existsSync = fsObj['existsSync'];
      if (existsSync case final JSFunction exists) {
        for (final dbFile in [
          '.too_many_cooks.db',
          '.too_many_cooks.db-wal',
          '.too_many_cooks.db-shm',
        ]) {
          final existsResult = exists.callAsFunction(fsObj, dbFile.toJS);
          if (existsResult case final JSBoolean b when b.toDart) {
            unlink.callAsFunction(fsObj, dbFile.toJS);
          }
        }
      }
    }
  }
}

/// Delete a specific database file and its WAL/SHM files.
void _deleteDbFile(String path) {
  final fs = requireModule('fs');
  if (fs case final JSObject fsObj) {
    final unlinkSync = fsObj['unlinkSync'];
    final existsSync = fsObj['existsSync'];

    if ((unlinkSync, existsSync) case (
      final JSFunction unlink,
      final JSFunction exists,
    )) {
      for (final suffix in ['', '-wal', '-shm']) {
        final filePath = '$path$suffix';
        final existsResult = exists.callAsFunction(fsObj, filePath.toJS);
        if (existsResult case final JSBoolean b when b.toDart) {
          unlink.callAsFunction(fsObj, filePath.toJS);
        }
      }
    }
  }
}
