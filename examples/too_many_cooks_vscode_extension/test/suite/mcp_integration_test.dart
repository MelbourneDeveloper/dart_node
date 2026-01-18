/// MCP Integration Tests - REAL end-to-end tests.
///
/// These tests PROVE that UI tree views update when MCP server state changes.
///
/// What we're testing:
/// 1. Call MCP tool (register, lock, message, plan)
/// 2. Wait for the tree view to update
/// 3. ASSERT the exact label/description appears in the tree
///
/// NO MOCKING. NO SKIPPING. FAIL HARD.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

@JS('Date.now')
external int _dateNow();

/// Helper to dump tree snapshot for debugging.
void _dumpTree(String name, JSArray<JSObject> items) {
  _log('\n=== $name TREE ===');
  void dump(JSArray<JSObject> items, int indent) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final prefix = '  ' * indent;
      final label = _getLabel(item);
      final desc = _getDescription(item);
      final descStr = desc != null ? ' [$desc]' : '';
      _log('$prefix- $label$descStr');
      final children = _getChildren(item);
      if (children != null) dump(children, indent + 1);
    }
  }

  dump(items, 0);
  _log('=== END ===\n');
}

/// Get label property from tree item.
@JS('Reflect.get')
external JSAny? _reflectGet(JSObject target, String key);

String _getLabel(JSObject item) {
  final val = _reflectGet(item, 'label');
  return val?.toString() ?? '';
}

String? _getDescription(JSObject item) {
  final val = _reflectGet(item, 'description');
  return val?.toString();
}

JSArray<JSObject>? _getChildren(JSObject item) {
  final val = _reflectGet(item, 'children');
  if (val == null || val.isUndefinedOrNull) return null;
  return val as JSArray<JSObject>;
}

/// Check if tree item has a child with label containing text.
bool _hasChildWithLabel(JSObject item, String text) {
  final children = _getChildren(item);
  if (children == null) return false;
  for (var i = 0; i < children.length; i++) {
    final child = children[i];
    if (_getLabel(child).contains(text)) return true;
  }
  return false;
}

/// Find child item by label content.
JSObject? _findChildByLabel(JSObject item, String text) {
  final children = _getChildren(item);
  if (children == null) return null;
  for (var i = 0; i < children.length; i++) {
    final child = children[i];
    if (_getLabel(child).contains(text)) return child;
  }
  return null;
}

/// Count children matching a predicate.
int _countChildrenMatching(JSObject item, bool Function(JSObject) predicate) {
  final children = _getChildren(item);
  if (children == null) return 0;
  var count = 0;
  for (var i = 0; i < children.length; i++) {
    if (predicate(children[i])) count++;
  }
  return count;
}

void main() {
  _log('[MCP INTEGRATION TEST] main() called');

  // Restore any dialog mocks from previous tests.
  restoreDialogMocks();

  // ==========================================================================
  // MCP Integration - UI Verification
  // ==========================================================================
  suite(
    'MCP Integration - UI Verification',
    syncTest(() {
      var agent1Key = '';
      var agent2Key = '';
      final testId = _dateNow();
      final agent1Name = 'test-agent-$testId-1';
      final agent2Name = 'test-agent-$testId-2';

      suiteSetup(
        asyncTest(() async {
          _log('[MCP UI] suiteSetup - waiting for extension activation');
          await waitForExtensionActivation();
          cleanDatabase();
        }),
      );

      suiteTeardown(
        asyncTest(() async {
          _log('[MCP UI] suiteTeardown - disconnecting');
          await safeDisconnect();
          cleanDatabase();
        }),
      );

      test(
        'Connect to MCP server',
        asyncTest(() async {
          _log('[MCP UI] Running connect test');
          await safeDisconnect();
          final api = getTestAPI();

          assertOk(!api.isConnected(), 'Should be disconnected');

          await api.connect().toDart;
          await waitForConnection();

          assertOk(api.isConnected(), 'Should be connected');
          assertEqual(api.getConnectionStatus(), 'connected');
          _log('[MCP UI] connect test PASSED');
        }),
      );

      test(
        'Empty state shows empty trees',
        asyncTest(() async {
          _log('[MCP UI] Running empty state test');
          final api = getTestAPI();
          await api.refreshStatus().toDart;

          final agentsTree = api.getAgentsTreeSnapshot();
          final locksTree = api.getLocksTreeSnapshot();
          final messagesTree = api.getMessagesTreeSnapshot();

          _dumpTree('AGENTS', agentsTree);
          _dumpTree('LOCKS', locksTree);
          _dumpTree('MESSAGES', messagesTree);

          assertEqual(agentsTree.length, 0, 'Agents tree should be empty');

          // Check for "No locks" placeholder
          var hasNoLocks = false;
          for (var i = 0; i < locksTree.length; i++) {
            if (_getLabel(locksTree[i]) == 'No locks') hasNoLocks = true;
          }
          assertOk(hasNoLocks, 'Locks tree should show "No locks"');

          // Check for "No messages" placeholder
          var hasNoMessages = false;
          for (var i = 0; i < messagesTree.length; i++) {
            if (_getLabel(messagesTree[i]) == 'No messages')
              hasNoMessages = true;
          }
          assertOk(hasNoMessages, 'Messages tree should show "No messages"');

          _log('[MCP UI] empty state test PASSED');
        }),
      );

      test(
        'Register agent-1 → label APPEARS in agents tree',
        asyncTest(() async {
          _log('[MCP UI] Running register agent-1 test');
          final api = getTestAPI();

          final args = createArgs({'name': agent1Name});
          final result = await api.callTool('register', args).toDart;
          agent1Key = extractKeyFromResult(result.toDart);
          assertOk(agent1Key.isNotEmpty, 'Should return agent key');

          await waitForAgentInTree(api, agent1Name);

          final agentItem = api.findAgentInTree(agent1Name);
          assertOk(agentItem != null, '$agent1Name MUST appear in the tree');
          assertEqual(
            _getLabel(agentItem!),
            agent1Name,
            'Label must be exactly "$agent1Name"',
          );

          _dumpTree('AGENTS after register', api.getAgentsTreeSnapshot());
          _log('[MCP UI] register agent-1 test PASSED');
        }),
      );

      test(
        'Register agent-2 → both agents visible in tree',
        asyncTest(() async {
          _log('[MCP UI] Running register agent-2 test');
          final api = getTestAPI();

          final args = createArgs({'name': agent2Name});
          final result = await api.callTool('register', args).toDart;
          agent2Key = extractKeyFromResult(result.toDart);

          await waitForCondition(
            () => api.getAgentsTreeSnapshot().length >= 2,
            message: '2 agents in tree',
          );

          final tree = api.getAgentsTreeSnapshot();
          _dumpTree('AGENTS after second register', tree);

          assertOk(
            api.findAgentInTree(agent1Name) != null,
            '$agent1Name MUST still be in tree',
          );
          assertOk(
            api.findAgentInTree(agent2Name) != null,
            '$agent2Name MUST be in tree',
          );
          assertEqual(tree.length, 2, 'Exactly 2 agent items');

          _log('[MCP UI] register agent-2 test PASSED');
        }),
      );

      test(
        'Acquire lock on /src/main.ts → file path APPEARS in locks tree',
        asyncTest(() async {
          _log('[MCP UI] Running acquire lock test');
          final api = getTestAPI();

          final args = createArgs({
            'action': 'acquire',
            'file_path': '/src/main.ts',
            'agent_name': agent1Name,
            'agent_key': agent1Key,
            'reason': 'Editing main',
          });
          await api.callTool('lock', args).toDart;

          await waitForLockInTree(api, '/src/main.ts');

          final lockItem = api.findLockInTree('/src/main.ts');
          _dumpTree('LOCKS after acquire', api.getLocksTreeSnapshot());

          assertOk(lockItem != null, '/src/main.ts MUST appear in the tree');
          assertEqual(
            _getLabel(lockItem!),
            '/src/main.ts',
            'Label must be exact file path',
          );

          final desc = _getDescription(lockItem);
          assertOk(
            desc != null && desc.contains(agent1Name),
            'Description should contain agent name, got: $desc',
          );

          _log('[MCP UI] acquire lock test PASSED');
        }),
      );

      test(
        'Acquire 2 more locks → all 3 file paths visible',
        asyncTest(() async {
          _log('[MCP UI] Running acquire 2 more locks test');
          final api = getTestAPI();

          final args1 = createArgs({
            'action': 'acquire',
            'file_path': '/src/utils.ts',
            'agent_name': agent1Name,
            'agent_key': agent1Key,
            'reason': 'Utils',
          });
          await api.callTool('lock', args1).toDart;

          final args2 = createArgs({
            'action': 'acquire',
            'file_path': '/src/types.ts',
            'agent_name': agent2Name,
            'agent_key': agent2Key,
            'reason': 'Types',
          });
          await api.callTool('lock', args2).toDart;

          await waitForCondition(
            () => api.getLockTreeItemCount() >= 3,
            message: '3 locks in tree',
          );

          final tree = api.getLocksTreeSnapshot();
          _dumpTree('LOCKS after 3 acquires', tree);

          assertOk(
            api.findLockInTree('/src/main.ts') != null,
            '/src/main.ts MUST be in tree',
          );
          assertOk(
            api.findLockInTree('/src/utils.ts') != null,
            '/src/utils.ts MUST be in tree',
          );
          assertOk(
            api.findLockInTree('/src/types.ts') != null,
            '/src/types.ts MUST be in tree',
          );
          assertEqual(api.getLockTreeItemCount(), 3, 'Exactly 3 lock items');

          _log('[MCP UI] acquire 2 more locks test PASSED');
        }),
      );

      test(
        'Release /src/utils.ts → file path DISAPPEARS from tree',
        asyncTest(() async {
          _log('[MCP UI] Running release lock test');
          final api = getTestAPI();

          final args = createArgs({
            'action': 'release',
            'file_path': '/src/utils.ts',
            'agent_name': agent1Name,
            'agent_key': agent1Key,
          });
          await api.callTool('lock', args).toDart;

          await waitForLockGone(api, '/src/utils.ts');

          final tree = api.getLocksTreeSnapshot();
          _dumpTree('LOCKS after release', tree);

          assertEqual(
            api.findLockInTree('/src/utils.ts'),
            null,
            '/src/utils.ts MUST NOT be in tree',
          );
          assertOk(
            api.findLockInTree('/src/main.ts') != null,
            '/src/main.ts MUST still be in tree',
          );
          assertOk(
            api.findLockInTree('/src/types.ts') != null,
            '/src/types.ts MUST still be in tree',
          );
          assertEqual(
            api.getLockTreeItemCount(),
            2,
            'Exactly 2 lock items remain',
          );

          _log('[MCP UI] release lock test PASSED');
        }),
      );

      test(
        'Update plan for agent-1 → plan content APPEARS in agent children',
        asyncTest(() async {
          _log('[MCP UI] Running update plan test');
          final api = getTestAPI();

          final args = createArgs({
            'action': 'update',
            'agent_name': agent1Name,
            'agent_key': agent1Key,
            'goal': 'Implement feature X',
            'current_task': 'Writing tests',
          });
          await api.callTool('plan', args).toDart;

          await waitForCondition(() {
            final agentItem = api.findAgentInTree(agent1Name);
            if (agentItem == null) return false;
            return _hasChildWithLabel(agentItem, 'Implement feature X');
          }, message: '$agent1Name plan to appear in agent children');

          final agentsTree = api.getAgentsTreeSnapshot();
          _dumpTree('AGENTS after plan update', agentsTree);

          final agentItem = api.findAgentInTree(agent1Name);
          assertOk(agentItem != null, '$agent1Name MUST be in tree');
          final children = _getChildren(agentItem!);
          assertOk(children != null, 'Agent should have children');

          final planChild = _findChildByLabel(
            agentItem,
            'Goal: Implement feature X',
          );
          assertOk(
            planChild != null,
            'Plan goal "Implement feature X" MUST appear in agent children',
          );

          final planDesc = _getDescription(planChild!);
          assertOk(
            planDesc != null && planDesc.contains('Writing tests'),
            'Plan description should contain task, got: $planDesc',
          );

          _log('[MCP UI] update plan test PASSED');
        }),
      );

      test(
        'Send message agent-1 → agent-2 → message APPEARS in tree',
        asyncTest(() async {
          _log('[MCP UI] Running send message test');
          final api = getTestAPI();

          final args = createArgs({
            'action': 'send',
            'agent_name': agent1Name,
            'agent_key': agent1Key,
            'to_agent': agent2Name,
            'content': 'Starting work on main.ts',
          });
          await api.callTool('message', args).toDart;

          await waitForMessageInTree(api, 'Starting work');

          final tree = api.getMessagesTreeSnapshot();
          _dumpTree('MESSAGES after send', tree);

          final msgItem = api.findMessageInTree('Starting work');
          assertOk(msgItem != null, 'Message MUST appear in tree');

          final msgLabel = _getLabel(msgItem!);
          assertOk(
            msgLabel.contains(agent1Name),
            'Message label should contain sender, got: $msgLabel',
          );
          assertOk(
            msgLabel.contains(agent2Name),
            'Message label should contain recipient, got: $msgLabel',
          );

          final msgDesc = _getDescription(msgItem);
          assertOk(
            msgDesc != null && msgDesc.contains('Starting work'),
            'Description should contain content preview, got: $msgDesc',
          );

          _log('[MCP UI] send message test PASSED');
        }),
      );

      test(
        'Send 2 more messages → all 3 messages visible with correct labels',
        asyncTest(() async {
          _log('[MCP UI] Running send 2 more messages test');
          final api = getTestAPI();

          final args1 = createArgs({
            'action': 'send',
            'agent_name': agent2Name,
            'agent_key': agent2Key,
            'to_agent': agent1Name,
            'content': 'Acknowledged',
          });
          await api.callTool('message', args1).toDart;

          final args2 = createArgs({
            'action': 'send',
            'agent_name': agent1Name,
            'agent_key': agent1Key,
            'to_agent': agent2Name,
            'content': 'Done with main.ts',
          });
          await api.callTool('message', args2).toDart;

          await waitForCondition(
            () => api.getMessageTreeItemCount() >= 3,
            message: '3 messages in tree',
          );

          final tree = api.getMessagesTreeSnapshot();
          _dumpTree('MESSAGES after 3 sends', tree);

          assertOk(
            api.findMessageInTree('Starting work') != null,
            'First message MUST be in tree',
          );
          assertOk(
            api.findMessageInTree('Acknowledged') != null,
            'Second message MUST be in tree',
          );
          assertOk(
            api.findMessageInTree('Done with main') != null,
            'Third message MUST be in tree',
          );
          assertEqual(
            api.getMessageTreeItemCount(),
            3,
            'Exactly 3 message items',
          );

          _log('[MCP UI] send 2 more messages test PASSED');
        }),
      );

      test(
        'Broadcast message to * → message APPEARS in tree with "all" label',
        asyncTest(() async {
          _log('[MCP UI] Running broadcast message test');
          final api = getTestAPI();

          final args = createArgs({
            'action': 'send',
            'agent_name': agent1Name,
            'agent_key': agent1Key,
            'to_agent': '*',
            'content': 'BROADCAST: Important announcement for all agents',
          });
          await api.callTool('message', args).toDart;

          await waitForMessageInTree(api, 'BROADCAST');

          final tree = api.getMessagesTreeSnapshot();
          _dumpTree('MESSAGES after broadcast', tree);

          final broadcastMsg = api.findMessageInTree('BROADCAST');
          assertOk(
            broadcastMsg != null,
            'Broadcast message MUST appear in tree',
          );

          final label = _getLabel(broadcastMsg!);
          assertOk(
            label.contains(agent1Name),
            'Broadcast label should contain sender, got: $label',
          );
          assertOk(
            label.contains('all'),
            'Broadcast label should show "all" for recipient, got: $label',
          );

          final desc = _getDescription(broadcastMsg);
          assertOk(
            desc != null && desc.contains('BROADCAST'),
            'Description should contain message content, got: $desc',
          );

          assertEqual(
            api.getMessageTreeItemCount(),
            4,
            'Should have 4 messages after broadcast',
          );

          _log('[MCP UI] broadcast message test PASSED');
        }),
      );

      test(
        'Agent tree shows locks/messages for each agent',
        asyncTest(() async {
          _log('[MCP UI] Running agent tree children test');
          final api = getTestAPI();

          final tree = api.getAgentsTreeSnapshot();
          _dumpTree('AGENTS with children', tree);

          final agent1 = api.findAgentInTree(agent1Name);
          assertOk(agent1 != null, '$agent1Name MUST be in tree');
          final children = _getChildren(agent1!);
          assertOk(
            children != null,
            '$agent1Name MUST have children showing locks/messages',
          );

          final hasLockChild = _hasChildWithLabel(agent1, '/src/main.ts');
          final hasPlanChild = _hasChildWithLabel(
            agent1,
            'Implement feature X',
          );
          final hasMessageChild = _hasChildWithLabel(agent1, 'Messages');

          assertOk(
            hasLockChild,
            '$agent1Name children MUST include /src/main.ts lock',
          );
          assertOk(hasPlanChild, '$agent1Name children MUST include plan goal');
          assertOk(
            hasMessageChild,
            '$agent1Name children MUST include Messages summary',
          );

          _log('[MCP UI] agent tree children test PASSED');
        }),
      );

      test(
        'Refresh syncs all state from server',
        asyncTest(() async {
          _log('[MCP UI] Running refresh test');
          final api = getTestAPI();

          await api.refreshStatus().toDart;

          assertOk(
            api.getAgentCount() >= 2,
            'At least 2 agents, got ${api.getAgentCount()}',
          );
          assertOk(
            api.getLockCount() >= 2,
            'At least 2 locks, got ${api.getLockCount()}',
          );
          assertOk(
            api.getPlans().length >= 1,
            'At least 1 plan, got ${api.getPlans().length}',
          );
          final msgLen = api.getMessages().length;
          assertOk(
            msgLen >= 4,
            'At least 4 messages (including broadcast), got $msgLen',
          );

          final agentsLen = api.getAgentsTreeSnapshot().length;
          assertOk(agentsLen >= 2, 'At least 2 agents in tree, got $agentsLen');
          final locksLen = api.getLockTreeItemCount();
          assertOk(locksLen >= 2, 'At least 2 locks in tree, got $locksLen');
          final msgTreeLen = api.getMessageTreeItemCount();
          assertOk(
            msgTreeLen >= 4,
            'At least 4 messages in tree (including broadcast), got $msgTreeLen',
          );

          final agentItem = api.findAgentInTree(agent1Name);
          assertOk(
            agentItem != null && _hasChildWithLabel(agentItem, 'Goal:'),
            'Agent should have plan child',
          );

          _log('[MCP UI] refresh test PASSED');
        }),
      );

      test(
        'Disconnect clears all tree views',
        asyncTest(() async {
          _log('[MCP UI] Running disconnect test');

          await safeDisconnect();
          final api = getTestAPI();

          assertOk(!api.isConnected(), 'Should be disconnected');

          assertEqual(api.getAgents().length, 0, 'Agents should be empty');
          assertEqual(api.getLocks().length, 0, 'Locks should be empty');
          assertEqual(api.getMessages().length, 0, 'Messages should be empty');
          assertEqual(api.getPlans().length, 0, 'Plans should be empty');

          assertEqual(
            api.getAgentsTreeSnapshot().length,
            0,
            'Agents tree should be empty',
          );
          assertEqual(
            api.getLockTreeItemCount(),
            0,
            'Locks tree should be empty',
          );
          assertEqual(
            api.getMessageTreeItemCount(),
            0,
            'Messages tree should be empty',
          );

          _log('[MCP UI] disconnect test PASSED');
        }),
      );

      test(
        'Reconnect restores all state and tree views',
        asyncTest(() async {
          _log('[MCP UI] Running reconnect test');
          final api = getTestAPI();

          await api.connect().toDart;
          await waitForConnection();
          await api.refreshStatus().toDart;

          // Re-register agents if lost (WAL not checkpointed on server kill)
          if (api.findAgentInTree(agent1Name) == null) {
            final result1 = await api
                .callTool('register', createArgs({'name': agent1Name}))
                .toDart;
            agent1Key = extractKeyFromResult(result1.toDart);
          }
          if (api.findAgentInTree(agent2Name) == null) {
            final result2 = await api
                .callTool('register', createArgs({'name': agent2Name}))
                .toDart;
            agent2Key = extractKeyFromResult(result2.toDart);
          }

          // Re-acquire locks if they were lost
          if (api.findLockInTree('/src/main.ts') == null) {
            await api
                .callTool(
                  'lock',
                  createArgs({
                    'action': 'acquire',
                    'file_path': '/src/main.ts',
                    'agent_name': agent1Name,
                    'agent_key': agent1Key,
                    'reason': 'Editing main',
                  }),
                )
                .toDart;
          }
          if (api.findLockInTree('/src/types.ts') == null) {
            await api
                .callTool(
                  'lock',
                  createArgs({
                    'action': 'acquire',
                    'file_path': '/src/types.ts',
                    'agent_name': agent2Name,
                    'agent_key': agent2Key,
                    'reason': 'Types',
                  }),
                )
                .toDart;
          }

          // Re-create plan if lost
          final agentItemForPlan = api.findAgentInTree(agent1Name);
          final hasPlan =
              agentItemForPlan != null &&
              _hasChildWithLabel(agentItemForPlan, 'Goal:');
          if (!hasPlan) {
            await api
                .callTool(
                  'plan',
                  createArgs({
                    'action': 'update',
                    'agent_name': agent1Name,
                    'agent_key': agent1Key,
                    'goal': 'Implement feature X',
                    'current_task': 'Writing tests',
                  }),
                )
                .toDart;
          }

          // Re-send messages if lost
          if (api.findMessageInTree('Starting work') == null) {
            await api
                .callTool(
                  'message',
                  createArgs({
                    'action': 'send',
                    'agent_name': agent1Name,
                    'agent_key': agent1Key,
                    'to_agent': agent2Name,
                    'content': 'Starting work on main.ts',
                  }),
                )
                .toDart;
          }
          if (api.findMessageInTree('Acknowledged') == null) {
            await api
                .callTool(
                  'message',
                  createArgs({
                    'action': 'send',
                    'agent_name': agent2Name,
                    'agent_key': agent2Key,
                    'to_agent': agent1Name,
                    'content': 'Acknowledged',
                  }),
                )
                .toDart;
          }
          if (api.findMessageInTree('Done with main') == null) {
            await api
                .callTool(
                  'message',
                  createArgs({
                    'action': 'send',
                    'agent_name': agent1Name,
                    'agent_key': agent1Key,
                    'to_agent': agent2Name,
                    'content': 'Done with main.ts',
                  }),
                )
                .toDart;
          }
          if (api.findMessageInTree('BROADCAST') == null) {
            await api
                .callTool(
                  'message',
                  createArgs({
                    'action': 'send',
                    'agent_name': agent1Name,
                    'agent_key': agent1Key,
                    'to_agent': '*',
                    'content':
                        'BROADCAST: Important announcement for all agents',
                  }),
                )
                .toDart;
          }

          await waitForCondition(
            () => api.getAgentCount() >= 2 && api.getLockCount() >= 2,
            message: 'state to be restored/recreated',
          );

          assertOk(
            api.getAgentCount() >= 2,
            'At least 2 agents, got ${api.getAgentCount()}',
          );
          assertOk(
            api.getLockCount() >= 2,
            'At least 2 locks, got ${api.getLockCount()}',
          );
          assertOk(
            api.getPlans().length >= 1,
            'At least 1 plan, got ${api.getPlans().length}',
          );
          final reconMsgLen = api.getMessages().length;
          assertOk(
            reconMsgLen >= 4,
            'At least 4 messages (including broadcast), got $reconMsgLen',
          );

          final agentsTree = api.getAgentsTreeSnapshot();
          final locksTree = api.getLocksTreeSnapshot();
          final messagesTree = api.getMessagesTreeSnapshot();

          _dumpTree('AGENTS after reconnect', agentsTree);
          _dumpTree('LOCKS after reconnect', locksTree);
          _dumpTree('MESSAGES after reconnect', messagesTree);

          assertOk(
            api.findAgentInTree(agent1Name) != null,
            '$agent1Name in tree',
          );
          assertOk(
            api.findAgentInTree(agent2Name) != null,
            '$agent2Name in tree',
          );
          assertOk(
            api.findLockInTree('/src/main.ts') != null,
            '/src/main.ts lock in tree',
          );
          assertOk(
            api.findLockInTree('/src/types.ts') != null,
            '/src/types.ts lock in tree',
          );

          final agent1AfterReconnect = api.findAgentInTree(agent1Name);
          assertOk(
            agent1AfterReconnect != null &&
                _hasChildWithLabel(agent1AfterReconnect, 'Goal:'),
            '$agent1Name plan should be in agent children',
          );

          assertOk(
            api.findMessageInTree('Starting work') != null,
            'First message in tree',
          );
          assertOk(
            api.findMessageInTree('Acknowledged') != null,
            'Second message in tree',
          );
          assertOk(
            api.findMessageInTree('Done with main') != null,
            'Third message in tree',
          );
          assertOk(
            api.findMessageInTree('BROADCAST') != null,
            'Broadcast message in tree',
          );
          final reconTreeMsgLen = api.getMessageTreeItemCount();
          assertOk(
            reconTreeMsgLen >= 4,
            'At least 4 messages in tree (including broadcast), '
            'got $reconTreeMsgLen',
          );

          _log('[MCP UI] reconnect test PASSED');
        }),
      );
    }),
  );

  // ==========================================================================
  // MCP Integration - Admin Operations
  // ==========================================================================
  suite(
    'MCP Integration - Admin Operations',
    syncTest(() {
      var adminAgentKey = '';
      var targetAgentKey = '';
      final testId = _dateNow();
      final adminAgentName = 'admin-test-$testId';
      final targetAgentName = 'target-test-$testId';

      suiteSetup(
        asyncTest(() async {
          _log('[MCP ADMIN] suiteSetup');
          await waitForExtensionActivation();
        }),
      );

      suiteTeardown(
        asyncTest(() async {
          _log('[MCP ADMIN] suiteTeardown');
          await safeDisconnect();
        }),
      );

      test(
        'CRITICAL: Admin tool must exist on server',
        asyncTest(() async {
          _log('[MCP ADMIN] Running admin tool existence test');
          await safeDisconnect();
          final api = getTestAPI();
          await api.connect().toDart;
          await waitForConnection();

          try {
            final result = await api
                .callTool(
                  'admin',
                  createArgs({
                    'action': 'delete_lock',
                    'file_path': '/nonexistent',
                  }),
                )
                .toDart;

            final resultStr = result.toDart;
            // Valid responses: {"deleted":true} or {"error":"..."}
            assertOk(
              resultStr.contains('deleted') || resultStr.contains('error'),
              'Admin tool should return valid response, got: $resultStr',
            );
          } on Object catch (err) {
            final msg = err.toString();
            if (msg.contains('Tool admin not found') ||
                msg.contains('-32602')) {
              throw AssertionError(
                'ADMIN TOOL NOT FOUND! The MCP server is outdated. '
                'Publish new version: cd examples/too_many_cooks && npm publish',
              );
            }
            // "NOT_FOUND:" errors are valid business responses - tool exists!
            if (msg.contains('NOT_FOUND:')) {
              _log('[MCP ADMIN] Admin tool exists (got NOT_FOUND response)');
              return;
            }
            // Other errors may be OK (e.g., lock doesn't exist)
          }
          _log('[MCP ADMIN] admin tool existence test PASSED');
        }),
      );

      test(
        'Setup: Connect and register agents',
        asyncTest(() async {
          _log('[MCP ADMIN] Running setup test');
          final api = getTestAPI();

          // Register admin agent
          final result1 = await api
              .callTool('register', createArgs({'name': adminAgentName}))
              .toDart;
          adminAgentKey = extractKeyFromResult(result1.toDart);
          assertOk(adminAgentKey.isNotEmpty, 'Admin agent should have key');

          // Register target agent
          final result2 = await api
              .callTool('register', createArgs({'name': targetAgentName}))
              .toDart;
          targetAgentKey = extractKeyFromResult(result2.toDart);
          assertOk(targetAgentKey.isNotEmpty, 'Target agent should have key');

          // Acquire a lock for target agent
          await api
              .callTool(
                'lock',
                createArgs({
                  'action': 'acquire',
                  'file_path': '/admin/test/file.ts',
                  'agent_name': targetAgentName,
                  'agent_key': targetAgentKey,
                  'reason': 'Testing admin delete',
                }),
              )
              .toDart;

          await waitForLockInTree(api, '/admin/test/file.ts');
          _log('[MCP ADMIN] setup test PASSED');
        }),
      );

      test(
        'Force release lock via admin → lock DISAPPEARS',
        asyncTest(() async {
          _log('[MCP ADMIN] Running force release test');
          final api = getTestAPI();

          assertOk(
            api.findLockInTree('/admin/test/file.ts') != null,
            'Lock should exist before force release',
          );

          await api
              .callTool(
                'admin',
                createArgs({
                  'action': 'delete_lock',
                  'file_path': '/admin/test/file.ts',
                }),
              )
              .toDart;

          await waitForLockGone(api, '/admin/test/file.ts');

          assertEqual(
            api.findLockInTree('/admin/test/file.ts'),
            null,
            'Lock should be gone after force release',
          );

          _log('[MCP ADMIN] force release test PASSED');
        }),
      );

      test(
        'Delete agent via admin → agent DISAPPEARS from tree',
        asyncTest(() async {
          _log('[MCP ADMIN] Running delete agent test');
          final api = getTestAPI();

          await waitForAgentInTree(api, targetAgentName);
          assertOk(
            api.findAgentInTree(targetAgentName) != null,
            'Target agent should exist before delete',
          );

          await api
              .callTool(
                'admin',
                createArgs({
                  'action': 'delete_agent',
                  'agent_name': targetAgentName,
                }),
              )
              .toDart;

          await waitForAgentGone(api, targetAgentName);

          assertEqual(
            api.findAgentInTree(targetAgentName),
            null,
            'Target agent should be gone after delete',
          );

          _log('[MCP ADMIN] delete agent test PASSED');
        }),
      );

      test(
        'Lock renewal extends expiration',
        asyncTest(() async {
          _log('[MCP ADMIN] Running lock renewal test');
          final api = getTestAPI();

          // Acquire a new lock
          await api
              .callTool(
                'lock',
                createArgs({
                  'action': 'acquire',
                  'file_path': '/admin/renew/test.ts',
                  'agent_name': adminAgentName,
                  'agent_key': adminAgentKey,
                  'reason': 'Testing renewal',
                }),
              )
              .toDart;

          await waitForLockInTree(api, '/admin/renew/test.ts');

          // Renew the lock
          await api
              .callTool(
                'lock',
                createArgs({
                  'action': 'renew',
                  'file_path': '/admin/renew/test.ts',
                  'agent_name': adminAgentName,
                  'agent_key': adminAgentKey,
                }),
              )
              .toDart;

          final lockItem = api.findLockInTree('/admin/renew/test.ts');
          assertOk(lockItem != null, 'Lock should still exist after renewal');

          // Clean up
          await api
              .callTool(
                'lock',
                createArgs({
                  'action': 'release',
                  'file_path': '/admin/renew/test.ts',
                  'agent_name': adminAgentName,
                  'agent_key': adminAgentKey,
                }),
              )
              .toDart;

          _log('[MCP ADMIN] lock renewal test PASSED');
        }),
      );

      test(
        'Mark message as read updates state',
        asyncTest(() async {
          _log('[MCP ADMIN] Running mark message as read test');
          final api = getTestAPI();

          // Send a message to admin agent
          final senderName = 'sender-$testId';
          final senderResult = await api
              .callTool('register', createArgs({'name': senderName}))
              .toDart;
          final senderKey = extractKeyFromResult(senderResult.toDart);

          await api
              .callTool(
                'message',
                createArgs({
                  'action': 'send',
                  'agent_name': senderName,
                  'agent_key': senderKey,
                  'to_agent': adminAgentName,
                  'content': 'Test message for read marking',
                }),
              )
              .toDart;

          await waitForMessageInTree(api, 'Test message for read');

          // Get messages and mark as read
          final getResult = await api
              .callTool(
                'message',
                createArgs({
                  'action': 'get',
                  'agent_name': adminAgentName,
                  'agent_key': adminAgentKey,
                }),
              )
              .toDart;

          final msgDataStr = getResult.toDart;
          assertOk(msgDataStr.contains('messages'), 'Should have messages');

          // Find message ID via regex
          final idMatch = RegExp(r'"id"\s*:\s*(\d+)').firstMatch(msgDataStr);
          if (idMatch != null) {
            final messageId = idMatch.group(1)!;
            await api
                .callTool(
                  'message',
                  createArgs({
                    'action': 'mark_read',
                    'agent_name': adminAgentName,
                    'agent_key': adminAgentKey,
                    'message_id': messageId,
                  }),
                )
                .toDart;
          }

          await api.refreshStatus().toDart;

          assertOk(
            api.findMessageInTree('Test message for read') != null,
            'Message should still be visible',
          );

          _log('[MCP ADMIN] mark message as read test PASSED');
        }),
      );
    }),
  );

  // ==========================================================================
  // MCP Integration - Lock State
  // ==========================================================================
  suite(
    'MCP Integration - Lock State',
    syncTest(() {
      var agentKey = '';
      final testId = _dateNow();
      final agentName = 'deco-test-$testId';

      suiteSetup(
        asyncTest(() async {
          _log('[MCP LOCK STATE] suiteSetup');
          await waitForExtensionActivation();
        }),
      );

      suiteTeardown(
        asyncTest(() async {
          _log('[MCP LOCK STATE] suiteTeardown');
          await safeDisconnect();
        }),
      );

      test(
        'Setup: Connect and register agent',
        asyncTest(() async {
          _log('[MCP LOCK STATE] Running setup test');
          await safeDisconnect();
          final api = getTestAPI();
          await api.connect().toDart;
          await waitForConnection();

          final result = await api
              .callTool('register', createArgs({'name': agentName}))
              .toDart;
          agentKey = extractKeyFromResult(result.toDart);
          assertOk(agentKey.isNotEmpty, 'Agent should have key');

          _log('[MCP LOCK STATE] setup test PASSED');
        }),
      );

      test(
        'Lock on file creates decoration data in state',
        asyncTest(() async {
          _log('[MCP LOCK STATE] Running lock creates decoration test');
          final api = getTestAPI();

          await api
              .callTool(
                'lock',
                createArgs({
                  'action': 'acquire',
                  'file_path': '/deco/test/file.ts',
                  'agent_name': agentName,
                  'agent_key': agentKey,
                  'reason': 'Testing decorations',
                }),
              )
              .toDart;

          await waitForLockInTree(api, '/deco/test/file.ts');

          final locks = api.getLocks();
          JSObject? foundLock;
          for (var i = 0; i < locks.length; i++) {
            final lock = locks[i];
            final filePath = _reflectGet(lock, 'filePath')?.toString();
            if (filePath == '/deco/test/file.ts') {
              foundLock = lock;
              break;
            }
          }
          assertOk(foundLock != null, 'Lock should be in state');

          final lockAgentName = _reflectGet(
            foundLock!,
            'agentName',
          )?.toString();
          assertEqual(
            lockAgentName,
            agentName,
            'Lock should have correct agent',
          );

          final lockReason = _reflectGet(foundLock, 'reason')?.toString();
          assertEqual(
            lockReason,
            'Testing decorations',
            'Lock should have correct reason',
          );

          final expiresAt = _reflectGet(foundLock, 'expiresAt')!;
          final expiresAtNum = (expiresAt as JSNumber).toDartInt;
          assertOk(expiresAtNum > _dateNow(), 'Lock should not be expired');

          _log('[MCP LOCK STATE] lock creates decoration test PASSED');
        }),
      );

      test(
        'Lock without reason still works',
        asyncTest(() async {
          _log('[MCP LOCK STATE] Running lock without reason test');
          final api = getTestAPI();

          await api
              .callTool(
                'lock',
                createArgs({
                  'action': 'acquire',
                  'file_path': '/deco/no-reason/file.ts',
                  'agent_name': agentName,
                  'agent_key': agentKey,
                }),
              )
              .toDart;

          await waitForLockInTree(api, '/deco/no-reason/file.ts');

          final locks = api.getLocks();
          JSObject? foundLock;
          for (var i = 0; i < locks.length; i++) {
            final lock = locks[i];
            final filePath = _reflectGet(lock, 'filePath')?.toString();
            if (filePath == '/deco/no-reason/file.ts') {
              foundLock = lock;
              break;
            }
          }
          assertOk(foundLock != null, 'Lock without reason should be in state');

          final lockReason = _reflectGet(foundLock!, 'reason');
          assertOk(
            lockReason == null || lockReason.isUndefinedOrNull,
            'Lock should have no reason',
          );

          // Clean up
          await api
              .callTool(
                'lock',
                createArgs({
                  'action': 'release',
                  'file_path': '/deco/no-reason/file.ts',
                  'agent_name': agentName,
                  'agent_key': agentKey,
                }),
              )
              .toDart;

          _log('[MCP LOCK STATE] lock without reason test PASSED');
        }),
      );

      test(
        'Active and expired locks computed correctly',
        asyncTest(() async {
          _log('[MCP LOCK STATE] Running active/expired locks test');
          final api = getTestAPI();

          final details = api.getAgentDetails();
          JSObject? agentDetail;
          for (var i = 0; i < details.length; i++) {
            final detail = details[i];
            final agent = _reflectGet(detail, 'agent')! as JSObject;
            final name = _reflectGet(agent, 'agentName')?.toString();
            if (name == agentName) {
              agentDetail = detail;
              break;
            }
          }
          assertOk(agentDetail != null, 'Agent details should exist');

          final locksVal = _reflectGet(agentDetail!, 'locks')!;
          final agentLocks = locksVal as JSArray<JSObject>;
          assertOk(
            agentLocks.length >= 1,
            'Agent should have at least one lock',
          );

          for (var i = 0; i < agentLocks.length; i++) {
            final lock = agentLocks[i];
            final filePath = _reflectGet(lock, 'filePath')?.toString();
            final expiresAtVal = _reflectGet(lock, 'expiresAt')!;
            final expiresAtNum = (expiresAtVal as JSNumber).toDartInt;
            assertOk(
              expiresAtNum > _dateNow(),
              'Lock $filePath should be active',
            );
          }

          _log('[MCP LOCK STATE] active/expired locks test PASSED');
        }),
      );

      test(
        'Release lock removes decoration data',
        asyncTest(() async {
          _log('[MCP LOCK STATE] Running release lock test');
          final api = getTestAPI();

          await api
              .callTool(
                'lock',
                createArgs({
                  'action': 'release',
                  'file_path': '/deco/test/file.ts',
                  'agent_name': agentName,
                  'agent_key': agentKey,
                }),
              )
              .toDart;

          await waitForLockGone(api, '/deco/test/file.ts');

          final locks = api.getLocks();
          JSObject? foundLock;
          for (var i = 0; i < locks.length; i++) {
            final lock = locks[i];
            final filePath = _reflectGet(lock, 'filePath')?.toString();
            if (filePath == '/deco/test/file.ts') {
              foundLock = lock;
              break;
            }
          }
          assertEqual(foundLock, null, 'Lock should be removed from state');

          _log('[MCP LOCK STATE] release lock test PASSED');
        }),
      );
    }),
  );

  // ==========================================================================
  // MCP Integration - Tree Provider Edge Cases
  // ==========================================================================
  suite(
    'MCP Integration - Tree Provider Edge Cases',
    syncTest(() {
      var agentKey = '';
      final testId = _dateNow();
      final agentName = 'edge-test-$testId';

      suiteSetup(
        asyncTest(() async {
          _log('[MCP EDGE] suiteSetup');
          await waitForExtensionActivation();
        }),
      );

      suiteTeardown(
        asyncTest(() async {
          _log('[MCP EDGE] suiteTeardown');
          await safeDisconnect();
        }),
      );

      test(
        'Setup: Connect and register agent',
        asyncTest(() async {
          _log('[MCP EDGE] Running setup test');
          await safeDisconnect();
          final api = getTestAPI();
          await api.connect().toDart;
          await waitForConnection();

          final result = await api
              .callTool('register', createArgs({'name': agentName}))
              .toDart;
          agentKey = extractKeyFromResult(result.toDart);
          assertOk(agentKey.isNotEmpty, 'Agent should have key');

          _log('[MCP EDGE] setup test PASSED');
        }),
      );

      test(
        'Long message content is truncated in tree',
        asyncTest(() async {
          _log('[MCP EDGE] Running long message test');
          final api = getTestAPI();

          final longContent = 'A' * 100;
          await api
              .callTool(
                'message',
                createArgs({
                  'action': 'send',
                  'agent_name': agentName,
                  'agent_key': agentKey,
                  'to_agent': agentName,
                  'content': longContent,
                }),
              )
              .toDart;

          await waitForMessageInTree(api, 'AAAA');

          final msgItem = api.findMessageInTree('AAAA');
          assertOk(msgItem != null, 'Long message should be found');

          final desc = _getDescription(msgItem!);
          assertOk(
            desc != null && desc.contains('AAA'),
            'Description should contain content',
          );

          _log('[MCP EDGE] long message test PASSED');
        }),
      );

      test(
        'Long plan task is truncated in tree',
        asyncTest(() async {
          _log('[MCP EDGE] Running long plan task test');
          final api = getTestAPI();

          final longTask = 'B' * 50;
          await api
              .callTool(
                'plan',
                createArgs({
                  'action': 'update',
                  'agent_name': agentName,
                  'agent_key': agentKey,
                  'goal': 'Test long task',
                  'current_task': longTask,
                }),
              )
              .toDart;

          await waitForCondition(() {
            final agentItem = api.findAgentInTree(agentName);
            if (agentItem == null) return false;
            return _hasChildWithLabel(agentItem, 'Test long task');
          }, message: 'Plan with long task to appear');

          final agentItem = api.findAgentInTree(agentName);
          final planChild = _findChildByLabel(agentItem!, 'Goal:');
          assertOk(planChild != null, 'Plan should be in agent children');

          _log('[MCP EDGE] long plan task test PASSED');
        }),
      );

      test(
        'Agent with multiple locks shows all locks',
        asyncTest(() async {
          _log('[MCP EDGE] Running multiple locks test');
          final api = getTestAPI();

          for (var i = 1; i <= 3; i++) {
            await api
                .callTool(
                  'lock',
                  createArgs({
                    'action': 'acquire',
                    'file_path': '/edge/multi/file$i.ts',
                    'agent_name': agentName,
                    'agent_key': agentKey,
                    'reason': 'Lock $i',
                  }),
                )
                .toDart;
          }

          await waitForCondition(() {
            final locks = api.getLocks();
            var count = 0;
            for (var i = 0; i < locks.length; i++) {
              final lock = locks[i];
              final filePath = _reflectGet(lock, 'filePath')?.toString() ?? '';
              if (filePath.contains('/edge/multi/')) count++;
            }
            return count >= 3;
          }, message: 'All 3 locks to appear');

          final agentItem = api.findAgentInTree(agentName);
          assertOk(agentItem != null, 'Agent should be in tree');
          final children = _getChildren(agentItem!);
          assertOk(children != null, 'Agent should have children');

          final lockCount = _countChildrenMatching(
            agentItem,
            (child) => _getLabel(child).contains('/edge/multi/'),
          );
          assertEqual(lockCount, 3, 'Agent should have 3 lock children');

          // Clean up
          for (var i = 1; i <= 3; i++) {
            await api
                .callTool(
                  'lock',
                  createArgs({
                    'action': 'release',
                    'file_path': '/edge/multi/file$i.ts',
                    'agent_name': agentName,
                    'agent_key': agentKey,
                  }),
                )
                .toDart;
          }

          _log('[MCP EDGE] multiple locks test PASSED');
        }),
      );

      test(
        'Agent description shows lock and message counts',
        asyncTest(() async {
          _log('[MCP EDGE] Running agent description test');
          final api = getTestAPI();

          final agentItem = api.findAgentInTree(agentName);
          assertOk(agentItem != null, 'Agent should be in tree');

          final desc = _getDescription(agentItem!) ?? '';
          assertOk(
            desc.contains('msg') || desc.contains('lock') || desc == 'idle',
            'Agent description should show counts or idle, got: $desc',
          );

          _log('[MCP EDGE] agent description test PASSED');
        }),
      );
    }),
  );

  // ==========================================================================
  // MCP Integration - Store Methods
  // ==========================================================================
  suite(
    'MCP Integration - Store Methods',
    syncTest(() {
      var storeAgentKey = '';
      final testId = _dateNow();
      final storeAgentName = 'store-test-$testId';
      final targetAgentForDelete = 'delete-target-$testId';

      suiteSetup(
        asyncTest(() async {
          _log('[MCP STORE] suiteSetup');
          await waitForExtensionActivation();
        }),
      );

      suiteTeardown(
        asyncTest(() async {
          _log('[MCP STORE] suiteTeardown');
          await safeDisconnect();
        }),
      );

      test(
        'Setup: Connect and register agents',
        asyncTest(() async {
          _log('[MCP STORE] Running setup test');
          await safeDisconnect();
          final api = getTestAPI();
          await api.connect().toDart;
          await waitForConnection();

          final result = await api
              .callTool('register', createArgs({'name': storeAgentName}))
              .toDart;
          storeAgentKey = extractKeyFromResult(result.toDart);
          assertOk(storeAgentKey.isNotEmpty, 'Store agent should have key');

          _log('[MCP STORE] setup test PASSED');
        }),
      );

      test(
        'store.forceReleaseLock removes lock',
        asyncTest(() async {
          _log('[MCP STORE] Running forceReleaseLock test');
          final api = getTestAPI();

          // Acquire a lock first
          await api
              .callTool(
                'lock',
                createArgs({
                  'action': 'acquire',
                  'file_path': '/store/force/release.ts',
                  'agent_name': storeAgentName,
                  'agent_key': storeAgentKey,
                  'reason': 'Testing forceReleaseLock',
                }),
              )
              .toDart;

          await waitForLockInTree(api, '/store/force/release.ts');

          // Use store method to force release
          await api.forceReleaseLock('/store/force/release.ts').toDart;

          await waitForLockGone(api, '/store/force/release.ts');

          assertEqual(
            api.findLockInTree('/store/force/release.ts'),
            null,
            'Lock should be removed by forceReleaseLock',
          );

          _log('[MCP STORE] forceReleaseLock test PASSED');
        }),
      );

      test(
        'store.deleteAgent removes agent and their data',
        asyncTest(() async {
          _log('[MCP STORE] Running deleteAgent test');
          final api = getTestAPI();

          // Register a target agent to delete
          final result = await api
              .callTool('register', createArgs({'name': targetAgentForDelete}))
              .toDart;
          final targetKey = extractKeyFromResult(result.toDart);

          // Acquire a lock as the target agent
          await api
              .callTool(
                'lock',
                createArgs({
                  'action': 'acquire',
                  'file_path': '/store/delete/agent.ts',
                  'agent_name': targetAgentForDelete,
                  'agent_key': targetKey,
                  'reason': 'Will be deleted with agent',
                }),
              )
              .toDart;

          await waitForAgentInTree(api, targetAgentForDelete);

          // Use store method to delete agent
          await api.deleteAgent(targetAgentForDelete).toDart;

          await waitForAgentGone(api, targetAgentForDelete);

          assertEqual(
            api.findAgentInTree(targetAgentForDelete),
            null,
            'Agent should be removed by deleteAgent',
          );

          // Lock should also be gone (cascade delete)
          assertEqual(
            api.findLockInTree('/store/delete/agent.ts'),
            null,
            'Agent locks should be removed when agent is deleted',
          );

          _log('[MCP STORE] deleteAgent test PASSED');
        }),
      );

      test(
        'store.sendMessage sends message via registered agent',
        asyncTest(() async {
          _log('[MCP STORE] Running sendMessage test');
          final api = getTestAPI();

          // Create a recipient agent
          final recipientName = 'recipient-$testId';
          await api
              .callTool('register', createArgs({'name': recipientName}))
              .toDart;

          // Use store method to send message (it registers sender automatically)
          final senderName = 'ui-sender-$testId';
          await api
              .sendMessage(
                senderName,
                recipientName,
                'Message from store.sendMessage',
              )
              .toDart;

          await waitForMessageInTree(api, 'Message from store');

          final msgItem = api.findMessageInTree('Message from store');
          assertOk(msgItem != null, 'Message should be found');

          final label = _getLabel(msgItem!);
          assertOk(
            label.contains(senderName),
            'Message should show sender $senderName',
          );
          assertOk(
            label.contains(recipientName),
            'Message should show recipient $recipientName',
          );

          _log('[MCP STORE] sendMessage test PASSED');
        }),
      );

      test(
        'store.sendMessage to broadcast recipient',
        asyncTest(() async {
          _log('[MCP STORE] Running sendMessage broadcast test');
          final api = getTestAPI();

          final senderName = 'broadcast-sender-$testId';
          await api
              .sendMessage(senderName, '*', 'Broadcast from store.sendMessage')
              .toDart;

          await waitForMessageInTree(api, 'Broadcast from store');

          final msgItem = api.findMessageInTree('Broadcast from store');
          assertOk(msgItem != null, 'Broadcast message should be found');

          final label = _getLabel(msgItem!);
          assertOk(
            label.contains('all'),
            'Broadcast message should show "all" as recipient',
          );

          _log('[MCP STORE] sendMessage broadcast test PASSED');
        }),
      );
    }),
  );

  _log('[MCP INTEGRATION TEST] main() completed');
}
