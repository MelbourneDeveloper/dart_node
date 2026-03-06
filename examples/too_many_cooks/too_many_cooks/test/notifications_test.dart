/// Tests for notifications.dart - NotificationEmitter.
library;

import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks/src/notifications.dart';

NotificationEmitter _createEmitter() {
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
  return createNotificationEmitter(server);
}

void main() {
  group('NotificationEmitter', () {
    test('emit does nothing without throwing', () {
      final emitter = _createEmitter();
      // Should not throw
      emitter.emit(eventAgentRegistered, {'test': 'data'});
    });

    test('emit with various event types does not throw', () {
      final emitter = _createEmitter();
      emitter.emit(eventLockAcquired, {'file': '/test.dart'});
      emitter.emit(eventAgentActivated, {'agent_name': 'test'});
      emitter.emit(eventAgentDeactivated, {'agent_name': 'test'});
      emitter.emit(eventPlanUpdated, {'plan': 'test'});
    });
  });

  group('Event constants', () {
    test('event constants have correct values', () {
      expect(eventAgentRegistered, 'agent_registered');
      expect(eventAgentActivated, 'agent_activated');
      expect(eventAgentDeactivated, 'agent_deactivated');
      expect(eventLockAcquired, 'lock_acquired');
      expect(eventLockReleased, 'lock_released');
      expect(eventLockRenewed, 'lock_renewed');
      expect(eventMessageSent, 'message_sent');
      expect(eventPlanUpdated, 'plan_updated');
    });
  });
}
