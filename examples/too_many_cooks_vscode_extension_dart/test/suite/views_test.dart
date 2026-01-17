/// View Tests
/// Verifies state views are accessible and UI bugs are fixed.
library;

import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('Views', () {
    test('Agents list is accessible from state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        expect(manager.state.agents, isA<List<AgentIdentity>>());
      });
    });

    test('Locks list is accessible from state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        expect(manager.state.locks, isA<List<FileLock>>());
      });
    });

    test('Messages list is accessible from state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        expect(manager.state.messages, isA<List<Message>>());
      });
    });

    test('Plans list is accessible from state', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        expect(manager.state.plans, isA<List<AgentPlan>>());
      });
    });
  });

  group('UI Bug Fixes', () {
    test('Messages are properly stored with all fields', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Register an agent and send a message
        final regResult = await manager.callTool('register', {
          'name': 'ui-test-agent',
        });
        final agentKey = extractAgentKey(regResult);

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': 'ui-test-agent',
          'agent_key': agentKey,
          'to_agent': '*',
          'content': 'Test message for UI verification',
        });

        await manager.refreshStatus();

        final msg = findMessage(manager, 'Test message');
        expect(msg, isNotNull);
        expect(msg!.content, contains('Test message'));
        expect(msg.fromAgent, equals('ui-test-agent'));
        expect(msg.toAgent, equals('*'));
      });
    });

    test('Broadcast messages to * are stored correctly', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        final regResult = await manager.callTool('register', {
          'name': 'broadcast-sender',
        });
        final agentKey = extractAgentKey(regResult);

        await manager.callTool('message', {
          'action': 'send',
          'agent_name': 'broadcast-sender',
          'agent_key': agentKey,
          'to_agent': '*',
          'content': 'Broadcast test message',
        });

        await manager.refreshStatus();

        final msg = findMessage(manager, 'Broadcast test');
        expect(msg, isNotNull);
        expect(msg!.toAgent, equals('*'));
      });
    });

    test('Auto-mark-read works when agent fetches messages', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Register sender
        final senderResult = await manager.callTool('register', {
          'name': 'sender-agent',
        });
        final senderKey = extractAgentKey(senderResult);

        // Register receiver
        final receiverResult = await manager.callTool('register', {
          'name': 'receiver-agent',
        });
        final receiverKey = extractAgentKey(receiverResult);

        // Send message
        await manager.callTool('message', {
          'action': 'send',
          'agent_name': 'sender-agent',
          'agent_key': senderKey,
          'to_agent': 'receiver-agent',
          'content': 'This should be auto-marked read',
        });

        // Receiver fetches their messages (triggers auto-mark-read)
        final fetchResult = await manager.callTool('message', {
          'action': 'get',
          'agent_name': 'receiver-agent',
          'agent_key': receiverKey,
          'unread_only': true,
        });

        final fetched = parseJson(fetchResult);
        expect(fetched['messages'], isNotNull);
        final messages = switch (fetched['messages']) {
          final List<Object?> list => list,
          _ => <Object?>[],
        };
        expect(messages, isNotEmpty);

        // Fetch again - should be empty (already marked read)
        final fetchResult2 = await manager.callTool('message', {
          'action': 'get',
          'agent_name': 'receiver-agent',
          'agent_key': receiverKey,
          'unread_only': true,
        });

        final fetched2 = parseJson(fetchResult2);
        final messageList = switch (fetched2['messages']) {
          final List<Object?> list => list,
          _ => <Object?>[],
        };
        final messages2 = messageList
            .where((m) => switch (m) {
                  final Map<String, Object?> map => switch (map['content']) {
                        final String content => content.contains('auto-marked'),
                        _ => false,
                      },
                  _ => false,
                })
            .toList();
        expect(messages2, isEmpty);
      });
    });

    test('Unread messages are counted correctly', () async {
      await withTestStore((manager, client) async {
        await manager.connect();

        // Register and send messages
        final regResult = await manager.callTool('register', {
          'name': 'count-agent',
        });
        final agentKey = extractAgentKey(regResult);

        for (var i = 0; i < 3; i++) {
          await manager.callTool('message', {
            'action': 'send',
            'agent_name': 'count-agent',
            'agent_key': agentKey,
            'to_agent': 'other-agent',
            'content': 'Message $i',
          });
        }

        await manager.refreshStatus();

        final totalCount = selectMessageCount(manager.state);
        final unreadCount = selectUnreadMessageCount(manager.state);

        expect(totalCount, greaterThanOrEqualTo(3));
        expect(unreadCount, lessThanOrEqualTo(totalCount));
      });
    });
  });
}
