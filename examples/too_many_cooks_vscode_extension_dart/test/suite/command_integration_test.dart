/// Command Integration Tests
/// Tests commands that require user confirmation flows.
/// These tests execute actual store methods to cover all code paths.
library;

import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('Command Integration - Lock Operations', () {
    late String agentKey;
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agentName = 'cmd-test-$testId';

    test('Setup: Connect and register agent', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        expect(agentKey, isNotEmpty);
        expect(manager.isConnected, isTrue);
      });
    });

    test('deleteLock removes lock from state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        const lockPath = '/cmd/delete/lock1.ts';

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': lockPath,
          'agent_name': agentName,
          'agent_key': agentKey,
          'reason': 'Testing delete command',
        });

        await manager.refreshStatus();
        expect(findLock(manager, lockPath), isNotNull);

        await manager.forceReleaseLock(lockPath);

        await manager.refreshStatus();
        expect(findLock(manager, lockPath), isNull);
      });
    });

    test('deleteLock handles nonexistent lock gracefully', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Should not throw for nonexistent lock
        await manager.forceReleaseLock('/nonexistent/path.ts');

        // State should remain valid
        expect(manager.isConnected, isTrue);
      });
    });
  });

  group('Command Integration - Agent Operations', () {
    final testId = DateTime.now().millisecondsSinceEpoch;

    test('deleteAgent removes agent from state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final targetName = 'delete-target-$testId';
        final result =
            await manager.callTool('register', {'name': targetName});
        final targetKey = extractAgentKey(result);

        // Create lock for agent
        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/cmd/agent/file.ts',
          'agent_name': targetName,
          'agent_key': targetKey,
          'reason': 'Will be deleted',
        });

        await manager.refreshStatus();
        expect(findAgent(manager, targetName), isNotNull);

        await manager.deleteAgent(targetName);

        await manager.refreshStatus();
        expect(findAgent(manager, targetName), isNull);
      });
    });

    test('deleteAgent handles nonexistent agent with error', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('admin', {
          'action': 'delete_agent',
          'agent_name': 'nonexistent-agent-xyz',
        });

        expect(result, contains('error'));
      });
    });
  });

  group('Command Integration - Message Operations', () {
    final testId = DateTime.now().millisecondsSinceEpoch;

    test('sendMessage with target agent creates message', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final recipientName = 'recipient-$testId';
        await manager.callTool('register', {'name': recipientName});

        final senderName = 'sender-with-target-$testId';
        await manager.sendMessage(
          senderName,
          recipientName,
          'Test message with target',
        );

        await manager.refreshStatus();

        final msg = findMessage(manager, 'Test message with target');
        expect(msg, isNotNull);
        expect(msg!.fromAgent, equals(senderName));
        expect(msg.toAgent, equals(recipientName));
      });
    });

    test('sendMessage broadcast to all agents', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final senderName = 'broadcast-sender-$testId';
        await manager.sendMessage(
          senderName,
          '*',
          'Broadcast test message',
        );

        await manager.refreshStatus();

        final msg = findMessage(manager, 'Broadcast test');
        expect(msg, isNotNull);
        expect(msg!.toAgent, equals('*'));
      });
    });
  });

  group('Command Integration - Combined Operations', () {
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agentName = 'combined-$testId';

    test('Full workflow: register, lock, plan, message, cleanup', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Register
        final result = await manager.callTool('register', {'name': agentName});
        final agentKey = extractAgentKey(result);

        await manager.refreshStatus();
        expect(findAgent(manager, agentName), isNotNull);

        // Lock
        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/combined/test.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
          'reason': 'Combined test',
        });

        await manager.refreshStatus();
        expect(findLock(manager, '/combined/test.ts'), isNotNull);

        // Plan
        await manager.callTool('plan', {
          'action': 'update',
          'agent_name': agentName,
          'agent_key': agentKey,
          'goal': 'Complete combined test',
          'current_task': 'Running workflow',
        });

        await manager.refreshStatus();
        expect(findPlan(manager, agentName), isNotNull);

        // Message
        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agentName,
          'agent_key': agentKey,
          'to_agent': '*',
          'content': 'Combined workflow message',
        });

        await manager.refreshStatus();
        expect(findMessage(manager, 'Combined workflow'), isNotNull);

        // Verify all state
        final details = selectAgentDetails(manager.state);
        final agentDetail =
            details.where((d) => d.agent.agentName == agentName).firstOrNull;

        expect(agentDetail, isNotNull);
        expect(agentDetail!.locks, isNotEmpty);
        expect(agentDetail.plan, isNotNull);
        expect(agentDetail.sentMessages, isNotEmpty);

        // Cleanup - release lock
        await manager.callTool('lock', {
          'action': 'release',
          'file_path': '/combined/test.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
        });

        await manager.refreshStatus();
        expect(findLock(manager, '/combined/test.ts'), isNull);

        // Cleanup - delete agent
        await manager.deleteAgent(agentName);

        await manager.refreshStatus();
        expect(findAgent(manager, agentName), isNull);
      });
    });

    test('Multiple agents with locks and messages', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Register multiple agents
        final agent1 = 'multi-agent-1-$testId';
        final agent2 = 'multi-agent-2-$testId';
        final agent3 = 'multi-agent-3-$testId';

        final result1 = await manager.callTool('register', {'name': agent1});
        final key1 = extractAgentKey(result1);

        final result2 = await manager.callTool('register', {'name': agent2});
        final key2 = extractAgentKey(result2);

        final result3 = await manager.callTool('register', {'name': agent3});
        final key3 = extractAgentKey(result3);

        // Each agent acquires locks
        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/multi/file1.ts',
          'agent_name': agent1,
          'agent_key': key1,
        });

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/multi/file2.ts',
          'agent_name': agent2,
          'agent_key': key2,
        });

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/multi/file3.ts',
          'agent_name': agent3,
          'agent_key': key3,
        });

        // Agents send messages to each other
        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agent1,
          'agent_key': key1,
          'to_agent': agent2,
          'content': 'From 1 to 2',
        });

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agent2,
          'agent_key': key2,
          'to_agent': agent3,
          'content': 'From 2 to 3',
        });

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agent3,
          'agent_key': key3,
          'to_agent': '*',
          'content': 'Broadcast from 3',
        });

        await manager.refreshStatus();

        // Verify state
        expect(manager.state.agents.length, greaterThanOrEqualTo(3));
        expect(manager.state.locks.length, equals(3));
        expect(manager.state.messages.length, equals(3));

        // Verify agent details
        final details = selectAgentDetails(manager.state);
        expect(details.length, greaterThanOrEqualTo(3));

        final agent1Details =
            details.where((d) => d.agent.agentName == agent1).first;
        expect(agent1Details.locks.length, equals(1));
        expect(agent1Details.sentMessages.length, equals(1));

        final agent3Details =
            details.where((d) => d.agent.agentName == agent3).first;
        expect(agent3Details.receivedMessages.length, greaterThanOrEqualTo(1));
      });
    });
  });

  group('Command Integration - State Consistency', () {
    test('State remains consistent after rapid operations', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final agentName = 'rapid-${DateTime.now().millisecondsSinceEpoch}';
        final result = await manager.callTool('register', {'name': agentName});
        final agentKey = extractAgentKey(result);

        // Rapid lock/unlock operations
        for (var i = 0; i < 5; i++) {
          await manager.callTool('lock', {
            'action': 'acquire',
            'file_path': '/rapid/file$i.ts',
            'agent_name': agentName,
            'agent_key': agentKey,
          });
        }

        await manager.refreshStatus();
        expect(manager.state.locks.length, equals(5));

        for (var i = 0; i < 3; i++) {
          await manager.callTool('lock', {
            'action': 'release',
            'file_path': '/rapid/file$i.ts',
            'agent_name': agentName,
            'agent_key': agentKey,
          });
        }

        await manager.refreshStatus();
        expect(manager.state.locks.length, equals(2));

        // Verify remaining locks are correct
        expect(findLock(manager, '/rapid/file3.ts'), isNotNull);
        expect(findLock(manager, '/rapid/file4.ts'), isNotNull);
        expect(findLock(manager, '/rapid/file0.ts'), isNull);
      });
    });

    test('Disconnect clears all state completely', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Build up some state
        final agentName = 'cleanup-${DateTime.now().millisecondsSinceEpoch}';
        final result = await manager.callTool('register', {'name': agentName});
        final agentKey = extractAgentKey(result);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/cleanup/test.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
        });

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agentName,
          'agent_key': agentKey,
          'to_agent': '*',
          'content': 'Cleanup test',
        });

        await manager.refreshStatus();
        expect(manager.state.agents, isNotEmpty);
        expect(manager.state.locks, isNotEmpty);
        expect(manager.state.messages, isNotEmpty);

        // Disconnect
        await manager.disconnect();

        // All state should be cleared
        expect(
          manager.state.connectionStatus,
          equals(ConnectionStatus.disconnected),
        );
        expect(manager.state.agents, isEmpty);
        expect(manager.state.locks, isEmpty);
        expect(manager.state.messages, isEmpty);
        expect(manager.state.plans, isEmpty);
      });
    });

    test('Reconnect restores ability to manage state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();
        await manager.disconnect();
        await manager.connect();

        final agentName = 'reconnect-${DateTime.now().millisecondsSinceEpoch}';
        final result = await manager.callTool('register', {'name': agentName});
        final agentKey = extractAgentKey(result);

        expect(agentKey, isNotEmpty);

        await manager.refreshStatus();
        expect(findAgent(manager, agentName), isNotNull);
      });
    });
  });
}
