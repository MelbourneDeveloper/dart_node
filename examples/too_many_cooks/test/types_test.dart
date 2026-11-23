/// Tests for pure Dart types.
library;

import 'package:test/test.dart';
import 'package:too_many_cooks/src/config.dart';
import 'package:too_many_cooks/src/types.dart';

void main() {
  group('TooManyCooksConfig', () {
    test('defaultConfig has correct values', () {
      // dbPath is dynamic based on HOME env var, just check it ends correctly
      expect(defaultConfig.dbPath, endsWith('.too_many_cooks/data.db'));
      expect(defaultConfig.lockTimeoutMs, 600000);
      expect(defaultConfig.maxMessageLength, 200);
      expect(defaultConfig.maxPlanLength, 100);
    });

    test('custom config works', () {
      const config = (
        dbPath: 'custom.db',
        lockTimeoutMs: 1000,
        maxMessageLength: 500,
        maxPlanLength: 200,
      );
      expect(config.dbPath, 'custom.db');
      expect(config.lockTimeoutMs, 1000);
    });
  });

  group('Types', () {
    test('AgentIdentity can be created', () {
      const identity = (
        agentName: 'test-agent',
        registeredAt: 1234567890,
        lastActive: 1234567899,
      );
      expect(identity.agentName, 'test-agent');
      expect(identity.registeredAt, 1234567890);
      expect(identity.lastActive, 1234567899);
    });

    test('AgentRegistration can be created', () {
      const reg = (agentName: 'agent1', agentKey: 'secret-key-123');
      expect(reg.agentName, 'agent1');
      expect(reg.agentKey, 'secret-key-123');
    });

    test('FileLock can be created', () {
      const lock = (
        filePath: '/src/main.dart',
        agentName: 'agent1',
        acquiredAt: 1000,
        expiresAt: 2000,
        reason: 'editing',
        version: 1,
      );
      expect(lock.filePath, '/src/main.dart');
      expect(lock.agentName, 'agent1');
      expect(lock.reason, 'editing');
      expect(lock.version, 1);
    });

    test('FileLock reason can be null', () {
      const lock = (
        filePath: '/src/main.dart',
        agentName: 'agent1',
        acquiredAt: 1000,
        expiresAt: 2000,
        reason: null,
        version: 1,
      );
      expect(lock.reason, isNull);
    });

    test('LockResult acquired true', () {
      const result = (
        acquired: true,
        lock: (
          filePath: '/test.dart',
          agentName: 'agent1',
          acquiredAt: 1000,
          expiresAt: 2000,
          reason: null,
          version: 1,
        ),
        error: null,
      );
      expect(result.acquired, isTrue);
      expect(result.lock, isNotNull);
      expect(result.error, isNull);
    });

    test('LockResult acquired false with error', () {
      const result = (
        acquired: false,
        lock: null,
        error: 'Lock held by another agent',
      );
      expect(result.acquired, isFalse);
      expect(result.lock, isNull);
      expect(result.error, 'Lock held by another agent');
    });

    test('Message can be created', () {
      const msg = (
        id: 'msg-123',
        fromAgent: 'agent1',
        toAgent: 'agent2',
        content: 'Hello!',
        createdAt: 1000,
        readAt: null,
      );
      expect(msg.id, 'msg-123');
      expect(msg.fromAgent, 'agent1');
      expect(msg.toAgent, 'agent2');
      expect(msg.content, 'Hello!');
      expect(msg.readAt, isNull);
    });

    test('Message with readAt', () {
      const msg = (
        id: 'msg-123',
        fromAgent: 'agent1',
        toAgent: 'agent2',
        content: 'Hello!',
        createdAt: 1000,
        readAt: 2000,
      );
      expect(msg.readAt, 2000);
    });

    test('AgentPlan can be created', () {
      const plan = (
        agentName: 'agent1',
        goal: 'Fix all bugs',
        currentTask: 'Reviewing code',
        updatedAt: 1000,
      );
      expect(plan.agentName, 'agent1');
      expect(plan.goal, 'Fix all bugs');
      expect(plan.currentTask, 'Reviewing code');
    });

    test('DbError can be created', () {
      const error = (code: errNotFound, message: 'Agent not found');
      expect(error.code, 'NOT_FOUND');
      expect(error.message, 'Agent not found');
    });
  });

  group('Error codes', () {
    test('errNotFound is correct', () {
      expect(errNotFound, 'NOT_FOUND');
    });

    test('errUnauthorized is correct', () {
      expect(errUnauthorized, 'UNAUTHORIZED');
    });

    test('errLockHeld is correct', () {
      expect(errLockHeld, 'LOCK_HELD');
    });

    test('errLockExpired is correct', () {
      expect(errLockExpired, 'LOCK_EXPIRED');
    });

    test('errValidation is correct', () {
      expect(errValidation, 'VALIDATION');
    });

    test('errDatabase is correct', () {
      expect(errDatabase, 'DATABASE');
    });
  });

  group('textContent', () {
    test('creates text content map', () {
      final content = textContent('Hello world');
      expect(content['type'], 'text');
      expect(content['text'], 'Hello world');
    });

    test('handles empty string', () {
      final content = textContent('');
      expect(content['type'], 'text');
      expect(content['text'], '');
    });

    test('handles special characters', () {
      final content = textContent('{"json": "value"}');
      expect(content['text'], '{"json": "value"}');
    });
  });
}
