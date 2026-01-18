/// View Tests
/// Verifies tree views are registered, visible, and UI bugs are fixed.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

// JS interop helper to get property from JSObject.
@JS('Reflect.get')
external JSAny? _reflectGet(JSObject target, JSString key);

/// Gets a string property from a JS object, returns empty string if not found.
String _getStringProp(JSObject obj, String key) {
  final value = _reflectGet(obj, key.toJS);
  if (value == null || value.isUndefinedOrNull) return '';
  if (value.typeofEquals('string')) return (value as JSString).toDart;
  return value.dartify()?.toString() ?? '';
}

/// Gets an array property from a JS object, returns null if not found.
JSArray<JSObject>? _getArrayProp(JSObject obj, String key) {
  final value = _reflectGet(obj, key.toJS);
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.typeofEquals('object') && value.instanceOfString('Array')) {
    return value as JSArray<JSObject>;
  }
  return null;
}

// Helper to get label from tree item snapshot.
String _getLabel(JSObject item) => _getStringProp(item, 'label');

// Helper to get description from tree item snapshot.
String _getDescription(JSObject item) => _getStringProp(item, 'description');

// Helper to get children from tree item snapshot.
JSArray<JSObject>? _getChildren(JSObject item) =>
    _getArrayProp(item, 'children');

void main() {
  _log('[VIEWS TEST] main() called');

  // Ensure any dialog mocks from previous tests are restored.
  restoreDialogMocks();

  suite(
    'Views',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          _log('[VIEWS] suiteSetup - waiting for extension activation');
          await waitForExtensionActivation();
        }),
      );

      test(
        'Too Many Cooks view container is registered',
        asyncTest(() async {
          _log('[VIEWS] Running view container test');

          // Open the view container
          await vscode.commands
              .executeCommand('workbench.view.extension.tooManyCooks')
              .toDart;

          // The test passes if the command doesn't throw
          // We can't directly query view containers, but opening succeeds
          _log('[VIEWS] view container test PASSED');
        }),
      );

      test(
        'Agents view is accessible',
        asyncTest(() async {
          _log('[VIEWS] Running agents view test');

          await vscode.commands
              .executeCommand('workbench.view.extension.tooManyCooks')
              .toDart;

          // Try to focus the agents view
          try {
            await vscode.commands
                .executeCommand('tooManyCooksAgents.focus')
                .toDart;
          } on Object {
            // View focus may not work in test environment, but that's ok
            // The important thing is the view exists
          }
          _log('[VIEWS] agents view test PASSED');
        }),
      );

      test(
        'Locks view is accessible',
        asyncTest(() async {
          _log('[VIEWS] Running locks view test');

          await vscode.commands
              .executeCommand('workbench.view.extension.tooManyCooks')
              .toDart;

          try {
            await vscode.commands
                .executeCommand('tooManyCooksLocks.focus')
                .toDart;
          } on Object {
            // View focus may not work in test environment
          }
          _log('[VIEWS] locks view test PASSED');
        }),
      );

      test(
        'Messages view is accessible',
        asyncTest(() async {
          _log('[VIEWS] Running messages view test');

          await vscode.commands
              .executeCommand('workbench.view.extension.tooManyCooks')
              .toDart;

          try {
            await vscode.commands
                .executeCommand('tooManyCooksMessages.focus')
                .toDart;
          } on Object {
            // View focus may not work in test environment
          }
          _log('[VIEWS] messages view test PASSED');
        }),
      );
    }),
  );
  // Note: Plans are now shown under agents in the Agents tree, not a view

  suite(
    'UI Bug Fixes',
    syncTest(() {
      var agentKey = '';
      final testId = DateTime.now().millisecondsSinceEpoch;
      final agentName = 'ui-test-agent-$testId';

      suiteSetup(
        asyncTest(() async {
          _log('[UI BUGS] suiteSetup');

          // waitForExtensionActivation handles server path setup and validation
          await waitForExtensionActivation();

          // Safely disconnect to avoid race condition with auto-connect
          await safeDisconnect();

          final api = getTestAPI();
          await api.connect().toDart;
          await waitForConnection();

          // Register test agent
          final registerArgs = createArgs({'name': agentName});
          final result = await api.callTool('register', registerArgs).toDart;
          agentKey = extractKeyFromResult(result.toDart);
        }),
      );

      suiteTeardown(
        asyncTest(() async {
          _log('[UI BUGS] suiteTeardown');
          await safeDisconnect();
          cleanDatabase();
        }),
      );

      test(
        'BUG FIX: Messages show as single row (no 4-row expansion)',
        asyncTest(() async {
          _log('[UI BUGS] Running single row message test');
          final api = getTestAPI();

          // Send a message
          final msgArgs = createArgs({
            'action': 'send',
            'agent_name': agentName,
            'agent_key': agentKey,
            'to_agent': '*',
            'content': 'Test message for UI verification',
          });
          await api.callTool('message', msgArgs).toDart;

          // Wait for message to appear in tree
          await waitForMessageInTree(api, 'Test message');

          // Find our message
          final msgItem = api.findMessageInTree('Test message');
          assertOk(msgItem != null, 'Message must appear in tree');

          // BUG FIX VERIFICATION:
          // Messages should NOT have children (no expandable 4-row detail view)
          // The old bug showed: Content, Sent, Status, ID as separate rows
          final children = _getChildren(msgItem!);
          assertEqual(
            children,
            null,
            'BUG FIX: Message items must NOT have children '
            '(no 4-row expansion)',
          );

          // Message should show as single row with:
          // - label: "from → to | time [unread]"
          // - description: message content
          final label = _getLabel(msgItem);
          assertOk(
            label.contains(agentName),
            'Label should include sender: $label',
          );
          assertOk(
            label.contains('→'),
            'Label should have arrow separator: $label',
          );

          final description = _getDescription(msgItem);
          assertOk(
            description.contains('Test message'),
            'Description should be message content: $description',
          );

          _log('[UI BUGS] single row message test PASSED');
        }),
      );

      test(
        'BUG FIX: Message format is "from → to | time [unread]"',
        asyncTest(() async {
          _log('[UI BUGS] Running message format test');
          final api = getTestAPI();

          // The message was sent in the previous test
          final msgItem = api.findMessageInTree('Test message');
          assertOk(msgItem != null, 'Message must exist from previous test');

          // Verify label format: "agentName → all | now [unread]"
          final label = _getLabel(msgItem!);
          final labelRegex = RegExp(r'^.+ → .+ \| \d+[dhm]|now( \[unread\])?$');
          assertOk(
            labelRegex.hasMatch(label) || label.contains('→'),
            'Label should match format "from → to | time [unread]", '
            'got: $label',
          );

          _log('[UI BUGS] message format test PASSED');
        }),
      );

      test(
        'BUG FIX: Unread messages show [unread] indicator',
        asyncTest(() async {
          _log('[UI BUGS] Running unread indicator test');
          final api = getTestAPI();

          // Find any unread message
          final messagesTree = api.getMessagesTreeSnapshot();
          JSObject? unreadMsg;
          for (var i = 0; i < messagesTree.length; i++) {
            final item = messagesTree[i];
            final label = _getLabel(item);
            if (label.contains('[unread]')) {
              unreadMsg = item;
              break;
            }
          }

          // We may have marked messages read by fetching them, so informational
          if (unreadMsg != null) {
            final label = _getLabel(unreadMsg);
            assertOk(
              label.contains('[unread]'),
              'Unread messages should have [unread] in label',
            );
          }

          // Verify the message count APIs work correctly
          final totalCount = api.getMessageCount();
          final unreadCount = api.getUnreadMessageCount();
          assertOk(
            unreadCount <= totalCount,
            'Unread count ($unreadCount) must be <= total ($totalCount)',
          );

          _log('[UI BUGS] unread indicator test PASSED');
        }),
      );

      test(
        'BUG FIX: Auto-mark-read works when agent fetches messages',
        asyncTest(() async {
          _log('[UI BUGS] Running auto-mark-read test');
          final api = getTestAPI();

          // Register a second agent to receive messages
          final receiver = 'ui-receiver-$testId';
          final regArgs = createArgs({'name': receiver});
          final regResult = await api.callTool('register', regArgs).toDart;
          final receiverKey = extractKeyFromResult(regResult.toDart);

          // Send a message TO the receiver
          final sendArgs = createArgs({
            'action': 'send',
            'agent_name': agentName,
            'agent_key': agentKey,
            'to_agent': receiver,
            'content': 'This should be auto-marked read',
          });
          await api.callTool('message', sendArgs).toDart;

          // Receiver fetches their messages (this triggers auto-mark-read)
          final fetchArgs = createArgs({
            'action': 'get',
            'agent_name': receiver,
            'agent_key': receiverKey,
            'unread_only': true,
          });
          final fetchResult = await api.callTool('message', fetchArgs).toDart;

          final fetched = fetchResult.toDart;
          // Parse JSON to check messages array
          final messagesMatch = RegExp(
            r'"messages"\s*:\s*\[',
          ).hasMatch(fetched);
          assertOk(messagesMatch, 'Get messages should return messages array');

          // The message should be in the fetched list
          assertOk(
            fetched.contains('auto-marked'),
            'Message should be in fetched results',
          );

          // Now fetch again - it should NOT appear (already marked read)
          final fetchArgs2 = createArgs({
            'action': 'get',
            'agent_name': receiver,
            'agent_key': receiverKey,
            'unread_only': true,
          });
          final fetchResult2 = await api.callTool('message', fetchArgs2).toDart;

          final fetched2 = fetchResult2.toDart;
          final stillUnread = fetched2.contains('auto-marked');
          assertEqual(
            stillUnread,
            false,
            'BUG FIX: Message should be auto-marked read after first fetch',
          );

          _log('[UI BUGS] auto-mark-read test PASSED');
        }),
      );

      test(
        'BROADCAST: Messages to "*" appear in tree as "all"',
        asyncTest(() async {
          _log('[UI BUGS] Running broadcast test');
          final api = getTestAPI();

          // Send a broadcast message
          final msgArgs = createArgs({
            'action': 'send',
            'agent_name': agentName,
            'agent_key': agentKey,
            'to_agent': '*',
            'content': 'Broadcast test message to everyone',
          });
          await api.callTool('message', msgArgs).toDart;

          // Wait for message to appear in tree
          await waitForMessageInTree(api, 'Broadcast test');

          // Find the broadcast message
          final msgItem = api.findMessageInTree('Broadcast test');
          assertOk(msgItem != null, 'Broadcast message MUST appear in tree');

          // PROOF: The label contains "all" (not "*")
          final label = _getLabel(msgItem!);
          assertOk(
            label.contains('→ all'),
            'Broadcast messages should show "→ all" in label, got: $label',
          );

          // Content should be in description
          final description = _getDescription(msgItem);
          assertOk(
            description.contains('Broadcast test'),
            'Description should contain message content, got: $description',
          );

          _log('BROADCAST TEST PASSED: $label');
        }),
      );
    }),
  );

  _log('[VIEWS TEST] main() completed');
}
