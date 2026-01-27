/// Treeview Bug Tests
///
/// Tests for treeview rendering bugs identified from screenshot analysis:
/// 1. Delete agent dialog shows "(empty)" as a second button option
///    because showWarningMessage passes empty string for unused item2 param
/// 2. Agent tree items must have correct label and description separation
///    (label and description must not overlap or be garbled)
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'test_helpers.dart';

@JS('console.log')
external void _log(String msg);

@JS('Date.now')
external int _dateNow();

// JS interop helpers.
@JS('Reflect.get')
external JSAny? _reflectGet(JSObject target, JSString key);

@JS('Reflect.set')
external void _reflectSetRaw(JSObject target, JSString key, JSAny? value);

/// eval for creating JS functions.
@JS('eval')
external JSAny _eval(String code);

/// globalThis.vscode.window
@JS('globalThis.vscode.window')
external JSObject get _globalVscodeWindow;

/// Get the label property from a tree item snapshot.
String _getLabel(JSObject item) {
  final label = _reflectGet(item, 'label'.toJS);
  if (label == null || label.isUndefinedOrNull) return '';
  if (label.typeofEquals('string')) return (label as JSString).toDart;
  return label.dartify()?.toString() ?? '';
}

/// Get the description property from a tree item snapshot.
String _getDescription(JSObject item) {
  final desc = _reflectGet(item, 'description'.toJS);
  if (desc == null || desc.isUndefinedOrNull) return '';
  if (desc.typeofEquals('string')) return (desc as JSString).toDart;
  return desc.dartify()?.toString() ?? '';
}

/// Get children from a tree item snapshot.
JSArray<JSObject>? _getChildren(JSObject item) {
  final value = _reflectGet(item, 'children'.toJS);
  if (value == null || value.isUndefinedOrNull) return null;
  if (value.typeofEquals('object') && value.instanceOfString('Array')) {
    return value as JSArray<JSObject>;
  }
  return null;
}

void main() {
  _log('[TREEVIEW BUGS TEST] main() called');

  // Ensure any dialog mocks from previous tests are restored.
  restoreDialogMocks();

  suite(
    'Treeview Bug: Delete Agent Dialog "(empty)" Button',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          _log('[TREEVIEW BUGS] suiteSetup - waiting for extension activation');
          await waitForExtensionActivation();
        }),
      );

      test(
        'BUG: showWarningMessage must NOT pass empty string as button item',
        asyncTest(() async {
          _log('[TREEVIEW BUGS] Running: empty button test');

          // The bug: Window.showWarningMessage passes `item2 ?? ''` when
          // item2 is null, causing VSCode to render an "(empty)" button.
          //
          // We test the DART WRAPPER directly (not via extension command)
          // because this test is compiled at -O0 which preserves all args,
          // while the extension is compiled at -O2 which may optimize them.
          //
          // We mock vscode.window.showWarningMessage at the JS level to
          // capture args, then call the Dart wrapper with only item1 (no
          // item2). If the wrapper passes an empty string, we catch it.

          final captureMock = _eval(
            '(function() { '
            'var captured = []; '
            'var mock = async function() { '
            '  captured.push(Array.from(arguments)); '
            '  return "Remove"; '
            '}; '
            'mock.captured = captured; '
            'return mock; '
            '})()',
          );

          final window = _globalVscodeWindow;
          final original = _reflectGet(window, 'showWarningMessage'.toJS);

          _reflectSetRaw(
            window,
            'showWarningMessage'.toJS,
            captureMock,
          );

          try {
            // Call the Dart wrapper directly with only item1, no item2.
            // This is the exact call pattern used by deleteAgent/deleteLock.
            await vscode.window
                .showWarningMessage(
                  'Test message',
                  MessageOptions(modal: true),
                  'Remove',
                )
                .toDart;

            // Get captured arguments
            final capturedCallsRaw = _reflectGet(
              captureMock as JSObject,
              'captured'.toJS,
            );
            if (capturedCallsRaw == null) {
              assertFail('captured array must exist on mock');
              return;
            }
            final capturedCalls = capturedCallsRaw as JSArray<JSAny>;

            assertOk(
              capturedCalls.length > 0,
              'showWarningMessage should have been called',
            );

            final firstCall = capturedCalls[0] as JSArray<JSAny?>;
            final argCount = firstCall.length;

            _log(
              '[TREEVIEW BUGS] showWarningMessage called with $argCount args',
            );

            for (var i = 0; i < argCount; i++) {
              final arg = firstCall[i];
              final str = arg.dartify()?.toString() ?? 'undefined';
              _log('[TREEVIEW BUGS] arg[$i]: $str');
            }

            // BUG CHECK: Must have exactly 3 args (message, options, item1).
            // If 4 args with empty string, that's the bug.
            var hasEmptyStringArg = false;
            for (var i = 0; i < argCount; i++) {
              final arg = firstCall[i];
              if (arg != null &&
                  !arg.isUndefinedOrNull &&
                  arg.typeofEquals('string')) {
                final str = (arg as JSString).toDart;
                if (str.isEmpty) {
                  hasEmptyStringArg = true;
                  _log(
                    '[TREEVIEW BUGS] FOUND EMPTY STRING at index $i - '
                    'this causes the "(empty)" button!',
                  );
                }
              }
            }

            assertEqual(
              hasEmptyStringArg,
              false,
              'BUG: showWarningMessage must NOT receive empty string as '
              'button item. Empty string causes VSCode to show "(empty)" '
              'button in dialog. Found $argCount args in call.',
            );
          } finally {
            if (original != null) {
              _reflectSetRaw(
                window,
                'showWarningMessage'.toJS,
                original,
              );
            }
          }

          _log('[TREEVIEW BUGS] empty button test completed');
        }),
      );
    }),
  );

  suite(
    'Treeview Bug: Agent Label and Description Integrity',
    syncTest(() {
      var agentKey = '';
      final testId = _dateNow();
      final agentName = 'treeview-test-agent-$testId';

      suiteSetup(
        asyncTest(() async {
          _log('[TREEVIEW LABEL] suiteSetup');
          await waitForExtensionActivation();
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
          _log('[TREEVIEW LABEL] suiteTeardown');
          await safeDisconnect();
          cleanDatabase();
        }),
      );

      test(
        'Agent label must exactly match agent name (no garbled text)',
        asyncTest(() async {
          _log('[TREEVIEW LABEL] Running: agent label integrity test');
          final api = getTestAPI();

          await waitForAgentInTree(api, agentName);

          final agentItem = api.findAgentInTree(agentName);
          assertOk(agentItem != null, 'Agent must appear in tree');

          // The label must be EXACTLY the agent name - no garbled text
          final label = _getLabel(agentItem!);
          assertEqual(
            label,
            agentName,
            'Agent label must exactly match agent name. '
            'Got: "$label", expected: "$agentName". '
            'Garbled text indicates label/description overlap bug.',
          );

          _log('[TREEVIEW LABEL] agent label integrity test PASSED');
        }),
      );

      test(
        'Agent description must be valid format (no overlap with label)',
        asyncTest(() async {
          _log('[TREEVIEW LABEL] Running: agent description integrity test');
          final api = getTestAPI();

          final agentItem = api.findAgentInTree(agentName);
          assertOk(agentItem != null, 'Agent must appear in tree');

          final label = _getLabel(agentItem!);
          final description = _getDescription(agentItem);

          // Description must be "idle" or match pattern like
          // "N lock(s), M msg(s)"
          final validDescriptionPattern = RegExp(
            r'^idle$|^\d+ locks?$|^\d+ msgs?$|^\d+ locks?, \d+ msgs?$',
          );

          assertOk(
            validDescriptionPattern.hasMatch(description),
            'Agent description must match valid format. '
            'Got: "$description". '
            'Valid formats: "idle", "N lock(s)", "N msg(s)", '
            '"N lock(s), M msg(s)".',
          );

          // Label must NOT contain description text
          assertOk(
            !label.contains(description) || description == 'idle',
            'Label "$label" must not contain description text "$description". '
            'This indicates text overlap/garble bug.',
          );

          // Description must NOT contain label text
          assertOk(
            !description.contains(label),
            'Description "$description" must not contain label "$label". '
            'This indicates text overlap/garble bug.',
          );

          _log('[TREEVIEW LABEL] agent description integrity test PASSED');
        }),
      );

      test(
        'Agent with messages shows correct count in description',
        asyncTest(() async {
          _log('[TREEVIEW LABEL] Running: agent message count test');
          final api = getTestAPI();

          // Send a message from the agent
          final msgArgs = createArgs({
            'action': 'send',
            'agent_name': agentName,
            'agent_key': agentKey,
            'to_agent': '*',
            'content': 'Treeview label test message',
          });
          await api.callTool('message', msgArgs).toDart;

          // Wait for the message to appear
          await waitForMessageInTree(api, 'Treeview label test');

          // Refresh and check the agent's description
          final agentItem = api.findAgentInTree(agentName);
          assertOk(agentItem != null, 'Agent must appear in tree');

          final description = _getDescription(agentItem!);
          final label = _getLabel(agentItem);

          // Description should now mention messages
          assertOk(
            description.contains('msg'),
            'Agent description should show message count after sending. '
            'Got: "$description".',
          );

          // Label must still be exactly the agent name
          assertEqual(
            label,
            agentName,
            'Agent label must still be agent name after sending message. '
            'Got: "$label".',
          );

          _log('[TREEVIEW LABEL] agent message count test PASSED');
        }),
      );

      test(
        'Agent children have correct label/description separation',
        asyncTest(() async {
          _log('[TREEVIEW LABEL] Running: agent children integrity test');
          final api = getTestAPI();

          // Acquire a lock to add children
          final lockArgs = createArgs({
            'action': 'acquire',
            'file_path': '/treeview/test/file.dart',
            'agent_name': agentName,
            'agent_key': agentKey,
            'reason': 'testing treeview',
          });
          await api.callTool('lock', lockArgs).toDart;

          await waitForLockInTree(api, '/treeview/test/file.dart');

          // Get the agents tree snapshot to check children
          final snapshot = api.getAgentsTreeSnapshot();
          JSObject? ourAgent;
          for (var i = 0; i < snapshot.length; i++) {
            if (_getLabel(snapshot[i]) == agentName) {
              ourAgent = snapshot[i];
              break;
            }
          }
          assertOk(ourAgent != null, 'Agent must be in tree snapshot');

          final children = _getChildren(ourAgent!);
          assertOk(
            children != null && children.length > 0,
            'Agent must have children (lock + messages)',
          );

          // Check each child item
          for (var i = 0; i < children!.length; i++) {
            final child = children[i];
            final childLabel = _getLabel(child);
            final childDesc = _getDescription(child);

            // Label must not be empty
            assertOk(
              childLabel.isNotEmpty,
              'Child item label must not be empty (index $i)',
            );

            // Label and description must not contain garbled/overlapping text
            // A garbled label would contain characters from the description
            // mixed in (e.g., "techdoc-buirider m8gaasgs" instead of clean
            // "techdoc-builder" with "18 msgs" separate)
            if (childDesc.isNotEmpty) {
              // Check that label doesn't contain description-like patterns
              // unless it's intentional (like "Goal: xxx")
              final isGoalItem = childLabel.startsWith('Goal:');
              final isMessageItem = childLabel == 'Messages';
              if (!isGoalItem && !isMessageItem) {
                // For lock items, label should be a file path
                assertOk(
                  childLabel.startsWith('/') || childLabel.contains('.'),
                  'Lock child label should be a file path. '
                  'Got: "$childLabel".',
                );
              }
            }
          }

          // Clean up lock
          final releaseArgs = createArgs({
            'action': 'release',
            'file_path': '/treeview/test/file.dart',
            'agent_name': agentName,
            'agent_key': agentKey,
          });
          await api.callTool('lock', releaseArgs).toDart;

          _log('[TREEVIEW LABEL] agent children integrity test PASSED');
        }),
      );
    }),
  );

  _log('[TREEVIEW BUGS TEST] main() completed');
}
