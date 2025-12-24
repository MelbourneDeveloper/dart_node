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

/// Output channel for logging.
OutputChannel? _outputChannel;

/// Log a message to the output channel.
void _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  _outputChannel?.appendLine('[$timestamp] $message');
}

/// Extension entry point - called by VSCode when the extension activates.
@JS('activate')
external set _activate(JSFunction f);

/// Extension deactivation - called by VSCode when the extension deactivates.
@JS('deactivate')
external set _deactivate(JSFunction f);

/// Main entry point - sets up the extension exports.
void main() {
  _activate = _activateExtension.toJS;
  _deactivate = _deactivateExtension.toJS;
}

/// Activates the extension.
JSPromise<JSObject> _activateExtension(ExtensionContext context) =>
    _doActivate(context).then((api) => api).toJS;

Future<JSObject> _doActivate(ExtensionContext context) async {
  // Create output channel
  _outputChannel = vscode.window.createOutputChannel('Too Many Cooks');
  _outputChannel?.show(true);
  _log('Extension activating...');

  // Get configuration
  final config = vscode.workspace.getConfiguration('tooManyCooks');
  final autoConnect = config.get<JSBoolean>('autoConnect')?.toDart ?? true;

  // Create MCP client and store manager
  final client = McpClientImpl();
  _storeManager = StoreManager(client: client);

  // Create tree providers
  final agentsProvider = AgentsTreeProvider(_storeManager!);
  final locksProvider = LocksTreeProvider(_storeManager!);
  final messagesProvider = MessagesTreeProvider(_storeManager!);

  // Register tree views - store in context for disposal
  vscode.window.createTreeView(
    'tooManyCooksAgents',
    TreeViewOptions<TreeItem>(
      treeDataProvider: JSTreeDataProvider<TreeItem>(agentsProvider),
      showCollapseAll: true,
    ),
  );

  vscode.window.createTreeView(
    'tooManyCooksLocks',
    TreeViewOptions<TreeItem>(
      treeDataProvider: JSTreeDataProvider<TreeItem>(locksProvider),
    ),
  );

  vscode.window.createTreeView(
    'tooManyCooksMessages',
    TreeViewOptions<TreeItem>(
      treeDataProvider: JSTreeDataProvider<TreeItem>(messagesProvider),
    ),
  );

  // Create status bar
  final statusBar = StatusBarManager(_storeManager!, vscode.window);

  // Register commands
  _registerCommands(context, agentsProvider);

  // Auto-connect if configured
  _log('Auto-connect: $autoConnect');
  if (autoConnect) {
    _log('Attempting auto-connect...');
    try {
      await _storeManager?.connect();
      _log('Auto-connect successful');
    } on Object catch (e) {
      _log('Auto-connect failed: $e');
    }
  }

  _log('Extension activated');

  // Register disposables
  context.addSubscription(createDisposable(() {
    unawaited(_storeManager?.disconnect());
    statusBar.dispose();
    agentsProvider.dispose();
    locksProvider.dispose();
    messagesProvider.dispose();
  }));

  // Return test API
  return _createTestAPI();
}

/// Registers all extension commands.
void _registerCommands(
  ExtensionContext context,
  AgentsTreeProvider agentsProvider,
) {
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
JSObject _createTestAPI() {
  final obj = _createJSObject();
  // Return state as jsified object for JS consumption
  _setProperty(
    obj,
    'getState',
    (() {
      final state = _storeManager?.state;
      if (state == null) return null;
      return {
        'agents': state.agents.map((a) => {
          'agentName': a.agentName,
          'registeredAt': a.registeredAt,
          'lastActive': a.lastActive,
        }).toList(),
        'locks': state.locks.map((l) => {
          'filePath': l.filePath,
          'agentName': l.agentName,
          'acquiredAt': l.acquiredAt,
          'expiresAt': l.expiresAt,
          'reason': l.reason,
        }).toList(),
        'messages': state.messages.map((m) => {
          'id': m.id,
          'fromAgent': m.fromAgent,
          'toAgent': m.toAgent,
          'content': m.content,
          'createdAt': m.createdAt,
          'readAt': m.readAt,
        }).toList(),
        'plans': state.plans.map((p) => {
          'agentName': p.agentName,
          'goal': p.goal,
          'currentTask': p.currentTask,
          'updatedAt': p.updatedAt,
        }).toList(),
        'connectionStatus': state.connectionStatus.name,
      }.jsify();
    }).toJS,
  );
  return obj;
}

@JS('Object')
external JSObject _createJSObject();

@JS('Object.defineProperty')
external void _setProperty(JSObject obj, String key, JSAny? value);

/// Deactivates the extension.
void _deactivateExtension() {
  // Cleanup handled by disposables
  _log('Extension deactivating');
}
