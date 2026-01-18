/// Test extension entry point for dart_node_vsix package.
///
/// This extension exercises all the APIs in dart_node_vsix to ensure
/// they work correctly in a real VSCode Extension Host environment.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';
import 'package:dart_node_vsix/src/js_helpers.dart' as js;

// ignore: unused_import - used by tests to access TestAPI type
import 'package:dart_node_vsix/test_api_types.dart';

/// Log messages for testing.
final List<String> _logMessages = [];

/// Status bar item for testing.
StatusBarItem? _statusBarItem;

/// Output channel for testing.
OutputChannel? _outputChannel;

/// Tree data provider for testing.
_TestTreeDataProvider? _treeProvider;

/// Test disposables.
final Map<String, bool> _disposedState = {};

/// Log a message.
void _log(String msg) {
  _logMessages.add(msg);
  js.consoleLog('[VSIX TEST] $msg');
}

// Wrapper functions for JS interop (can't use tearoffs with closures).
JSArray<JSString> _getLogMessages() =>
    _logMessages.map((m) => m.toJS).toList().toJS;

String _getStatusBarText() => _statusBarItem?.text ?? '';

String _getOutputChannelName() => _outputChannel?.name ?? '';

int _getTreeItemCount() => _treeProvider?.items.length ?? 0;

void _fireTreeChange() => _treeProvider?.fireChange();

TreeItem _createTestTreeItem(String label) => TreeItem(label);

bool _wasDisposed(String name) => _disposedState[name] ?? false;

void _registerDisposable(String name) => _disposedState[name] = false;

void _disposeByName(String name) => _disposedState[name] = true;

/// Create the test API.
JSObject _createTestAPI() {
  final obj = js.evalCreateObject('({})');

  js.reflectSet(obj, 'getLogMessages', _getLogMessages.toJS);
  js.reflectSet(obj, 'getStatusBarText', _getStatusBarText.toJS);
  js.reflectSet(obj, 'getOutputChannelName', _getOutputChannelName.toJS);
  js.reflectSet(obj, 'getTreeItemCount', _getTreeItemCount.toJS);
  js.reflectSet(obj, 'fireTreeChange', _fireTreeChange.toJS);
  js.reflectSet(obj, 'createTestTreeItem', _createTestTreeItem.toJS);
  js.reflectSet(obj, 'wasDisposed', _wasDisposed.toJS);
  js.reflectSet(obj, 'registerDisposable', _registerDisposable.toJS);
  js.reflectSet(obj, 'disposeByName', _disposeByName.toJS);

  return obj;
}

/// Test tree data provider.
class _TestTreeDataProvider extends TreeDataProvider<TreeItem> {
  final EventEmitter<TreeItem?> _onDidChangeTreeData =
      EventEmitter<TreeItem?>();
  final List<TreeItem> items = [];

  @override
  Event<TreeItem?> get onDidChangeTreeData => _onDidChangeTreeData.event;

  @override
  TreeItem getTreeItem(TreeItem element) => element;

  @override
  List<TreeItem>? getChildren([TreeItem? element]) {
    if (element != null) return null;
    return items;
  }

  void addItem(String label) {
    items.add(TreeItem(label));
    fireChange();
  }

  void fireChange() {
    _onDidChangeTreeData.fire(null);
  }

  void dispose() {
    _onDidChangeTreeData.dispose();
  }
}

/// Activates the test extension.
@JS('activate')
external set _activate(JSFunction fn);

/// Deactivates the test extension.
@JS('deactivate')
external set _deactivate(JSFunction fn);

/// Extension activation.
Future<JSObject> activate(ExtensionContext context) async {
  _log('Extension activating...');

  // Test output channel
  _outputChannel = vscode.window.createOutputChannel('VSIX Test');
  _outputChannel!.appendLine('Test extension activated');
  _log('Output channel created: ${_outputChannel!.name}');

  // Test status bar item
  _statusBarItem = vscode.window.createStatusBarItem(
    StatusBarAlignment.left.value,
    100,
  );
  _statusBarItem!.text = r'$(beaker) VSIX Test';
  _statusBarItem!.tooltip = 'dart_node_vsix test extension';
  _statusBarItem!.show();
  _log('Status bar item created');

  // Test command registration
  final cmd = vscode.commands.registerCommand(
    'dartNodeVsix.test',
    _onTestCommand,
  );
  context.addSubscription(cmd);
  _log('Command registered: dartNodeVsix.test');

  // Test tree view
  _treeProvider = _TestTreeDataProvider();
  _treeProvider!.addItem('Test Item 1');
  _treeProvider!.addItem('Test Item 2');
  _treeProvider!.addItem('Test Item 3');

  final treeView = vscode.window.createTreeView(
    'dartNodeVsix.testTree',
    TreeViewOptions(treeDataProvider: JSTreeDataProvider(_treeProvider!)),
  );
  // ignore: unnecessary_lambdas - can't tearoff external extension type members
  context.addSubscription(Disposable.fromFunction(() => treeView.dispose()));
  _log('Tree view created with ${_treeProvider!.items.length} items');

  _log('Extension activated');
  return _createTestAPI();
}

void _onTestCommand() {
  vscode.window.showInformationMessage('dart_node_vsix test command!');
  _log('Test command executed');
}

/// Extension deactivation.
void deactivate() {
  _log('Extension deactivating...');
  _statusBarItem?.dispose();
  _outputChannel?.dispose();
  _treeProvider?.dispose();
  _log('Extension deactivated');
}

JSPromise<JSObject> _activateWrapper(ExtensionContext context) =>
    activate(context).toJS;

/// Main entry point - sets up exports for VSCode.
void main() {
  _activate = _activateWrapper.toJS;
  _deactivate = deactivate.toJS;
}
