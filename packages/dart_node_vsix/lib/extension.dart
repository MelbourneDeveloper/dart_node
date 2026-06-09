/// The Dart Node extension entry point.
///
/// A general-purpose VS Code extension written entirely in Dart. It ships a
/// handful of basic commands (hello, version, echo, run counter) and also
/// exercises every binding in dart_node_vsix via a self-test command so the
/// APIs are validated in a real VS Code Extension Host environment.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';
import 'package:dart_node_vsix/src/js_helpers.dart' as js;

// ignore: unused_import - used by tests to access TestAPI type
import 'package:dart_node_vsix/test_api_types.dart';

/// Command id: greet the user.
const _cmdHello = 'dartNode.hello';

/// Command id: show the running VS Code version.
const _cmdVersion = 'dartNode.showVersion';

/// Command id: prompt for input and echo it back.
const _cmdEcho = 'dartNode.echo';

/// Command id: increment and report a persisted run counter.
const _cmdCount = 'dartNode.count';

/// Command id: exercise every binding (self-test).
const _cmdTest = 'dartNode.test';

/// Explorer tree view id.
const _treeViewId = 'dartNode.tree';

/// Output channel name.
const _channelName = 'Dart Node';

/// Status bar text (with a codicon).
const _statusBarText = r'$(rocket) Dart Node';

/// Status bar hover tooltip.
const _statusBarTooltip = 'Dart Node extension';

/// Prefix for console log lines.
const _logPrefix = '[Dart Node]';

/// Greeting shown by the hello command.
const _helloMessage = 'Hello from Dart Node!';

/// Prefix for the version message.
const _versionPrefix = 'VS Code ';

/// Prompt shown by the echo command.
const _echoPrompt = 'Type a message for Dart Node to echo';

/// Placeholder shown by the echo command.
const _echoPlaceholder = 'Your message';

/// Prefix for the echoed reply.
const _echoReplyPrefix = 'Dart Node echo: ';

/// Global-state key for the run counter.
const _countKey = 'dartNode.runCount';

/// Prefix for the run-counter message.
const _countPrefix = 'Dart Node command run ';

/// Suffix for the run-counter message.
const _countSuffix = ' time(s)';

/// Message shown by the self-test command.
const _testCommandMessage = 'Dart Node bindings self-test ran!';

/// Global-state key used by the activation memento self-check.
const _selfCheckKey = 'dartNode.selfCheck';

/// Value written then read back by the activation memento self-check.
const _selfCheckValue = 7;

/// Prefix for the memento self-check log line.
const _selfCheckPrefix = 'globalState round-trip: ';

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
  js.consoleLog('$_logPrefix $msg');
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

  // Output channel
  _outputChannel = vscode.window.createOutputChannel(_channelName);
  _outputChannel!.appendLine('Dart Node activated');
  _log('Output channel created: ${_outputChannel!.name}');

  // Status bar item
  _statusBarItem = vscode.window.createStatusBarItem(
    StatusBarAlignment.left.value,
    100,
  );
  _statusBarItem!.text = _statusBarText;
  _statusBarItem!.tooltip = _statusBarTooltip;
  _statusBarItem!.command = _cmdHello;
  _statusBarItem!.show();
  _log('Status bar item created');

  // General-purpose feature commands.
  _registerFeatureCommands(context);

  // Self-test command (exercises the bindings).
  final cmd = vscode.commands.registerCommand(_cmdTest, _onTestCommand);
  context.addSubscription(cmd);
  _log('Command registered: $_cmdTest');

  // Tree view
  _treeProvider = _TestTreeDataProvider();
  _treeProvider!.addItem('Test Item 1');
  _treeProvider!.addItem('Test Item 2');
  _treeProvider!.addItem('Test Item 3');

  final treeView = vscode.window.createTreeView(
    _treeViewId,
    TreeViewOptions(treeDataProvider: JSTreeDataProvider(_treeProvider!)),
  );
  // ignore: unnecessary_lambdas - can't tearoff external extension type members
  context.addSubscription(Disposable.fromFunction(() => treeView.dispose()));
  _log('Tree view created with ${_treeProvider!.items.length} items');

  // Self-check the globalState memento binding (Memento.update + get). If the
  // binding were broken this throws and activation fails loudly — no silence.
  await context.globalState.update(_selfCheckKey, _selfCheckValue);
  final readBack = context.globalState.get<JSNumber>(_selfCheckKey)?.toDartInt;
  _log('$_selfCheckPrefix$readBack');

  _log('Extension activated');
  return _createTestAPI();
}

void _onTestCommand() {
  vscode.window.showInformationMessage(_testCommandMessage);
  _log('Test command executed');
}

/// Registers the general-purpose Dart Node commands.
void _registerFeatureCommands(ExtensionContext context) {
  context
    ..addSubscription(vscode.commands.registerCommand(_cmdHello, _onHello))
    ..addSubscription(vscode.commands.registerCommand(_cmdVersion, _onVersion))
    ..addSubscription(
      vscode.commands.registerCommand(_cmdEcho, () => unawaited(_onEcho())),
    )
    ..addSubscription(
      vscode.commands.registerCommand(
        _cmdCount,
        () => unawaited(_onCount(context)),
      ),
    );
  _log('Feature commands registered');
}

/// Greets the user.
void _onHello() => vscode.window.showInformationMessage(_helloMessage);

/// Shows the running VS Code version.
void _onVersion() =>
    vscode.window.showInformationMessage('$_versionPrefix${vscode.version}');

/// Prompts for input and echoes it back.
Future<void> _onEcho() async {
  final options = InputBoxOptions(
    prompt: _echoPrompt,
    placeHolder: _echoPlaceholder,
  );
  final result = await vscode.window.showInputBox(options).toDart;
  if (result == null) return;
  vscode.window.showInformationMessage('$_echoReplyPrefix${result.toDart}');
}

/// Increments and reports a persisted run counter.
Future<void> _onCount(ExtensionContext context) async {
  final stored = context.globalState.get<JSNumber>(_countKey);
  final next = (stored?.toDartInt ?? 0) + 1;
  await context.globalState.update(_countKey, next);
  vscode.window.showInformationMessage('$_countPrefix$next$_countSuffix');
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
