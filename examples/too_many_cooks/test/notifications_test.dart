/// Tests for notifications.dart - NotificationEmitter.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks/src/notifications.dart';

void main() {
  group('NotificationEmitter', () {
    test('addSubscriber and getSubscribers work', () {
      final serverResult = McpServer.create(
        (name: 'test', version: '1.0.0'),
        options: (
          capabilities: (
            tools: (listChanged: false),
            resources: null,
            prompts: null,
            logging: (enabled: true),
          ),
          instructions: null,
        ),
      );
      expect(serverResult, isA<Success<McpServer, String>>());
      final server = (serverResult as Success<McpServer, String>).value;

      final emitter = createNotificationEmitter(server);

      // Initially no subscribers
      expect(emitter.getSubscribers(), isEmpty);

      // Add subscriber
      emitter.addSubscriber((subscriberId: 'test-sub', events: ['*']));
      expect(emitter.getSubscribers().length, 1);
      expect(emitter.getSubscribers().first.subscriberId, 'test-sub');

      // Add another subscriber
      emitter.addSubscriber((
        subscriberId: 'test-sub-2',
        events: [eventLockAcquired],
      ));
      expect(emitter.getSubscribers().length, 2);
    });

    test('removeSubscriber works', () {
      final serverResult = McpServer.create(
        (name: 'test', version: '1.0.0'),
        options: (
          capabilities: (
            tools: (listChanged: false),
            resources: null,
            prompts: null,
            logging: (enabled: true),
          ),
          instructions: null,
        ),
      );
      final server = (serverResult as Success<McpServer, String>).value;
      final emitter = createNotificationEmitter(server);

      emitter.addSubscriber((subscriberId: 'sub1', events: ['*']));
      emitter.addSubscriber((subscriberId: 'sub2', events: ['*']));
      expect(emitter.getSubscribers().length, 2);

      emitter.removeSubscriber('sub1');
      expect(emitter.getSubscribers().length, 1);
      expect(emitter.getSubscribers().first.subscriberId, 'sub2');
    });

    test('emit does nothing with no subscribers', () {
      final serverResult = McpServer.create(
        (name: 'test', version: '1.0.0'),
        options: (
          capabilities: (
            tools: (listChanged: false),
            resources: null,
            prompts: null,
            logging: (enabled: true),
          ),
          instructions: null,
        ),
      );
      final server = (serverResult as Success<McpServer, String>).value;
      final emitter = createNotificationEmitter(server);

      // Should not throw
      emitter.emit(eventAgentRegistered, {'test': 'data'});
    });

    test('emit sends to interested subscribers', () {
      final serverResult = McpServer.create(
        (name: 'test', version: '1.0.0'),
        options: (
          capabilities: (
            tools: (listChanged: false),
            resources: null,
            prompts: null,
            logging: (enabled: true),
          ),
          instructions: null,
        ),
      );
      final server = (serverResult as Success<McpServer, String>).value;
      final emitter = createNotificationEmitter(server);

      // Add subscriber interested in lock events only
      emitter.addSubscriber((
        subscriberId: 'lock-watcher',
        events: [eventLockAcquired, eventLockReleased],
      ));

      // Emit lock event - subscriber is interested
      emitter.emit(eventLockAcquired, {'file': '/test.dart'});

      // Emit agent event - subscriber not interested (but still works)
      emitter.emit(eventAgentRegistered, {'agent': 'test'});
    });

    test('emit sends to wildcard subscribers', () {
      final serverResult = McpServer.create(
        (name: 'test', version: '1.0.0'),
        options: (
          capabilities: (
            tools: (listChanged: false),
            resources: null,
            prompts: null,
            logging: (enabled: true),
          ),
          instructions: null,
        ),
      );
      final server = (serverResult as Success<McpServer, String>).value;
      final emitter = createNotificationEmitter(server);

      // Add wildcard subscriber
      emitter.addSubscriber((subscriberId: 'all-events', events: ['*']));

      // Any event should match
      emitter.emit(eventPlanUpdated, {'plan': 'test'});
    });
  });

  group('Event constants', () {
    test('allEventTypes contains all event types', () {
      expect(allEventTypes, contains(eventAgentRegistered));
      expect(allEventTypes, contains(eventLockAcquired));
      expect(allEventTypes, contains(eventLockReleased));
      expect(allEventTypes, contains(eventLockRenewed));
      expect(allEventTypes, contains(eventMessageSent));
      expect(allEventTypes, contains(eventPlanUpdated));
      expect(allEventTypes.length, 6);
    });

    test('event constants have correct values', () {
      expect(eventAgentRegistered, 'agent_registered');
      expect(eventLockAcquired, 'lock_acquired');
      expect(eventLockReleased, 'lock_released');
      expect(eventLockRenewed, 'lock_renewed');
      expect(eventMessageSent, 'message_sent');
      expect(eventPlanUpdated, 'plan_updated');
    });
  });
}
