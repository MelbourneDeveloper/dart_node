/// Extension Activation Tests (Dart)
///
/// Verifies the extension activates correctly and exposes the test API.
/// This file compiles to JavaScript and runs via Mocha in VSCode test host.
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

// ============================================================================
// Test Suite
// ============================================================================

void main() {
  _registerExtensionActivationSuite();
  _registerMcpServerFeatureVerificationSuite();
}

void _registerExtensionActivationSuite() {
  suite('Extension Activation', (() {
    suiteSetup((() async {
      await waitForExtensionActivation();
    }).toJS);

    test('Extension is present and can be activated', (() {
      final ext = vscodeExtensions.getExtension(
        'Nimblesite.too-many-cooks-dart',
      );
      assertOk(ext != null, 'Extension should be present');
      assertOk(ext!.isActive, 'Extension should be active');
    }).toJS);

    test('Extension exports TestAPI', (() {
      final api = getTestAPI();
      assertOk(api.isValid, 'TestAPI should be available');
    }).toJS);

    test('TestAPI has all required methods', (() {
      final api = getTestAPI();
      _verifyApiMethods(api);
      assertOk(true, 'All TestAPI methods are callable');
    }).toJS);

    test('Initial state is disconnected', (() {
      final api = getTestAPI();
      assertEqual(api.getConnectionStatus(), 'disconnected', null);
      assertEqual(api.isConnected(), false, null);
    }).toJS);

    test('Initial state has empty arrays', (() {
      final api = getTestAPI();
      assertEqual(api.getAgents().length, 0, 'Agents should be empty');
      assertEqual(api.getLocks().length, 0, 'Locks should be empty');
      assertEqual(api.getMessages().length, 0, 'Messages should be empty');
      assertEqual(api.getPlans().length, 0, 'Plans should be empty');
    }).toJS);

    test('Initial computed values are zero', (() {
      final api = getTestAPI();
      assertEqual(api.getAgentCount(), 0, null);
      assertEqual(api.getLockCount(), 0, null);
      assertEqual(api.getMessageCount(), 0, null);
      assertEqual(api.getUnreadMessageCount(), 0, null);
    }).toJS);

    test('Extension logs activation messages', (() {
      final api = getTestAPI();
      final logs = api.getLogMessages();

      assertOk(logs.isNotEmpty, 'Extension must produce log messages');

      final hasActivating = logs.any((m) => m.contains('Extension activating'));
      assertOk(hasActivating, 'Must log "Extension activating..."');

      final hasActivated = logs.any((m) => m.contains('Extension activated'));
      assertOk(hasActivated, 'Must log "Extension activated"');

      final hasServerLog = logs.any(
        (m) =>
            m.contains('TEST MODE: Using local server') ||
            m.contains('Using npx too-many-cooks'),
      );
      assertOk(hasServerLog, 'Must log server mode');
    }).toJS);
  }).toJS);
}

/// Verifies all API methods are callable without throwing.
void _verifyApiMethods(TestAPI api) {
  api
    ..getAgents()
    ..getLocks()
    ..getMessages()
    ..getPlans()
    ..getConnectionStatus()
    ..getAgentCount()
    ..getLockCount()
    ..getMessageCount()
    ..getUnreadMessageCount()
    ..getAgentDetails()
    ..isConnected()
    ..isConnecting();
}

void _registerMcpServerFeatureVerificationSuite() {
  suite('MCP Server Feature Verification', (() {
    final testId = DateTime.now().millisecondsSinceEpoch;
    final agentName = 'feature-verify-$testId';
    String? agentKey;

    suiteSetup((() async {
      await waitForExtensionActivation();

      final api = getTestAPI();
      if (!api.isConnected()) {
        await api.connect();
        await waitForConnection(timeout: 10000);
      }

      final result = await api.callTool('register', {'name': agentName});
      final parsed = _parseJson(result);
      agentKey = parsed['agent_key'] as String?;
    }).toJS);

    suiteTeardown((() async {
      await safeDisconnect();
    }).toJS);

    test('CRITICAL: Admin tool MUST exist on MCP server', (() async {
      final api = getTestAPI();
      assertOk(agentKey != null, 'Should have agent key from suiteSetup');

      try {
        final adminResult = await api.callTool('admin', {
          'action': 'delete_agent',
          'agent_name': 'non-existent-agent-12345',
        });
        final adminParsed = _parseJson(adminResult);
        assertOk(
          adminParsed.containsKey('deleted') ||
              adminParsed.containsKey('error'),
          'Admin tool should return valid response',
        );
      } on Object catch (e) {
        final msg = e.toString();
        if (msg.contains('Tool admin not found') || msg.contains('-32602')) {
          throw StateError(
            'CRITICAL: Admin tool not found on MCP server!\n'
            'The VSCode extension requires the admin tool.\n'
            'Error was: $msg',
          );
        }
        if (msg.contains('NOT_FOUND:')) return;
        rethrow;
      }
    }).toJS);

    test('CRITICAL: Subscribe tool MUST exist on MCP server', (() async {
      final api = getTestAPI();

      try {
        final result = await api.callTool('subscribe', {'action': 'list'});
        final parsed = _parseJson(result);
        assertOk(
          parsed.containsKey('subscribers'),
          'Subscribe tool should return subscribers list',
        );
      } on Object catch (e) {
        final msg = e.toString();
        if (msg.contains('not found') || msg.contains('-32602')) {
          throw StateError(
            'CRITICAL: Subscribe tool not found on MCP server!\n'
            'Error was: $msg',
          );
        }
        rethrow;
      }
    }).toJS);

    test('All core tools are available', (() async {
      final api = getTestAPI();

      final result = await api.callTool('status', {});
      final parsed = _parseJson(result);
      assertOk(parsed.containsKey('agents'), 'Status should have agents');
    }).toJS);
  }).toJS);
}

@JS('JSON.parse')
external JSObject _jsonParse(String json);

Map<String, Object?> _parseJson(String json) {
  final obj = _jsonParse(json);
  final result = obj.dartify();
  return result is Map ? Map<String, Object?>.from(result) : {};
}
