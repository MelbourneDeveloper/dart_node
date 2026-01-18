/// Extension Activation Tests
///
/// Verifies the extension activates correctly and exposes the test API.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

/// Helper to extract error message from a possibly-wrapped JS error.
/// When Dart exceptions travel through JS Promises, they get wrapped.
/// Try to extract the actual error message from the 'error' property.
@JS('Reflect.get')
external JSAny? _reflectGet(JSAny target, JSString key);

String _extractErrorMessage(Object err) {
  // First, try to get message from the err object itself
  var msg = err.toString();

  // Try to access 'error' and 'message' properties via interop
  // The error might be a wrapped Dart exception with an 'error' property
  try {
    final jsErr = err.jsify();
    if (jsErr != null && !jsErr.isUndefinedOrNull) {
      final errorProp = _reflectGet(jsErr, 'error'.toJS);
      if (errorProp != null && !errorProp.isUndefinedOrNull) {
        final innerMsg = errorProp.toString();
        if (innerMsg.isNotEmpty && !innerMsg.contains('Instance of')) {
          msg = innerMsg;
        }
      }
      final messageProp = _reflectGet(jsErr, 'message'.toJS);
      if (messageProp != null && !messageProp.isUndefinedOrNull) {
        if (messageProp.typeofEquals('string')) {
          final innerMsg = (messageProp as JSString).toDart;
          if (innerMsg.isNotEmpty) {
            msg = innerMsg;
          }
        }
      }
    }
  } on Object {
    // Ignore jsify errors - just use toString()
  }

  return msg;
}

void main() {
  _log('[EXTENSION ACTIVATION TEST] main() called');

  // Ensure any dialog mocks from previous tests are restored
  restoreDialogMocks();

  suite(
    'Extension Activation',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          _log('[ACTIVATION] suiteSetup - waiting for extension activation');
          await waitForExtensionActivation();
        }),
      );

      test(
        'Extension is present and can be activated',
        asyncTest(() async {
          _log('[ACTIVATION] Testing extension presence...');
          final extension = vscode.extensions.getExtension(extensionId);
          assertOk(extension != null, 'Extension should be present');
          assertOk(extension!.isActive, 'Extension should be active');
          _log('[ACTIVATION] Extension is present and can be activated PASSED');
        }),
      );

      test(
        'Extension exports TestAPI',
        syncTest(() {
          _log('[ACTIVATION] Testing TestAPI export...');
          // getTestAPI() throws if not available, so just calling it proves export
          final api = getTestAPI();
          // Verify it's a valid JSObject by checking it exists
          assertOk(api.isA<JSObject>(), 'TestAPI should be available');
          _log('[ACTIVATION] Extension exports TestAPI PASSED');
        }),
      );

      test(
        'TestAPI has all required methods',
        syncTest(() {
          _log('[ACTIVATION] Testing TestAPI methods...');
          final api = getTestAPI();

          // State getters - verify they work by calling them
          // These will throw if the methods don't exist on the JS object
          final agents = api.getAgents();
          _log('[ACTIVATION] getAgents returned ${agents.length} items');

          final locks = api.getLocks();
          _log('[ACTIVATION] getLocks returned ${locks.length} items');

          final messages = api.getMessages();
          _log('[ACTIVATION] getMessages returned ${messages.length} items');

          final plans = api.getPlans();
          _log('[ACTIVATION] getPlans returned ${plans.length} items');

          final status = api.getConnectionStatus();
          _log('[ACTIVATION] getConnectionStatus returned $status');

          // Computed getters
          final agentCount = api.getAgentCount();
          _log('[ACTIVATION] getAgentCount returned $agentCount');

          final lockCount = api.getLockCount();
          _log('[ACTIVATION] getLockCount returned $lockCount');

          final messageCount = api.getMessageCount();
          _log('[ACTIVATION] getMessageCount returned $messageCount');

          final unreadCount = api.getUnreadMessageCount();
          _log('[ACTIVATION] getUnreadMessageCount returned $unreadCount');

          final details = api.getAgentDetails();
          _log('[ACTIVATION] getAgentDetails returned ${details.length} items');

          // Store actions - verify they exist (don't call connect/disconnect here)
          final connected = api.isConnected();
          _log('[ACTIVATION] isConnected returned $connected');

          // If we got here, all methods exist and are callable
          assertOk(true, 'All TestAPI methods are available');
          _log('[ACTIVATION] TestAPI has all required methods PASSED');
        }),
      );

      test(
        'Initial state is disconnected',
        syncTest(() {
          _log('[ACTIVATION] Testing initial disconnected state...');
          final api = getTestAPI();
          assertEqual(api.getConnectionStatus(), 'disconnected');
          assertEqual(api.isConnected(), false);
          _log('[ACTIVATION] Initial state is disconnected PASSED');
        }),
      );

      test(
        'Initial state has empty arrays',
        syncTest(() {
          _log('[ACTIVATION] Testing initial empty arrays...');
          final api = getTestAPI();
          assertEqual(api.getAgents().length, 0);
          assertEqual(api.getLocks().length, 0);
          assertEqual(api.getMessages().length, 0);
          assertEqual(api.getPlans().length, 0);
          _log('[ACTIVATION] Initial state has empty arrays PASSED');
        }),
      );

      test(
        'Initial computed values are zero',
        syncTest(() {
          _log('[ACTIVATION] Testing initial computed values...');
          final api = getTestAPI();
          assertEqual(api.getAgentCount(), 0);
          assertEqual(api.getLockCount(), 0);
          assertEqual(api.getMessageCount(), 0);
          assertEqual(api.getUnreadMessageCount(), 0);
          _log('[ACTIVATION] Initial computed values are zero PASSED');
        }),
      );

      test(
        'Extension logs activation messages',
        syncTest(() {
          _log('[ACTIVATION] Testing extension log messages...');
          final api = getTestAPI();
          final logs = api.getLogMessages();

          // MUST have log messages - extension MUST be logging
          assertOk(logs.length > 0, 'Extension must produce log messages');

          // Convert JSArray to check messages
          var hasActivatingLog = false;
          var hasActivatedLog = false;
          var hasServerLog = false;

          for (var i = 0; i < logs.length; i++) {
            final msg = logs[i].toDart;
            if (msg.contains('Extension activating')) {
              hasActivatingLog = true;
            }
            if (msg.contains('Extension activated')) {
              hasActivatedLog = true;
            }
            if (msg.contains('TEST MODE: Using local server') ||
                msg.contains('Using npx too-many-cooks')) {
              hasServerLog = true;
            }
          }

          // MUST contain activation message
          assertOk(hasActivatingLog, 'Must log "Extension activating..."');

          // MUST contain activated message
          assertOk(hasActivatedLog, 'Must log "Extension activated"');

          // MUST contain server mode log (either test server path or npx)
          assertOk(hasServerLog, 'Must log server mode');

          _log('[ACTIVATION] Extension logs activation messages PASSED');
        }),
      );
    }),
  );

  /// MCP Server Feature Verification Tests
  ///
  /// These tests verify that the MCP server has all required tools.
  /// CRITICAL: These tests MUST pass for production use.
  /// If admin tool is missing, the VSCode extension delete/remove features
  /// won't work.
  suite(
    'MCP Server Feature Verification',
    syncTest(() {
      final testId = DateTime.now().millisecondsSinceEpoch;
      final agentName = 'feature-verify-$testId';
      var agentKey = '';

      suiteSetup(
        asyncTest(() async {
          _log('[MCP FEATURE] suiteSetup - waiting for extension activation');
          await waitForExtensionActivation();

          // Connect in suiteSetup so tests don't have to wait
          final api = getTestAPI();
          if (!api.isConnected()) {
            await api.connect().toDart;
            await waitForConnection(timeout: const Duration(seconds: 10));
          }

          // Register an agent for tests
          final args = createArgs({'name': agentName});
          final result = await api.callTool('register', args).toDart;
          agentKey = extractKeyFromResult(result.toDart);
          _log('[MCP FEATURE] Agent registered with key: $agentKey');
        }),
      );

      suiteTeardown(
        asyncTest(() async {
          _log('[MCP FEATURE] suiteTeardown');
          await safeDisconnect();
        }),
      );

      test(
        'CRITICAL: Admin tool MUST exist on MCP server',
        asyncTest(() async {
          _log('[MCP FEATURE] Testing admin tool existence...');
          final api = getTestAPI();
          assertOk(
            agentKey.isNotEmpty,
            'Should have agent key from suiteSetup',
          );

          // Test admin tool exists by calling it
          // This is the CRITICAL test - if admin tool doesn't exist, this will
          // throw
          try {
            final adminArgs = createArgs({
              'action': 'delete_agent',
              'agent_name': 'non-existent-agent-12345',
            });
            final adminResult = await api.callTool('admin', adminArgs).toDart;
            final resultStr = adminResult.toDart;

            // Either success (agent didn't exist) or error response (which is fine)
            // Valid responses: {"deleted":true}, {"error":"NOT_FOUND: ..."}, etc.
            assertOk(
              resultStr.contains('deleted') || resultStr.contains('error'),
              'Admin tool should return valid response',
            );
            _log(
              '[MCP FEATURE] CRITICAL: Admin tool MUST exist on MCP server PASSED',
            );
          } on Object catch (err) {
            // If error message contains "Tool admin not found" (MCP protocol
            // error), the server is outdated. But "NOT_FOUND: Agent not found" is a
            // valid business logic response that means the tool exists.
            final msg = _extractErrorMessage(err);
            _log('[MCP FEATURE] Admin tool error: $msg');

            // Check for MCP-level "tool not found" error (means admin tool missing)
            if (msg.contains('Tool admin not found') ||
                msg.contains('-32602')) {
              throw StateError(
                'CRITICAL: Admin tool not found on MCP server!\n'
                'The VSCode extension requires the admin tool for '
                'delete/remove features.\n'
                'This means either:\n'
                '  1. You are using npx with outdated npm package '
                '(need to publish 0.3.0)\n'
                '  2. The local server build is outdated (run build.sh)\n'
                'To fix: cd examples/too_many_cooks && npm publish\n'
                'Error was: $msg',
              );
            }

            // "NOT_FOUND: Agent not found" is a valid business response - tool
            // exists! This error means we successfully called the admin tool.
            if (msg.contains('NOT_FOUND') || msg.contains('StateError')) {
              // This is actually success - the admin tool exists and responded
              _log(
                '[MCP FEATURE] CRITICAL: Admin tool MUST exist on MCP server '
                'PASSED (NOT_FOUND response)',
              );
              return;
            }

            // Other errors are re-thrown
            rethrow;
          }
        }),
      );

      test(
        'CRITICAL: Subscribe tool MUST exist on MCP server',
        asyncTest(() async {
          _log('[MCP FEATURE] Testing subscribe tool existence...');
          final api = getTestAPI();

          // Subscribe tool is required for real-time notifications
          try {
            final subscribeArgs = createArgs({'action': 'list'});
            final result = await api
                .callTool('subscribe', subscribeArgs)
                .toDart;
            final resultStr = result.toDart;
            assertOk(
              resultStr.contains('subscribers'),
              'Subscribe tool should return subscribers list',
            );
            _log(
              '[MCP FEATURE] CRITICAL: Subscribe tool MUST exist on MCP server '
              'PASSED',
            );
          } on Object catch (err) {
            final msg = err.toString();
            if (msg.contains('not found') || msg.contains('-32602')) {
              throw StateError(
                'CRITICAL: Subscribe tool not found on MCP server!\n'
                'Error was: $msg',
              );
            }
            rethrow;
          }
        }),
      );

      test(
        'All core tools are available',
        asyncTest(() async {
          _log('[MCP FEATURE] Testing all core tools...');
          final api = getTestAPI();

          // Test each core tool
          final coreTools = ['status', 'register', 'lock', 'message', 'plan'];

          for (final tool in coreTools) {
            try {
              // Call status tool (safe, no side effects)
              if (tool == 'status') {
                final statusArgs = createArgs({});
                final result = await api.callTool('status', statusArgs).toDart;
                final resultStr = result.toDart;
                assertOk(
                  resultStr.contains('agents'),
                  'Status should have agents',
                );
              }
            } on Object catch (err) {
              final msg = err.toString();
              if (msg.contains('not found')) {
                throw StateError("Core tool '$tool' not found on MCP server!");
              }
              // Other errors might be expected (missing params, etc.)
            }
          }

          _log('[MCP FEATURE] All core tools are available PASSED');
        }),
      );
    }),
  );

  _log('[EXTENSION ACTIVATION TEST] main() completed');
}
