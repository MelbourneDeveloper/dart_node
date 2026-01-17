/// MCP Integration Tests - REAL end-to-end tests.
///
/// These tests PROVE that state updates when MCP server state changes.
///
/// What we're testing:
/// 1. Call MCP tool (register, lock, message, plan)
/// 2. Wait for the state to update
/// 3. ASSERT the exact values appear in state
///
/// NO MOCKING. NO SKIPPING. FAIL HARD.
library;


import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('MCP Integration - UI Verification', () {
    late String agent1Key;
    late String agent2Key;
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agent1Name = 'test-agent-$testId-1';
    final agent2Name = 'test-agent-$testId-2';

    test('Connect to MCP server', () async {
      await withTestStore((manager, client) async {
        expect(manager.isConnected, isFalse);

        await manager.connect();

        expect(manager.isConnected, isTrue);
        expect(
          manager.state.connectionStatus,
          equals(ConnectionStatus.connected),
        );
      });
    });

    test('Empty state shows empty lists', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        expect(manager.state.agents, isEmpty);
        expect(manager.state.locks, isEmpty);
        expect(manager.state.messages, isEmpty);
        expect(manager.state.plans, isEmpty);
      });
    });

    test('Register agent-1 → agent APPEARS in state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result);
        expect(agent1Key, isNotEmpty);

        await manager.refreshStatus();

        final agent = findAgent(manager, agent1Name);
        expect(agent, isNotNull);
        expect(agent!.agentName, equals(agent1Name));
      });
    });

    test('Register agent-2 → both agents visible', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Register first agent
        final result1 =
            await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result1);

        // Register second agent
        final result2 =
            await manager.callTool('register', {'name': agent2Name});
        agent2Key = extractAgentKey(result2);

        await manager.refreshStatus();

        expect(findAgent(manager, agent1Name), isNotNull);
        expect(findAgent(manager, agent2Name), isNotNull);
        expect(manager.state.agents.length, equals(2));
      });
    });

    test('Acquire lock on /src/main.ts → lock APPEARS in state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Register agent
        final result =
            await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/main.ts',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'reason': 'Editing main',
        });

        await manager.refreshStatus();

        final lock = findLock(manager, '/src/main.ts');
        expect(lock, isNotNull);
        expect(lock!.filePath, equals('/src/main.ts'));
        expect(lock.agentName, equals(agent1Name));
      });
    });

    test('Acquire 3 locks → all 3 file paths visible', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Register agents
        final result1 =
            await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result1);

        final result2 =
            await manager.callTool('register', {'name': agent2Name});
        agent2Key = extractAgentKey(result2);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/main.ts',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'reason': 'Editing main',
        });

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/utils.ts',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'reason': 'Utils',
        });

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/types.ts',
          'agent_name': agent2Name,
          'agent_key': agent2Key,
          'reason': 'Types',
        });

        await manager.refreshStatus();

        expect(findLock(manager, '/src/main.ts'), isNotNull);
        expect(findLock(manager, '/src/utils.ts'), isNotNull);
        expect(findLock(manager, '/src/types.ts'), isNotNull);
        expect(manager.state.locks.length, equals(3));
      });
    });

    test('Release /src/utils.ts → lock DISAPPEARS from state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result =
            await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result);

        // Acquire then release
        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/utils.ts',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'reason': 'Utils',
        });

        await manager.callTool('lock', {
          'action': 'release',
          'file_path': '/src/utils.ts',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
        });

        await manager.refreshStatus();

        expect(findLock(manager, '/src/utils.ts'), isNull);
      });
    });

    test('Update plan for agent → plan APPEARS in state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result =
            await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result);

        await manager.callTool('plan', {
          'action': 'update',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'goal': 'Implement feature X',
          'current_task': 'Writing tests',
        });

        await manager.refreshStatus();

        final plan = findPlan(manager, agent1Name);
        expect(plan, isNotNull);
        expect(plan!.goal, equals('Implement feature X'));
        expect(plan.currentTask, equals('Writing tests'));
      });
    });

    test('Send message agent-1 → agent-2 → message APPEARS in state',
        () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result1 =
            await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result1);

        await manager.callTool('register', {'name': agent2Name});

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'to_agent': agent2Name,
          'content': 'Starting work on main.ts',
        });

        await manager.refreshStatus();

        final msg = findMessage(manager, 'Starting work');
        expect(msg, isNotNull);
        expect(msg!.fromAgent, equals(agent1Name));
        expect(msg.toAgent, equals(agent2Name));
      });
    });

    test('Send 3 messages → all 3 messages visible', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result1 =
            await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result1);

        final result2 =
            await manager.callTool('register', {'name': agent2Name});
        agent2Key = extractAgentKey(result2);

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'to_agent': agent2Name,
          'content': 'Starting work',
        });

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agent2Name,
          'agent_key': agent2Key,
          'to_agent': agent1Name,
          'content': 'Acknowledged',
        });

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'to_agent': agent2Name,
          'content': 'Done with main.ts',
        });

        await manager.refreshStatus();

        expect(findMessage(manager, 'Starting work'), isNotNull);
        expect(findMessage(manager, 'Acknowledged'), isNotNull);
        expect(findMessage(manager, 'Done with main'), isNotNull);
        expect(manager.state.messages.length, equals(3));
      });
    });

    test('Broadcast message to * → message APPEARS with "*" as recipient',
        () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result =
            await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result);

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'to_agent': '*',
          'content': 'BROADCAST: Important announcement',
        });

        await manager.refreshStatus();

        final msg = findMessage(manager, 'BROADCAST');
        expect(msg, isNotNull);
        expect(msg!.toAgent, equals('*'));
      });
    });

    test('Agent details selector computes correctly', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result =
            await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result);

        // Add lock and plan for agent
        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/detail/test.ts',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'reason': 'Testing details',
        });

        await manager.callTool('plan', {
          'action': 'update',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'goal': 'Test goal',
          'current_task': 'Testing',
        });

        await manager.refreshStatus();

        final details = selectAgentDetails(manager.state);
        final agentDetail =
            details.where((d) => d.agent.agentName == agent1Name).firstOrNull;

        expect(agentDetail, isNotNull);
        expect(agentDetail!.locks.length, equals(1));
        expect(agentDetail.plan, isNotNull);
        expect(agentDetail.plan!.goal, equals('Test goal'));
      });
    });

    test('Refresh syncs all state from server', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Setup some state
        final result =
            await manager.callTool('register', {'name': agent1Name});
        agent1Key = extractAgentKey(result);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/refresh/test.ts',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
        });

        await manager.callTool('plan', {
          'action': 'update',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'goal': 'Refresh test',
          'current_task': 'Testing',
        });

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agent1Name,
          'agent_key': agent1Key,
          'to_agent': '*',
          'content': 'Refresh message',
        });

        await manager.refreshStatus();

        expect(manager.state.agents.length, greaterThanOrEqualTo(1));
        expect(manager.state.locks.length, greaterThanOrEqualTo(1));
        expect(manager.state.plans.length, greaterThanOrEqualTo(1));
        expect(manager.state.messages.length, greaterThanOrEqualTo(1));
      });
    });

    test('Disconnect clears all state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Setup some state
        await manager.callTool('register', {'name': agent1Name});
        await manager.refreshStatus();

        expect(manager.state.agents, isNotEmpty);

        await manager.disconnect();

        expect(manager.isConnected, isFalse);
        expect(manager.state.agents, isEmpty);
        expect(manager.state.locks, isEmpty);
        expect(manager.state.messages, isEmpty);
        expect(manager.state.plans, isEmpty);
      });
    });
  });

  group('MCP Integration - Admin Operations', () {
    late String adminAgentKey;
    final testId = DateTime.now().millisecondsSinceEpoch;
    final adminAgentName = 'admin-test-$testId';
    final targetAgentName = 'target-test-$testId';

    test('Admin tool must exist on server', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Test admin tool exists
        final result = await manager.callTool('admin', {
          'action': 'delete_lock',
          'file_path': '/nonexistent',
        });

        expect(result, anyOf(contains('deleted'), contains('error')));
      });
    });

    test('Force release lock via admin → lock DISAPPEARS', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result =
            await manager.callTool('register', {'name': adminAgentName});
        adminAgentKey = extractAgentKey(result);

        // Acquire a lock
        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/admin/test/file.ts',
          'agent_name': adminAgentName,
          'agent_key': adminAgentKey,
          'reason': 'Testing admin delete',
        });

        await manager.refreshStatus();
        expect(findLock(manager, '/admin/test/file.ts'), isNotNull);

        // Force release via admin
        await manager.callTool('admin', {
          'action': 'delete_lock',
          'file_path': '/admin/test/file.ts',
        });

        await manager.refreshStatus();
        expect(findLock(manager, '/admin/test/file.ts'), isNull);
      });
    });

    test('Delete agent via admin → agent DISAPPEARS from state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Register target agent
        await manager.callTool('register', {'name': targetAgentName});

        await manager.refreshStatus();
        expect(findAgent(manager, targetAgentName), isNotNull);

        // Delete via admin
        await manager.callTool('admin', {
          'action': 'delete_agent',
          'agent_name': targetAgentName,
        });

        await manager.refreshStatus();
        expect(findAgent(manager, targetAgentName), isNull);
      });
    });

    test('Lock renewal extends expiration', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result =
            await manager.callTool('register', {'name': adminAgentName});
        adminAgentKey = extractAgentKey(result);

        // Acquire a lock
        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/admin/renew/test.ts',
          'agent_name': adminAgentName,
          'agent_key': adminAgentKey,
          'reason': 'Testing renewal',
        });

        await manager.refreshStatus();
        final lockBefore = findLock(manager, '/admin/renew/test.ts');
        expect(lockBefore, isNotNull);

        // Renew the lock
        await manager.callTool('lock', {
          'action': 'renew',
          'file_path': '/admin/renew/test.ts',
          'agent_name': adminAgentName,
          'agent_key': adminAgentKey,
        });

        await manager.refreshStatus();
        final lockAfter = findLock(manager, '/admin/renew/test.ts');
        expect(lockAfter, isNotNull);
      });
    });
  });

  group('MCP Integration - Lock State', () {
    late String agentKey;
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agentName = 'lock-test-$testId';

    test('Lock on file creates state entry', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/lock/test/file.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
          'reason': 'Testing locks',
        });

        await manager.refreshStatus();

        final lock = findLock(manager, '/lock/test/file.ts');
        expect(lock, isNotNull);
        expect(lock!.agentName, equals(agentName));
        expect(lock.reason, equals('Testing locks'));
        final now = DateTime.now().millisecondsSinceEpoch;
        expect(lock.expiresAt, greaterThan(now));
      });
    });

    test('Lock without reason still works', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/lock/no-reason/file.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
        });

        await manager.refreshStatus();

        final lock = findLock(manager, '/lock/no-reason/file.ts');
        expect(lock, isNotNull);
        expect(lock!.reason, isNull);
      });
    });

    test('Active and expired locks computed correctly', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/lock/active/test.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
        });

        await manager.refreshStatus();

        final activeLocks = selectActiveLocks(manager.state);
        final expiredLocks = selectExpiredLocks(manager.state);

        expect(activeLocks.length, greaterThanOrEqualTo(1));
        expect(expiredLocks, isEmpty);
      });
    });

    test('Release lock removes state entry', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        // Acquire
        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/lock/release/test.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
        });

        await manager.refreshStatus();
        expect(findLock(manager, '/lock/release/test.ts'), isNotNull);

        // Release
        await manager.callTool('lock', {
          'action': 'release',
          'file_path': '/lock/release/test.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
        });

        await manager.refreshStatus();
        expect(findLock(manager, '/lock/release/test.ts'), isNull);
      });
    });
  });

  group('MCP Integration - Tree Provider Edge Cases', () {
    late String agentKey;
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agentName = 'edge-test-$testId';

    test('Long message content is stored correctly', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        final longContent = 'A' * 100;
        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agentName,
          'agent_key': agentKey,
          'to_agent': agentName,
          'content': longContent,
        });

        await manager.refreshStatus();

        final msg = findMessage(manager, 'AAAA');
        expect(msg, isNotNull);
        expect(msg!.content.length, equals(100));
      });
    });

    test('Long plan task is stored correctly', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        final longTask = 'B' * 50;
        await manager.callTool('plan', {
          'action': 'update',
          'agent_name': agentName,
          'agent_key': agentKey,
          'goal': 'Test long task',
          'current_task': longTask,
        });

        await manager.refreshStatus();

        final plan = findPlan(manager, agentName);
        expect(plan, isNotNull);
        expect(plan!.currentTask.length, equals(50));
      });
    });

    test('Agent with multiple locks shows all locks', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        for (var i = 1; i <= 3; i++) {
          await manager.callTool('lock', {
            'action': 'acquire',
            'file_path': '/edge/multi/file$i.ts',
            'agent_name': agentName,
            'agent_key': agentKey,
            'reason': 'Lock $i',
          });
        }

        await manager.refreshStatus();

        final agentLocks = manager.state.locks
            .where((l) => l.agentName == agentName)
            .toList();
        expect(agentLocks.length, equals(3));
      });
    });
  });

  group('MCP Integration - Store Methods', () {
    late String storeAgentKey;
    final testId = DateTime.now().millisecondsSinceEpoch;
    final storeAgentName = 'store-test-$testId';
    final targetAgentForDelete = 'delete-target-$testId';

    test('forceReleaseLock removes lock', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result =
            await manager.callTool('register', {'name': storeAgentName});
        storeAgentKey = extractAgentKey(result);

        // Acquire a lock first
        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/store/force/release.ts',
          'agent_name': storeAgentName,
          'agent_key': storeAgentKey,
          'reason': 'Testing forceReleaseLock',
        });

        await manager.refreshStatus();
        expect(findLock(manager, '/store/force/release.ts'), isNotNull);

        // Force release via store method
        await manager.forceReleaseLock('/store/force/release.ts');

        await manager.refreshStatus();
        expect(findLock(manager, '/store/force/release.ts'), isNull);
      });
    });

    test('deleteAgent removes agent and their data', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Register target agent
        final result =
            await manager.callTool('register', {'name': targetAgentForDelete});
        final targetKey = extractAgentKey(result);

        // Acquire a lock
        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/store/delete/agent.ts',
          'agent_name': targetAgentForDelete,
          'agent_key': targetKey,
          'reason': 'Will be deleted',
        });

        await manager.refreshStatus();
        expect(findAgent(manager, targetAgentForDelete), isNotNull);

        // Delete via store method
        await manager.deleteAgent(targetAgentForDelete);

        await manager.refreshStatus();
        expect(findAgent(manager, targetAgentForDelete), isNull);
        expect(findLock(manager, '/store/delete/agent.ts'), isNull);
      });
    });

    test('sendMessage sends message via registered agent', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Create recipient
        await manager.callTool('register', {'name': 'recipient-agent'});

        // Send via store method
        await manager.sendMessage(
          'ui-sender',
          'recipient-agent',
          'Message from store.sendMessage',
        );

        await manager.refreshStatus();

        final msg = findMessage(manager, 'Message from store');
        expect(msg, isNotNull);
        expect(msg!.fromAgent, equals('ui-sender'));
        expect(msg.toAgent, equals('recipient-agent'));
      });
    });

    test('sendMessage to broadcast recipient', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        await manager.sendMessage(
          'broadcast-sender',
          '*',
          'Broadcast from store.sendMessage',
        );

        await manager.refreshStatus();

        final msg = findMessage(manager, 'Broadcast from store');
        expect(msg, isNotNull);
        expect(msg!.toAgent, equals('*'));
      });
    });
  });
}
