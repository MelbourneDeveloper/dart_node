/// Coverage Tests
/// Tests specifically designed to cover untested code paths.
library;

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Lock State Coverage', () {
    late String agentKey;
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agentName = 'lock-cov-test-$testId';

    test('Active lock appears in state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/test/lock/active.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
          'reason': 'Testing active lock',
        });

        await manager.refreshStatus();

        final lock = findLock(manager, '/test/lock/active.ts');
        expect(lock, isNotNull);
        expect(lock!.agentName, equals(agentName));
        expect(lock.reason, equals('Testing active lock'));
        expect(
          lock.expiresAt,
          greaterThan(DateTime.now().millisecondsSinceEpoch),
        );
      });
    });

    test('Lock shows agent name correctly', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/test/lock/description.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
          'reason': 'Testing lock description',
        });

        await manager.refreshStatus();

        final lock = findLock(manager, '/test/lock/description.ts');
        expect(lock, isNotNull);
        expect(lock!.agentName, equals(agentName));
      });
    });
  });

  group('Store Error Handling Coverage', () {
    late String agentKey;
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agentName = 'store-err-test-$testId';

    test('forceReleaseLock works on existing lock', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/test/force/release.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
          'reason': 'Will be force released',
        });

        await manager.refreshStatus();
        expect(findLock(manager, '/test/force/release.ts'), isNotNull);

        await manager.forceReleaseLock('/test/force/release.ts');

        await manager.refreshStatus();
        expect(findLock(manager, '/test/force/release.ts'), isNull);
      });
    });

    test('deleteAgent removes agent and associated data', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final deleteAgentName = 'to-delete-$testId';
        final regResult =
            await manager.callTool('register', {'name': deleteAgentName});
        final deleteAgentKey = extractAgentKey(regResult);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/test/delete/agent.ts',
          'agent_name': deleteAgentName,
          'agent_key': deleteAgentKey,
          'reason': 'Will be deleted with agent',
        });

        await manager.callTool('plan', {
          'action': 'update',
          'agent_name': deleteAgentName,
          'agent_key': deleteAgentKey,
          'goal': 'Will be deleted',
          'current_task': 'Waiting to be deleted',
        });

        await manager.refreshStatus();
        expect(findAgent(manager, deleteAgentName), isNotNull);

        await manager.deleteAgent(deleteAgentName);

        await manager.refreshStatus();
        expect(findAgent(manager, deleteAgentName), isNull);
        expect(findLock(manager, '/test/delete/agent.ts'), isNull);
      });
    });

    test('sendMessage creates message in state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final receiverName = 'receiver-$testId';
        await manager.callTool('register', {'name': receiverName});

        final senderName = 'store-sender-$testId';
        await manager.sendMessage(
          senderName,
          receiverName,
          'Test message via store.sendMessage',
        );

        await manager.refreshStatus();

        final msg = findMessage(manager, 'Test message via store');
        expect(msg, isNotNull);
        expect(msg!.fromAgent, equals(senderName));
        expect(msg.toAgent, equals(receiverName));
      });
    });
  });

  group('Extension Commands Coverage', () {
    test('refresh works when connected', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        await manager.refreshStatus();

        expect(manager.isConnected, isTrue);
      });
    });

    test('connect succeeds with valid client', () async {
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
  });

  group('Tree Provider Edge Cases', () {
    late String agentKey;
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agentName = 'edge-case-$testId';

    test('Messages are handled correctly after being read', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        final receiverName = 'edge-receiver-$testId';
        final regResult =
            await manager.callTool('register', {'name': receiverName});
        final receiverKey = extractAgentKey(regResult);

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': agentName,
          'agent_key': agentKey,
          'to_agent': receiverName,
          'content': 'Edge case message',
        });

        await manager.refreshStatus();
        final msgBefore = findMessage(manager, 'Edge case');
        expect(msgBefore, isNotNull);

        // Fetch to mark as read
        await manager.callTool('message', {
          'action': 'get',
          'agent_name': receiverName,
          'agent_key': receiverKey,
        });

        await manager.refreshStatus();

        final msgAfter = findMessage(manager, 'Edge case');
        expect(msgAfter, isNotNull);
      });
    });

    test('Agent details show locks correctly', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/edge/case/file.ts',
          'agent_name': agentName,
          'agent_key': agentKey,
          'reason': 'Edge case lock',
        });

        await manager.refreshStatus();

        final details = selectAgentDetails(manager.state);
        final agentDetail =
            details.where((d) => d.agent.agentName == agentName).firstOrNull;

        expect(agentDetail, isNotNull);
        expect(agentDetail!.locks, isNotEmpty);
      });
    });

    test('Plans appear correctly for agents', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('register', {'name': agentName});
        agentKey = extractAgentKey(result);

        await manager.callTool('plan', {
          'action': 'update',
          'agent_name': agentName,
          'agent_key': agentKey,
          'goal': 'Edge case goal',
          'current_task': 'Testing edge cases',
        });

        await manager.refreshStatus();

        final details = selectAgentDetails(manager.state);
        final agentDetail =
            details.where((d) => d.agent.agentName == agentName).firstOrNull;

        expect(agentDetail, isNotNull);
        expect(agentDetail!.plan, isNotNull);
        expect(agentDetail.plan!.goal, equals('Edge case goal'));
      });
    });
  });

  group('Error Handling Coverage', () {
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agentName = 'error-test-$testId';

    test('Tool call with invalid agent key returns error', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        await manager.callTool('register', {'name': agentName});

        final result = await manager.callTool('lock', {
          'action': 'acquire',
          'file_path': '/error/test/file.ts',
          'agent_name': agentName,
          'agent_key': 'invalid-key-that-should-fail',
          'reason': 'Testing error path',
        });

        expect(result, contains('error'));
      });
    });

    test('Invalid tool arguments trigger error response', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final result = await manager.callTool('lock', {
          'action': 'acquire',
          // Missing required args
        });

        expect(result, contains('error'));
      });
    });

    test('Disconnect while connected covers stop path', () async {
      await withTestStore((manager, client) async {
        await manager.connect();
        expect(manager.isConnected, isTrue);

        await manager.disconnect();

        expect(manager.isConnected, isFalse);
      });
    });

    test('Refresh after disconnect recovers', () async {
      await withTestStore((manager, client) async {
        await manager.connect();
        await manager.disconnect();
        await manager.connect();

        await manager.refreshStatus();

        expect(manager.isConnected, isTrue);
      });
    });
  });

  group('Reducer Coverage', () {
    test('SetConnectionStatus action works', () {
      var state = initialState;

      state = appReducer(
        state,
        SetConnectionStatus(ConnectionStatus.connecting),
      );
      expect(state.connectionStatus, equals(ConnectionStatus.connecting));

      state = appReducer(
        state,
        SetConnectionStatus(ConnectionStatus.connected),
      );
      expect(state.connectionStatus, equals(ConnectionStatus.connected));
    });

    test('SetAgents action works', () {
      var state = initialState;

      final agents = [
        (
          agentName: 'agent1',
          registeredAt: 1000,
          lastActive: 1000,
        ),
      ];

      state = appReducer(state, SetAgents(agents));
      expect(state.agents.length, equals(1));
      expect(state.agents.first.agentName, equals('agent1'));
    });

    test('AddAgent action works', () {
      var state = initialState;

      const agent = (
        agentName: 'new-agent',
        registeredAt: 1000,
        lastActive: 1000,
      );

      state = appReducer(state, AddAgent(agent));
      expect(state.agents.length, equals(1));
      expect(state.agents.first.agentName, equals('new-agent'));
    });

    test('RemoveAgent action works', () {
      final agents = [
        (agentName: 'agent1', registeredAt: 1000, lastActive: 1000),
        (agentName: 'agent2', registeredAt: 1000, lastActive: 1000),
      ];

      var state = (
        connectionStatus: ConnectionStatus.connected,
        agents: agents,
        locks: <FileLock>[],
        messages: <Message>[],
        plans: <AgentPlan>[],
      );

      state = appReducer(state, RemoveAgent('agent1'));
      expect(state.agents.length, equals(1));
      expect(state.agents.first.agentName, equals('agent2'));
    });

    test('UpsertLock action works', () {
      var state = initialState;

      const lock = (
        filePath: '/test.ts',
        agentName: 'agent1',
        acquiredAt: 1000,
        expiresAt: 2000,
        reason: 'test',
        version: 1,
      );

      state = appReducer(state, UpsertLock(lock));
      expect(state.locks.length, equals(1));
      expect(state.locks.first.filePath, equals('/test.ts'));

      // Upsert should update, not add duplicate
      const updatedLock = (
        filePath: '/test.ts',
        agentName: 'agent1',
        acquiredAt: 1000,
        expiresAt: 3000,
        reason: 'updated',
        version: 2,
      );

      state = appReducer(state, UpsertLock(updatedLock));
      expect(state.locks.length, equals(1));
      expect(state.locks.first.expiresAt, equals(3000));
    });

    test('RemoveLock action works', () {
      final locks = <FileLock>[
        (
          filePath: '/a.ts',
          agentName: 'agent1',
          acquiredAt: 1000,
          expiresAt: 2000,
          reason: null,
          version: 1,
        ),
        (
          filePath: '/b.ts',
          agentName: 'agent1',
          acquiredAt: 1000,
          expiresAt: 2000,
          reason: null,
          version: 1,
        ),
      ];

      final state = appReducer(
        (
          connectionStatus: ConnectionStatus.connected,
          agents: <AgentIdentity>[],
          locks: locks,
          messages: <Message>[],
          plans: <AgentPlan>[],
        ),
        RemoveLock('/a.ts'),
      );
      expect(state.locks.length, equals(1));
      expect(state.locks.first.filePath, equals('/b.ts'));
    });

    test('RenewLock action works', () {
      final locks = <FileLock>[
        (
          filePath: '/test.ts',
          agentName: 'agent1',
          acquiredAt: 1000,
          expiresAt: 2000,
          reason: 'test',
          version: 1,
        ),
      ];

      final state = appReducer(
        (
          connectionStatus: ConnectionStatus.connected,
          agents: <AgentIdentity>[],
          locks: locks,
          messages: <Message>[],
          plans: <AgentPlan>[],
        ),
        RenewLock('/test.ts', 5000),
      );
      expect(state.locks.first.expiresAt, equals(5000));
    });

    test('AddMessage action works', () {
      var state = initialState;

      const message = (
        id: 'msg1',
        fromAgent: 'sender',
        toAgent: 'receiver',
        content: 'Hello',
        createdAt: 1000,
        readAt: null,
      );

      state = appReducer(state, AddMessage(message));
      expect(state.messages.length, equals(1));
      expect(state.messages.first.content, equals('Hello'));
    });

    test('UpsertPlan action works', () {
      var state = initialState;

      const plan = (
        agentName: 'agent1',
        goal: 'Goal 1',
        currentTask: 'Task 1',
        updatedAt: 1000,
      );

      state = appReducer(state, UpsertPlan(plan));
      expect(state.plans.length, equals(1));

      // Update same agent's plan
      const updatedPlan = (
        agentName: 'agent1',
        goal: 'Goal 2',
        currentTask: 'Task 2',
        updatedAt: 2000,
      );

      state = appReducer(state, UpsertPlan(updatedPlan));
      expect(state.plans.length, equals(1));
      expect(state.plans.first.goal, equals('Goal 2'));
    });

    test('ResetState action works', () {
      final state = (
        connectionStatus: ConnectionStatus.connected,
        agents: [
          (agentName: 'agent1', registeredAt: 1000, lastActive: 1000),
        ],
        locks: <FileLock>[],
        messages: <Message>[],
        plans: <AgentPlan>[],
      );

      final resetState = appReducer(state, ResetState());
      expect(
        resetState.connectionStatus,
        equals(ConnectionStatus.disconnected),
      );
      expect(resetState.agents, isEmpty);
    });
  });
}
