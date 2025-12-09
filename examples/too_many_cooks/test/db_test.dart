import 'dart:io';

import 'package:nadz/nadz.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks/src/config.dart';
import 'package:too_many_cooks/src/db/db.dart';
import 'package:too_many_cooks/src/types.dart';

void main() {
  late TooManyCooksDb db;
  late String testDbPath;

  setUp(() {
    testDbPath = '.test_${DateTime.now().millisecondsSinceEpoch}.db';
    final config = (
      dbPath: testDbPath,
      lockTimeoutMs: 1000,
      maxMessageLength: 200,
      maxPlanLength: 100,
    );
    final result = createDb(config);
    expect(result, isA<Success>());
    db = (result as Success<TooManyCooksDb, String>).value;
  });

  tearDown(() {
    db.close();
    try {
      File(testDbPath).deleteSync();
    } catch (_) {}
  });

  group('Identity', () {
    test('register creates agent with key', () {
      final result = db.register('agent1');
      expect(result, isA<Success>());
      final reg = (result as Success<AgentRegistration, DbError>).value;
      expect(reg.agentName, 'agent1');
      expect(reg.agentKey.length, 64);
    });

    test('register rejects duplicate names', () {
      db.register('agent1');
      final result = db.register('agent1');
      expect(result, isA<Error>());
      final err = (result as Error<AgentRegistration, DbError>).error;
      expect(err.code, errValidation);
    });

    test('register rejects empty name', () {
      final result = db.register('');
      expect(result, isA<Error>());
    });

    test('authenticate succeeds with valid credentials', () {
      final reg = (db.register('agent1') as Success).value as AgentRegistration;
      final result = db.authenticate(reg.agentName, reg.agentKey);
      expect(result, isA<Success>());
    });

    test('authenticate fails with wrong key', () {
      db.register('agent1');
      final result = db.authenticate('agent1', 'wrongkey');
      expect(result, isA<Error>());
      final err = (result as Error<AgentIdentity, DbError>).error;
      expect(err.code, errUnauthorized);
    });

    test('listAgents returns all agents', () {
      db.register('agent1');
      db.register('agent2');
      final result = db.listAgents();
      expect(result, isA<Success>());
      final agents = (result as Success<List<AgentIdentity>, DbError>).value;
      expect(agents.length, 2);
    });
  });

  group('Locks', () {
    late AgentRegistration agent1;
    late AgentRegistration agent2;

    setUp(() {
      agent1 = (db.register('agent1') as Success).value as AgentRegistration;
      agent2 = (db.register('agent2') as Success).value as AgentRegistration;
    });

    test('acquireLock succeeds on free file', () {
      final result = db.acquireLock(
        '/path/file.dart',
        agent1.agentName,
        agent1.agentKey,
        'editing',
        1000,
      );
      expect(result, isA<Success>());
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
      expect(result, isA<Success>());
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
      expect(result, isA<Success>());
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
      expect(result, isA<Error>());
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
      expect(result, isA<Error>());
      final err = (result as Error<void, DbError>).error;
      expect(err.code, errLockHeld);
    });

    test('queryLock returns null for unlocked file', () {
      final result = db.queryLock('/path/file.dart');
      expect(result, isA<Success>());
      final lock = (result as Success<FileLock?, DbError>).value;
      expect(lock, isNull);
    });

    test('listLocks returns all locks', () {
      db.acquireLock('/a.dart', agent1.agentName, agent1.agentKey, null, 1000);
      db.acquireLock('/b.dart', agent2.agentName, agent2.agentKey, null, 1000);
      final result = db.listLocks();
      expect(result, isA<Success>());
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
      final before = (db.queryLock('/path/file.dart') as Success).value
          as FileLock;
      db.renewLock('/path/file.dart', agent1.agentName, agent1.agentKey, 5000);
      final after = (db.queryLock('/path/file.dart') as Success).value
          as FileLock;
      expect(after.expiresAt, greaterThan(before.expiresAt));
    });
  });

  group('Messages', () {
    late AgentRegistration agent1;
    late AgentRegistration agent2;

    setUp(() {
      agent1 = (db.register('agent1') as Success).value as AgentRegistration;
      agent2 = (db.register('agent2') as Success).value as AgentRegistration;
    });

    test('sendMessage creates message', () {
      final result = db.sendMessage(
        agent1.agentName,
        agent1.agentKey,
        agent2.agentName,
        'Hello!',
      );
      expect(result, isA<Success>());
    });

    test('sendMessage rejects too long content', () {
      final longContent = 'x' * 300;
      final result = db.sendMessage(
        agent1.agentName,
        agent1.agentKey,
        agent2.agentName,
        longContent,
      );
      expect(result, isA<Error>());
    });

    test('getMessages returns messages for recipient', () {
      db.sendMessage(
        agent1.agentName,
        agent1.agentKey,
        agent2.agentName,
        'Hello!',
      );
      final result = db.getMessages(agent2.agentName, agent2.agentKey);
      expect(result, isA<Success>());
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
      agent1 = (db.register('agent1') as Success).value as AgentRegistration;
    });

    test('updatePlan creates plan', () {
      final result = db.updatePlan(
        agent1.agentName,
        agent1.agentKey,
        'Fix bugs',
        'Reviewing code',
      );
      expect(result, isA<Success>());
    });

    test('updatePlan rejects too long fields', () {
      final longText = 'x' * 200;
      final result = db.updatePlan(
        agent1.agentName,
        agent1.agentKey,
        longText,
        'task',
      );
      expect(result, isA<Error>());
    });

    test('getPlan returns agent plan', () {
      db.updatePlan(
        agent1.agentName,
        agent1.agentKey,
        'Fix bugs',
        'Reviewing',
      );
      final result = db.getPlan(agent1.agentName);
      expect(result, isA<Success>());
      final plan = (result as Success<AgentPlan?, DbError>).value;
      expect(plan?.goal, 'Fix bugs');
    });

    test('getPlan returns null for no plan', () {
      final result = db.getPlan('nonexistent');
      expect((result as Success).value, isNull);
    });

    test('listPlans returns all plans', () {
      db.updatePlan(agent1.agentName, agent1.agentKey, 'Goal', 'Task');
      final result = db.listPlans();
      expect(result, isA<Success>());
      final plans = (result as Success<List<AgentPlan>, DbError>).value;
      expect(plans.length, 1);
    });
  });
}
