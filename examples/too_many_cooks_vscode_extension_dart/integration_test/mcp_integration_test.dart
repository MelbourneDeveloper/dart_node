/// MCP Integration Tests - REAL end-to-end tests (Dart).
///
/// These tests PROVE that UI tree views update when MCP server state changes.
/// NO MOCKING. NO SKIPPING. FAIL HARD.
library;

import 'dart:js_interop';

import 'test_helpers.dart';

// ============================================================================
// Mocha TDD Bindings
// ============================================================================

@JS('suite')
external void suite(String name, JSFunction fn);

@JS('suiteSetup')
external void suiteSetup(JSFunction fn);

@JS('suiteTeardown')
external void suiteTeardown(JSFunction fn);

@JS('test')
external void test(String name, JSFunction fn);

@JS('assert.ok')
external void assertOk(bool value, String? message);

@JS('assert.strictEqual')
external void assertEqual(Object? actual, Object? expected, String? message);

@JS('console.log')
external void _consoleLog(String message);

// ============================================================================
// Test Suite
// ============================================================================

void main() {
  _registerMcpIntegrationSuite();
  _registerAdminOperationsSuite();
  _registerLockStateSuite();
}

void _registerMcpIntegrationSuite() {
  suite('MCP Integration - UI Verification', (() {
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agent1Name = 'test-agent-$testId-1';
    final agent2Name = 'test-agent-$testId-2';
    String? agent1Key;
    String? agent2Key;

    suiteSetup((() async {
      await waitForExtensionActivation();
      cleanDatabase();
    }).toJS);

    suiteTeardown((() async {
      await safeDisconnect();
      cleanDatabase();
    }).toJS);

    test('Connect to MCP server', (() async {
      await safeDisconnect();
      final api = getTestAPI();
      assertEqual(api.isConnected(), false, 'Should be disconnected');

      await api.connect();
      await waitForConnection();

      assertEqual(api.isConnected(), true, 'Should be connected');
      assertEqual(api.getConnectionStatus(), 'connected', null);
    }).toJS);

    test('Empty state shows empty trees', (() async {
      final api = getTestAPI();
      await api.refreshStatus();

      final agentsTree = api.getAgentsTreeSnapshot();
      final locksTree = api.getLocksTreeSnapshot();
      final messagesTree = api.getMessagesTreeSnapshot();

      _dumpTree('AGENTS', agentsTree);
      _dumpTree('LOCKS', locksTree);
      _dumpTree('MESSAGES', messagesTree);

      assertEqual(agentsTree.length, 0, 'Agents tree should be empty');
      assertOk(
        locksTree.any((item) => item.label == 'No locks'),
        'Locks tree should show "No locks"',
      );
      assertOk(
        messagesTree.any((item) => item.label == 'No messages'),
        'Messages tree should show "No messages"',
      );
    }).toJS);

    test('Register agent-1 → label APPEARS in agents tree', (() async {
      final api = getTestAPI();

      final result = await api.callTool('register', {'name': agent1Name});
      agent1Key = _parseJson(result)['agent_key'] as String?;
      assertOk(agent1Key != null, 'Should return agent key');

      await waitForCondition(
        () => api.findAgentInTree(agent1Name) != null,
        message: '$agent1Name to appear in tree',
        timeout: 5000,
      );

      final agentItem = api.findAgentInTree(agent1Name);
      assertOk(agentItem != null, '$agent1Name MUST appear in the tree');
      assertEqual(agentItem!.label, agent1Name, 'Label must match');

      _dumpTree('AGENTS after register', api.getAgentsTreeSnapshot());
    }).toJS);

    test('Register agent-2 → both agents visible in tree', (() async {
      final api = getTestAPI();

      final result = await api.callTool('register', {'name': agent2Name});
      agent2Key = _parseJson(result)['agent_key'] as String?;

      await waitForCondition(
        () => api.getAgentsTreeSnapshot().length >= 2,
        message: '2 agents in tree',
        timeout: 5000,
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
    }).toJS);

    test('Acquire lock → file path APPEARS in locks tree', (() async {
      final api = getTestAPI();

      await api.callTool('lock', {
        'action': 'acquire',
        'file_path': '/src/main.ts',
        'agent_name': agent1Name,
        'agent_key': agent1Key,
        'reason': 'Editing main',
      });

      await waitForCondition(
        () => api.findLockInTree('/src/main.ts') != null,
        message: '/src/main.ts to appear in locks tree',
        timeout: 5000,
      );

      final lockItem = api.findLockInTree('/src/main.ts');
      _dumpTree('LOCKS after acquire', api.getLocksTreeSnapshot());

      assertOk(lockItem != null, '/src/main.ts MUST appear in the tree');
      assertEqual(lockItem!.label, '/src/main.ts', 'Label must be file path');
      assertOk(
        lockItem.description?.contains(agent1Name) ?? false,
        'Description should contain agent name',
      );
    }).toJS);

    test('Acquire 2 more locks → all 3 file paths visible', (() async {
      final api = getTestAPI();

      await api.callTool('lock', {
        'action': 'acquire',
        'file_path': '/src/utils.ts',
        'agent_name': agent1Name,
        'agent_key': agent1Key,
        'reason': 'Utils',
      });

      await api.callTool('lock', {
        'action': 'acquire',
        'file_path': '/src/types.ts',
        'agent_name': agent2Name,
        'agent_key': agent2Key,
        'reason': 'Types',
      });

      await waitForCondition(
        () => api.getLockTreeItemCount() >= 3,
        message: '3 locks in tree',
        timeout: 5000,
      );

      _dumpTree('LOCKS after 3 acquires', api.getLocksTreeSnapshot());

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
    }).toJS);

    test('Release lock → file path DISAPPEARS from tree', (() async {
      final api = getTestAPI();

      await api.callTool('lock', {
        'action': 'release',
        'file_path': '/src/utils.ts',
        'agent_name': agent1Name,
        'agent_key': agent1Key,
      });

      await waitForCondition(
        () => api.findLockInTree('/src/utils.ts') == null,
        message: '/src/utils.ts to disappear from tree',
        timeout: 5000,
      );

      _dumpTree('LOCKS after release', api.getLocksTreeSnapshot());

      assertEqual(
        api.findLockInTree('/src/utils.ts'),
        null,
        '/src/utils.ts MUST NOT be in tree',
      );
      assertOk(
        api.findLockInTree('/src/main.ts') != null,
        '/src/main.ts MUST still be in tree',
      );
      assertEqual(api.getLockTreeItemCount(), 2, 'Exactly 2 lock items remain');
    }).toJS);

    test('Send message → message APPEARS in tree', (() async {
      final api = getTestAPI();

      await api.callTool('message', {
        'action': 'send',
        'agent_name': agent1Name,
        'agent_key': agent1Key,
        'to_agent': agent2Name,
        'content': 'Starting work on main.ts',
      });

      await waitForCondition(
        () => api.findMessageInTree('Starting work') != null,
        message: 'message to appear in tree',
        timeout: 5000,
      );

      _dumpTree('MESSAGES after send', api.getMessagesTreeSnapshot());

      final msgItem = api.findMessageInTree('Starting work');
      assertOk(msgItem != null, 'Message MUST appear in tree');
      assertOk(
        msgItem!.label.contains(agent1Name),
        'Message label should contain sender',
      );
    }).toJS);

    test('Broadcast message → appears with "all" label', (() async {
      final api = getTestAPI();

      await api.callTool('message', {
        'action': 'send',
        'agent_name': agent1Name,
        'agent_key': agent1Key,
        'to_agent': '*',
        'content': 'BROADCAST: Important announcement',
      });

      await waitForCondition(
        () => api.findMessageInTree('BROADCAST') != null,
        message: 'broadcast message to appear in tree',
        timeout: 5000,
      );

      _dumpTree('MESSAGES after broadcast', api.getMessagesTreeSnapshot());

      final broadcastMsg = api.findMessageInTree('BROADCAST');
      assertOk(broadcastMsg != null, 'Broadcast message MUST appear in tree');
      assertOk(
        broadcastMsg!.label.contains('all'),
        'Broadcast label should show "all" for recipient',
      );
    }).toJS);

    test('Disconnect clears all tree views', (() async {
      await safeDisconnect();
      final api = getTestAPI();

      assertEqual(api.isConnected(), false, 'Should be disconnected');
      assertEqual(api.getAgents().length, 0, 'Agents should be empty');
      assertEqual(api.getLocks().length, 0, 'Locks should be empty');
      assertEqual(api.getMessages().length, 0, 'Messages should be empty');
      assertEqual(
        api.getAgentsTreeSnapshot().length,
        0,
        'Agents tree should be empty',
      );
    }).toJS);
  }).toJS);
}

void _registerAdminOperationsSuite() {
  suite('MCP Integration - Admin Operations', (() {
    final testId = DateTime.now().millisecondsSinceEpoch;
    final adminAgentName = 'admin-test-$testId';
    final targetAgentName = 'target-test-$testId';
    String? adminAgentKey;
    String? targetAgentKey;

    suiteSetup((() async {
      await waitForExtensionActivation();
    }).toJS);

    suiteTeardown((() async {
      await safeDisconnect();
    }).toJS);

    test('Setup: Connect and register agents', (() async {
      await safeDisconnect();
      final api = getTestAPI();
      await api.connect();
      await waitForConnection();

      var result = await api.callTool('register', {'name': adminAgentName});
      adminAgentKey = _parseJson(result)['agent_key'] as String?;
      assertOk(adminAgentKey != null, 'Admin agent should have key');

      result = await api.callTool('register', {'name': targetAgentName});
      targetAgentKey = _parseJson(result)['agent_key'] as String?;
      assertOk(targetAgentKey != null, 'Target agent should have key');

      await api.callTool('lock', {
        'action': 'acquire',
        'file_path': '/admin/test/file.ts',
        'agent_name': targetAgentName,
        'agent_key': targetAgentKey,
        'reason': 'Testing admin delete',
      });

      await waitForCondition(
        () => api.findLockInTree('/admin/test/file.ts') != null,
        message: 'Lock to appear',
        timeout: 5000,
      );
    }).toJS);

    test('Force release lock via admin → lock DISAPPEARS', (() async {
      final api = getTestAPI();

      assertOk(
        api.findLockInTree('/admin/test/file.ts') != null,
        'Lock should exist before force release',
      );

      await api.callTool('admin', {
        'action': 'delete_lock',
        'file_path': '/admin/test/file.ts',
      });

      await waitForCondition(
        () => api.findLockInTree('/admin/test/file.ts') == null,
        message: 'Lock to disappear after force release',
        timeout: 5000,
      );

      assertEqual(
        api.findLockInTree('/admin/test/file.ts'),
        null,
        'Lock should be gone after force release',
      );
    }).toJS);

    test('Delete agent via admin → agent DISAPPEARS from tree', (() async {
      final api = getTestAPI();

      await waitForCondition(
        () => api.findAgentInTree(targetAgentName) != null,
        message: 'Target agent to appear',
        timeout: 5000,
      );
      assertOk(
        api.findAgentInTree(targetAgentName) != null,
        'Target agent should exist before delete',
      );

      await api.callTool('admin', {
        'action': 'delete_agent',
        'agent_name': targetAgentName,
      });

      await waitForCondition(
        () => api.findAgentInTree(targetAgentName) == null,
        message: 'Target agent to disappear after delete',
        timeout: 5000,
      );

      assertEqual(
        api.findAgentInTree(targetAgentName),
        null,
        'Target agent should be gone after delete',
      );
    }).toJS);
  }).toJS);
}

void _registerLockStateSuite() {
  suite('MCP Integration - Lock State', (() {
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agentName = 'lock-test-$testId';
    String? agentKey;

    suiteSetup((() async {
      await waitForExtensionActivation();
    }).toJS);

    suiteTeardown((() async {
      await safeDisconnect();
    }).toJS);

    test('Setup: Connect and register agent', (() async {
      await safeDisconnect();
      final api = getTestAPI();
      await api.connect();
      await waitForConnection();

      final result = await api.callTool('register', {'name': agentName});
      agentKey = _parseJson(result)['agent_key'] as String?;
      assertOk(agentKey != null, 'Agent should have key');
    }).toJS);

    test('Lock creates data in state', (() async {
      final api = getTestAPI();

      await api.callTool('lock', {
        'action': 'acquire',
        'file_path': '/lock/test/file.ts',
        'agent_name': agentName,
        'agent_key': agentKey,
        'reason': 'Testing lock state',
      });

      await waitForCondition(
        () => api.findLockInTree('/lock/test/file.ts') != null,
        message: 'Lock to appear in tree',
        timeout: 5000,
      );

      final locks = api.getLocks();
      final lock = locks.where((l) => l.filePath == '/lock/test/file.ts');
      assertOk(lock.isNotEmpty, 'Lock should be in state');
      assertEqual(lock.first.agentName, agentName, 'Lock has correct agent');
      assertEqual(
        lock.first.reason,
        'Testing lock state',
        'Lock has correct reason',
      );
    }).toJS);

    test('Release lock removes data from state', (() async {
      final api = getTestAPI();

      await api.callTool('lock', {
        'action': 'release',
        'file_path': '/lock/test/file.ts',
        'agent_name': agentName,
        'agent_key': agentKey,
      });

      await waitForCondition(
        () => api.findLockInTree('/lock/test/file.ts') == null,
        message: 'Lock to disappear from tree',
        timeout: 5000,
      );

      final locks = api.getLocks();
      final lock = locks.where((l) => l.filePath == '/lock/test/file.ts');
      assertOk(lock.isEmpty, 'Lock should be removed from state');
    }).toJS);
  }).toJS);
}

void _dumpTree(String name, List<TreeItemSnapshot> items) {
  _consoleLog('\n=== $name TREE ===');
  for (final item in items) {
    final desc = item.description != null ? ' [${item.description}]' : '';
    _consoleLog('- ${item.label}$desc');
    if (item.children != null) {
      for (final child in item.children!) {
        final childDesc =
            child.description != null ? ' [${child.description}]' : '';
        _consoleLog('  - ${child.label}$childDesc');
      }
    }
  }
  _consoleLog('=== END ===\n');
}

@JS('JSON.parse')
external JSObject _jsonParse(String json);

Map<String, Object?> _parseJson(String json) {
  final obj = _jsonParse(json);
  final result = obj.dartify();
  return result is Map ? Map<String, Object?>.from(result) : {};
}
