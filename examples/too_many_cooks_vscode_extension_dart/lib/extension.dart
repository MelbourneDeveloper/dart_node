/// Too Many Cooks VSCode Extension - Dart Port
///
/// Visualizes the Too Many Cooks multi-agent coordination system.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';
import 'package:too_many_cooks_vscode_extension_dart/mcp/client.dart';
import 'package:too_many_cooks_vscode_extension_dart/state/store.dart';
import 'package:too_many_cooks_vscode_extension_dart/ui/status_bar/status_bar_manager.dart';
import 'package:too_many_cooks_vscode_extension_dart/ui/tree/agents_tree_provider.dart';
import 'package:too_many_cooks_vscode_extension_dart/ui/tree/locks_tree_provider.dart';
import 'package:too_many_cooks_vscode_extension_dart/ui/tree/messages_tree_provider.dart';
import 'package:too_many_cooks_vscode_extension_dart/ui/webview/dashboard_panel.dart';

/// Global store manager.
StoreManager? _storeManager;

/// Global tree providers for TestAPI access.
AgentsTreeProvider? _agentsProvider;
LocksTreeProvider? _locksProvider;
MessagesTreeProvider? _messagesProvider;

/// Output channel for logging.
OutputChannel? _outputChannel;

/// Log messages for test access.
final List<String> _logMessages = [];

/// Log a message to the output channel.
void _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  final fullMessage = '[$timestamp] $message';
  _outputChannel?.appendLine(fullMessage);
  _logMessages.add(fullMessage);
}

/// Extension entry point - called by VSCode when the extension activates.
@JS('activate')
external set _activate(JSFunction f);

/// Extension deactivation - called by VSCode when the extension deactivates.
@JS('deactivate')
external set _deactivate(JSFunction f);

/// Test server path set by test harness via globalThis.
@JS('globalThis._tooManyCooksTestServerPath')
external JSString? get _testServerPath;

/// Test server path from environment variable (set in .vscode-test.mjs).
@JS('process.env.TMC_TEST_SERVER_PATH')
external JSString? get _envTestServerPath;

/// Main entry point - sets up the extension exports.
void main() {
  _activate = _activateExtension.toJS;
  _deactivate = _deactivateExtension.toJS;
}

/// Activates the extension - returns the TestAPI directly (synchronous).
JSObject _activateExtension(ExtensionContext context) =>
    _doActivateSync(context);

/// Synchronous activation to avoid dart2js async Promise issues.
JSObject _doActivateSync(ExtensionContext context) {
  // Create output channel
  _outputChannel = vscode.window.createOutputChannel('Too Many Cooks');
  _outputChannel?.show(true);
  _log('Extension activating...');

  // Debug: log to console to verify activation runs
  _consoleLog('DART EXTENSION: _doActivateSync starting...');

  // Get configuration
  final config = vscode.workspace.getConfiguration('tooManyCooks');
  final autoConnect = config.get<JSBoolean>('autoConnect')?.toDart ?? true;

  // Check for test server path (set by test harness via globalThis or env var)
  final serverPath = _testServerPath?.toDart ?? _envTestServerPath?.toDart;
  if (serverPath != null) {
    _log('TEST MODE: Using local server at $serverPath');
  } else {
    _log('Using npx too-many-cooks');
  }

  // Create MCP client and store manager
  final client = McpClientImpl(serverPath: serverPath);
  _storeManager = StoreManager(client: client);

  // Create tree providers and store globally for TestAPI
  _agentsProvider = AgentsTreeProvider(_storeManager!);
  _locksProvider = LocksTreeProvider(_storeManager!);
  _messagesProvider = MessagesTreeProvider(_storeManager!);

  // Register tree views - store in context for disposal
  vscode.window.createTreeView(
    'tooManyCooksAgents',
    TreeViewOptions<TreeItem>(
      treeDataProvider: JSTreeDataProvider<TreeItem>(_agentsProvider!),
      showCollapseAll: true,
    ),
  );

  vscode.window.createTreeView(
    'tooManyCooksLocks',
    TreeViewOptions<TreeItem>(
      treeDataProvider: JSTreeDataProvider<TreeItem>(_locksProvider!),
    ),
  );

  vscode.window.createTreeView(
    'tooManyCooksMessages',
    TreeViewOptions<TreeItem>(
      treeDataProvider: JSTreeDataProvider<TreeItem>(_messagesProvider!),
    ),
  );

  // Create status bar
  final statusBar = StatusBarManager(_storeManager!, vscode.window);

  // Register commands
  _registerCommands(context);

  // Auto-connect if configured (non-blocking to avoid activation hang)
  _log('Auto-connect: $autoConnect');
  if (autoConnect) {
    _log('Attempting auto-connect...');
    unawaited(_storeManager?.connect().then((_) {
      _log('Auto-connect successful');
    }).catchError((Object e) {
      _log('Auto-connect failed: $e');
    }));
  }

  _log('Extension activated');

  // Register disposables
  context.addSubscription(createDisposable(() {
    unawaited(_storeManager?.disconnect());
    statusBar.dispose();
    _agentsProvider?.dispose();
    _locksProvider?.dispose();
    _messagesProvider?.dispose();
  }));

  // Return test API
  _consoleLog('DART EXTENSION: Creating TestAPI...');
  final api = _createTestAPI();
  _consoleLog('DART EXTENSION: TestAPI created, returning...');

  // Debug: check if the object has properties
  _consoleLogObj('DART EXTENSION: TestAPI object:', api);

  return api;
}

/// Registers all extension commands.
void _registerCommands(ExtensionContext context) {
  // Connect command
  final connectCmd = vscode.commands.registerCommand(
    'tooManyCooks.connect',
    () async {
      _log('Connect command triggered');
      try {
        await _storeManager?.connect();
        _log('Connected successfully');
        vscode.window
            .showInformationMessage('Connected to Too Many Cooks server');
      } on Object catch (e) {
        _log('Connection failed: $e');
        vscode.window.showErrorMessage('Failed to connect: $e');
      }
    },
  );
  context.addSubscription(connectCmd);

  // Disconnect command
  final disconnectCmd = vscode.commands.registerCommand(
    'tooManyCooks.disconnect',
    () async {
      await _storeManager?.disconnect();
      vscode.window
          .showInformationMessage('Disconnected from Too Many Cooks server');
    },
  );
  context.addSubscription(disconnectCmd);

  // Refresh command
  final refreshCmd = vscode.commands.registerCommand(
    'tooManyCooks.refresh',
    () async {
      try {
        await _storeManager?.refreshStatus();
      } on Object catch (e) {
        vscode.window.showErrorMessage('Failed to refresh: $e');
      }
    },
  );
  context.addSubscription(refreshCmd);

  // Dashboard command
  final dashboardCmd = vscode.commands.registerCommand(
    'tooManyCooks.showDashboard',
    () => DashboardPanel.createOrShow(vscode.window, _storeManager!),
  );
  context.addSubscription(dashboardCmd);

  // Delete lock command
  final deleteLockCmd = vscode.commands.registerCommandWithArgs<TreeItem>(
    'tooManyCooks.deleteLock',
    (item) async {
      final filePath = _getFilePathFromItem(item);
      if (filePath == null) {
        vscode.window.showErrorMessage('No lock selected');
        return;
      }
      final confirm = await vscode.window
          .showWarningMessage(
            'Force release lock on $filePath?',
            MessageOptions(modal: true),
            'Release',
          )
          .toDart;
      if (confirm?.toDart != 'Release') return;
      try {
        await _storeManager?.forceReleaseLock(filePath);
        _log('Force released lock: $filePath');
        vscode.window.showInformationMessage('Lock released: $filePath');
      } on Object catch (e) {
        _log('Failed to release lock: $e');
        vscode.window.showErrorMessage('Failed to release lock: $e');
      }
    },
  );
  context.addSubscription(deleteLockCmd);

  // Delete agent command
  final deleteAgentCmd = vscode.commands.registerCommandWithArgs<TreeItem>(
    'tooManyCooks.deleteAgent',
    (item) async {
      final agentName = _getAgentNameFromItem(item);
      if (agentName == null) {
        vscode.window.showErrorMessage('No agent selected');
        return;
      }
      final confirm = await vscode.window
          .showWarningMessage(
            'Remove agent "$agentName"? This will release all their locks.',
            MessageOptions(modal: true),
            'Remove',
          )
          .toDart;
      if (confirm?.toDart != 'Remove') return;
      try {
        await _storeManager?.deleteAgent(agentName);
        _log('Removed agent: $agentName');
        vscode.window.showInformationMessage('Agent removed: $agentName');
      } on Object catch (e) {
        _log('Failed to remove agent: $e');
        vscode.window.showErrorMessage('Failed to remove agent: $e');
      }
    },
  );
  context.addSubscription(deleteAgentCmd);

  // Send message command
  final sendMessageCmd = vscode.commands.registerCommandWithArgs<TreeItem?>(
    'tooManyCooks.sendMessage',
    (item) async {
      var toAgent = item != null ? _getAgentNameFromItem(item) : null;

      // If no target, show quick pick to select one
      if (toAgent == null) {
        final response = await _storeManager?.callTool('status', {});
        if (response == null) {
          vscode.window.showErrorMessage('Not connected to server');
          return;
        }
        // Parse and show agent picker
        final agents = _storeManager?.state.agents ?? [];
        final agentNames = [
          '* (broadcast to all)',
          ...agents.map((a) => a.agentName),
        ];
        final pickedJs = await vscode.window
            .showQuickPick(
              agentNames.map((n) => n.toJS).toList().toJS,
              QuickPickOptions(placeHolder: 'Select recipient agent'),
            )
            .toDart;
        if (pickedJs == null) return;
        final picked = pickedJs.toDart;
        toAgent = picked == '* (broadcast to all)' ? '*' : picked;
      }

      // Get sender name
      final fromAgentJs = await vscode.window
          .showInputBox(
            InputBoxOptions(
              prompt: 'Your agent name (sender)',
              placeHolder: 'e.g., vscode-user',
              value: 'vscode-user',
            ),
          )
          .toDart;
      if (fromAgentJs == null) return;
      final fromAgent = fromAgentJs.toDart;

      // Get message content
      final contentJs = await vscode.window
          .showInputBox(
            InputBoxOptions(
              prompt: 'Message to $toAgent',
              placeHolder: 'Enter your message...',
            ),
          )
          .toDart;
      if (contentJs == null) return;
      final content = contentJs.toDart;

      try {
        await _storeManager?.sendMessage(fromAgent, toAgent, content);
        final preview =
            content.length > 50 ? '${content.substring(0, 50)}...' : content;
        vscode.window
            .showInformationMessage('Message sent to $toAgent: "$preview"');
        _log('Message sent from $fromAgent to $toAgent: $content');
      } on Object catch (e) {
        _log('Failed to send message: $e');
        vscode.window.showErrorMessage('Failed to send message: $e');
      }
    },
  );
  context.addSubscription(sendMessageCmd);
}

/// Extracts file path from a tree item.
String? _getFilePathFromItem(TreeItem item) =>
    _getCustomProperty(item, 'filePath');

/// Extracts agent name from a tree item.
String? _getAgentNameFromItem(TreeItem item) =>
    _getCustomProperty(item, 'agentName');

@JS()
external String? _getCustomProperty(JSObject item, String property);

/// Creates the test API object for integration tests.
/// This matches the TypeScript TestAPI interface exactly.
JSObject _createTestAPI() {
  final api = _TestAPIImpl();
  return api.toJS();
}

/// TestAPI implementation that matches the TypeScript interface.
class _TestAPIImpl {
  // State getters
  List<Map<String, Object?>> getAgents() => _storeManager?.state.agents
          .map((a) => {
                'agentName': a.agentName,
                'registeredAt': a.registeredAt,
                'lastActive': a.lastActive,
              })
          .toList() ??
      [];

  List<Map<String, Object?>> getLocks() => _storeManager?.state.locks
          .map((l) => {
                'filePath': l.filePath,
                'agentName': l.agentName,
                'acquiredAt': l.acquiredAt,
                'expiresAt': l.expiresAt,
                'reason': l.reason,
              })
          .toList() ??
      [];

  List<Map<String, Object?>> getMessages() => _storeManager?.state.messages
          .map((m) => {
                'id': m.id,
                'fromAgent': m.fromAgent,
                'toAgent': m.toAgent,
                'content': m.content,
                'createdAt': m.createdAt,
                'readAt': m.readAt,
              })
          .toList() ??
      [];

  List<Map<String, Object?>> getPlans() => _storeManager?.state.plans
          .map((p) => {
                'agentName': p.agentName,
                'goal': p.goal,
                'currentTask': p.currentTask,
                'updatedAt': p.updatedAt,
              })
          .toList() ??
      [];

  String getConnectionStatus() =>
      _storeManager?.state.connectionStatus.name ?? 'disconnected';

  // Computed getters
  int getAgentCount() => _storeManager?.state.agents.length ?? 0;
  int getLockCount() => _storeManager?.state.locks.length ?? 0;
  int getMessageCount() => _storeManager?.state.messages.length ?? 0;
  int getUnreadMessageCount() =>
      _storeManager?.state.messages.where((m) => m.readAt == null).length ?? 0;

  List<Map<String, Object?>> getAgentDetails() {
    final state = _storeManager?.state;
    if (state == null) return [];
    return state.agents.map((agent) {
      final locks =
          state.locks.where((l) => l.agentName == agent.agentName).toList();
      final plan = state.plans
          .where((p) => p.agentName == agent.agentName)
          .firstOrNull;
      final sentMessages =
          state.messages.where((m) => m.fromAgent == agent.agentName).toList();
      final receivedMessages = state.messages
          .where((m) => m.toAgent == agent.agentName || m.toAgent == '*')
          .toList();
      return {
        'agent': {
          'agentName': agent.agentName,
          'registeredAt': agent.registeredAt,
          'lastActive': agent.lastActive,
        },
        'locks': locks
            .map((l) => {
                  'filePath': l.filePath,
                  'agentName': l.agentName,
                  'acquiredAt': l.acquiredAt,
                  'expiresAt': l.expiresAt,
                  'reason': l.reason,
                })
            .toList(),
        'plan': plan != null
            ? {
                'agentName': plan.agentName,
                'goal': plan.goal,
                'currentTask': plan.currentTask,
                'updatedAt': plan.updatedAt,
              }
            : null,
        'sentMessages': sentMessages
            .map((m) => {
                  'id': m.id,
                  'fromAgent': m.fromAgent,
                  'toAgent': m.toAgent,
                  'content': m.content,
                  'createdAt': m.createdAt,
                  'readAt': m.readAt,
                })
            .toList(),
        'receivedMessages': receivedMessages
            .map((m) => {
                  'id': m.id,
                  'fromAgent': m.fromAgent,
                  'toAgent': m.toAgent,
                  'content': m.content,
                  'createdAt': m.createdAt,
                  'readAt': m.readAt,
                })
            .toList(),
      };
    }).toList();
  }

  // Store actions
  Future<void> connect() async {
    _consoleLog('TestAPI.connect() called');
    try {
      await _storeManager?.connect();
      _consoleLog('TestAPI.connect() completed successfully');
    } catch (e) {
      _consoleLog('TestAPI.connect() failed: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _consoleLog('TestAPI.disconnect() called');
    await _storeManager?.disconnect();
    _consoleLog('TestAPI.disconnect() completed');
  }
  Future<void> refreshStatus() async => _storeManager?.refreshStatus();
  bool isConnected() => _storeManager?.isConnected ?? false;
  bool isConnecting() => _storeManager?.isConnecting ?? false;

  Future<String> callTool(String name, Map<String, Object?> args) async =>
      await _storeManager?.callTool(name, args) ?? '';

  Future<void> forceReleaseLock(String filePath) async =>
      _storeManager?.forceReleaseLock(filePath);

  Future<void> deleteAgent(String agentName) async =>
      _storeManager?.deleteAgent(agentName);

  Future<void> sendMessage(
    String fromAgent,
    String toAgent,
    String content,
  ) async =>
      _storeManager?.sendMessage(fromAgent, toAgent, content);

  // Tree view queries
  int getLockTreeItemCount() {
    if (_locksProvider == null) return 0;
    final categories = _locksProvider!.getChildren() ?? [];
    var count = 0;
    for (final cat in categories) {
      final children = _locksProvider!.getChildren(cat) ?? [];
      count += children.length;
    }
    return count;
  }

  int getMessageTreeItemCount() {
    if (_messagesProvider == null) return 0;
    final items = _messagesProvider!.getChildren() ?? [];
    // Filter out "No messages" placeholder
    return items.where((item) => item.label != 'No messages').length;
  }

  // Tree snapshots
  List<Map<String, Object?>> getAgentsTreeSnapshot() {
    if (_agentsProvider == null) return [];
    final items = _agentsProvider!.getChildren() ?? [];
    return items.map(_toSnapshot).toList();
  }

  List<Map<String, Object?>> getLocksTreeSnapshot() {
    if (_locksProvider == null) return [];
    final items = _locksProvider!.getChildren() ?? [];
    return items.map(_toSnapshot).toList();
  }

  List<Map<String, Object?>> getMessagesTreeSnapshot() {
    if (_messagesProvider == null) return [];
    final items = _messagesProvider!.getChildren() ?? [];
    return items.map(_toSnapshot).toList();
  }

  Map<String, Object?> _toSnapshot(TreeItem item) {
    final label = item.label;
    final snapshot = <String, Object?>{'label': label};
    final desc = item.description;
    if (desc != null) {
      snapshot['description'] = desc;
    }
    // Get children if this is an agent item
    if (_agentsProvider != null) {
      final children = _agentsProvider!.getChildren(item);
      if (children != null && children.isNotEmpty) {
        snapshot['children'] = children.map(_toSnapshot).toList();
      }
    }
    return snapshot;
  }

  // Find specific items
  Map<String, Object?>? findAgentInTree(String agentName) {
    final snapshot = getAgentsTreeSnapshot();
    return _findInTree(snapshot, (item) => item['label'] == agentName);
  }

  Map<String, Object?>? findLockInTree(String filePath) {
    final snapshot = getLocksTreeSnapshot();
    return _findInTree(snapshot, (item) => item['label'] == filePath);
  }

  Map<String, Object?>? findMessageInTree(String content) {
    final snapshot = getMessagesTreeSnapshot();
    return _findInTree(snapshot, (item) {
      final desc = item['description'];
      return desc is String && desc.contains(content);
    });
  }

  Map<String, Object?>? _findInTree(
    List<Map<String, Object?>> items,
    bool Function(Map<String, Object?>) predicate,
  ) {
    for (final item in items) {
      if (predicate(item)) return item;
      final children = item['children'];
      if (children is List<Map<String, Object?>>) {
        final found = _findInTree(children, predicate);
        if (found != null) return found;
      }
    }
    return null;
  }

  // Logging
  List<String> getLogMessages() => List.unmodifiable(_logMessages);

  /// Convert to JS object for extension exports.
  JSObject toJS() {
    final obj = _createJSObject();
    // State getters
    _setProp(obj, 'getAgents', (() => getAgents().jsify()).toJS);
    _setProp(obj, 'getLocks', (() => getLocks().jsify()).toJS);
    _setProp(obj, 'getMessages', (() => getMessages().jsify()).toJS);
    _setProp(obj, 'getPlans', (() => getPlans().jsify()).toJS);
    _setProp(obj, 'getConnectionStatus', getConnectionStatus.toJS);

    // Computed getters
    _setProp(obj, 'getAgentCount', getAgentCount.toJS);
    _setProp(obj, 'getLockCount', getLockCount.toJS);
    _setProp(obj, 'getMessageCount', getMessageCount.toJS);
    _setProp(obj, 'getUnreadMessageCount', getUnreadMessageCount.toJS);
    _setProp(obj, 'getAgentDetails', (() => getAgentDetails().jsify()).toJS);

    // Store actions (async)
    _setProp(obj, 'connect', (() => connect().toJS).toJS);
    _setProp(obj, 'disconnect', (() => disconnect().toJS).toJS);
    _setProp(obj, 'refreshStatus', (() => refreshStatus().toJS).toJS);
    _setProp(obj, 'isConnected', isConnected.toJS);
    _setProp(obj, 'isConnecting', isConnecting.toJS);
    _setProp(
      obj,
      'callTool',
      ((JSString name, JSObject args) => callTool(
            name.toDart,
            (args.dartify() ?? {}) as Map<String, Object?>,
          ).toJS).toJS,
    );
    _setProp(
      obj,
      'forceReleaseLock',
      ((JSString filePath) => forceReleaseLock(filePath.toDart).toJS).toJS,
    );
    _setProp(
      obj,
      'deleteAgent',
      ((JSString agentName) => deleteAgent(agentName.toDart).toJS).toJS,
    );
    _setProp(
      obj,
      'sendMessage',
      ((JSString fromAgent, JSString toAgent, JSString content) =>
          sendMessage(
            fromAgent.toDart,
            toAgent.toDart,
            content.toDart,
          ).toJS).toJS,
    );

    // Tree view queries
    _setProp(obj, 'getLockTreeItemCount', getLockTreeItemCount.toJS);
    _setProp(obj, 'getMessageTreeItemCount', getMessageTreeItemCount.toJS);

    // Tree snapshots
    _setProp(
      obj,
      'getAgentsTreeSnapshot',
      (() => getAgentsTreeSnapshot().jsify()).toJS,
    );
    _setProp(
      obj,
      'getLocksTreeSnapshot',
      (() => getLocksTreeSnapshot().jsify()).toJS,
    );
    _setProp(
      obj,
      'getMessagesTreeSnapshot',
      (() => getMessagesTreeSnapshot().jsify()).toJS,
    );

    // Find in tree
    _setProp(
      obj,
      'findAgentInTree',
      ((JSString agentName) => findAgentInTree(agentName.toDart).jsify()).toJS,
    );
    _setProp(
      obj,
      'findLockInTree',
      ((JSString filePath) => findLockInTree(filePath.toDart).jsify()).toJS,
    );
    _setProp(
      obj,
      'findMessageInTree',
      ((JSString content) => findMessageInTree(content.toDart).jsify()).toJS,
    );

    // Logging
    _setProp(obj, 'getLogMessages', (() => getLogMessages().jsify()).toJS);

    return obj;
  }
}

/// Creates a new empty JS object using eval to get a literal {}.
/// This is safe since we're just creating an empty object.
@JS('eval')
external JSObject _eval(String code);

JSObject _createJSObject() => _eval('({})');

/// Sets a property on a JS object using Reflect.set.
@JS('Reflect.set')
external void _reflectSet(JSObject target, JSString key, JSAny? value);

/// Console.log for debugging.
@JS('console.log')
external void _consoleLog(String message);

/// Console.log with object for debugging.
@JS('console.log')
external void _consoleLogObj(String message, JSObject obj);

void _setProp(JSObject target, String key, JSAny? value) =>
    _reflectSet(target, key.toJS, value);

/// Deactivates the extension.
void _deactivateExtension() {
  // Cleanup handled by disposables
  _log('Extension deactivating');
}
