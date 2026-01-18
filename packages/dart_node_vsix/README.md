# dart_node_vsix

Type-safe VSCode extension API bindings for Dart. Build Visual Studio Code extensions entirely in Dart.

## Installation

```yaml
dependencies:
  dart_node_vsix: ^0.11.0-beta
```

## Quick Start

Create `lib/extension.dart`:

```dart
import 'dart:js_interop';
import 'package:dart_node_vsix/dart_node_vsix.dart';

Future<void> activate(ExtensionContext context) async {
  // Create output channel for logging
  final output = vscode.window.createOutputChannel('My Extension');
  output.appendLine('Extension activated!');

  // Register a command
  final cmd = vscode.commands.registerCommand(
    'myExtension.sayHello',
    () => vscode.window.showInformationMessage('Hello from Dart!'),
  );

  context.subscriptions.add(cmd);
}

void deactivate() {}

// Required exports for VSCode
@JS('activate')
external set _activate(JSFunction f);

@JS('deactivate')
external set _deactivate(JSFunction f);

void main() {
  _activate = ((ExtensionContext ctx) => activate(ctx)).toJS;
  _deactivate = deactivate.toJS;
}
```

## Commands

Register and execute VSCode commands:

```dart
// Register a command
final disposable = vscode.commands.registerCommand(
  'myExtension.doSomething',
  () {
    // Command implementation
  },
);

// Execute a command
await vscode.commands.executeCommand('vscode.open', uri).toDart;

// Get all commands
final commands = await vscode.commands.getCommands().toDart;
```

## Window

Interact with the VSCode window:

```dart
// Show messages
vscode.window.showInformationMessage('Info!');
vscode.window.showWarningMessage('Warning!');
vscode.window.showErrorMessage('Error!');

// Show input box
final result = await vscode.window.showInputBox(
  InputBoxOptions(
    prompt: 'Enter your name',
    placeHolder: 'John Doe',
  ),
).toDart;

// Create output channel
final output = vscode.window.createOutputChannel('My Channel');
output.appendLine('Hello!');
output.show();

// Create status bar item
final statusBar = vscode.window.createStatusBarItem(
  StatusBarAlignment.left,
  100,
);
statusBar.text = '\$(sync~spin) Working...';
statusBar.show();
```

## Tree Views

Create custom tree views:

```dart
// Define tree items
extension type MyTreeItem._(JSObject _) implements TreeItem {
  external factory MyTreeItem({
    required String label,
    TreeItemCollapsibleState collapsibleState,
  });
}

// Create a tree data provider
final provider = TreeDataProvider(
  getTreeItem: (element) => element as TreeItem,
  getChildren: (element) {
    if (element == null) {
      return [
        MyTreeItem(
          label: 'Item 1',
          collapsibleState: TreeItemCollapsibleState.collapsed,
        ),
        MyTreeItem(label: 'Item 2'),
      ].toJS;
    }
    return <TreeItem>[].toJS;
  },
);

// Create the tree view
final treeView = vscode.window.createTreeView(
  'myTreeView',
  TreeViewOptions(treeDataProvider: provider),
);
```

## Workspace

Access workspace folders and configuration:

```dart
// Get workspace folders
final folders = vscode.workspace.workspaceFolders;

// Read configuration
final config = vscode.workspace.getConfiguration('myExtension');
final value = config.get<String>('someSetting');

// Watch file changes
final watcher = vscode.workspace.createFileSystemWatcher('**/*.dart');
watcher.onDidChange((uri) {
  print('File changed: ${uri.fsPath}');
});
```

## Disposables

Manage resource cleanup:

```dart
// Create a disposable from a function
final disposable = createDisposable(() {
  // Cleanup code
});

// Add to subscriptions
context.subscriptions.add(disposable);
```

## Event Emitters

Create custom events:

```dart
// Create an event emitter
final emitter = EventEmitter<String>();

// Subscribe to events
final subscription = emitter.event((value) {
  print('Received: $value');
});

// Fire an event
emitter.fire('Hello!');

// Dispose when done
subscription.dispose();
emitter.dispose();
```

## Build Setup

VSCode extensions require CommonJS modules. Create `scripts/wrap-extension.js`:

```javascript
const fs = require('fs');
const path = require('path');

const input = path.join(__dirname, '../build/extension.js');
const output = path.join(__dirname, '../out/extension.js');

const dartJs = fs.readFileSync(input, 'utf8');

const wrapped = `// VSCode extension wrapper for dart2js
(function() {
  if (typeof self === 'undefined') globalThis.self = globalThis;
  if (typeof navigator === 'undefined') {
    globalThis.navigator = { userAgent: 'VSCodeExtensionHost' };
  }
  if (typeof globalThis.require === 'undefined') {
    globalThis.require = require;
  }
  globalThis.vscode = require('vscode');
  ${dartJs}
})();
module.exports = { activate, deactivate };
`;

fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, wrapped);
```

Build script (`build.sh`):

```bash
#!/bin/bash
dart pub get
dart compile js lib/extension.dart -o build/extension.js -O2
node scripts/wrap-extension.js
```

## Testing

dart_node_vsix includes Mocha bindings for VSCode extension testing:

```dart
import 'package:dart_node_vsix/dart_node_vsix.dart';

void main() {
  suite('My Extension', syncTest(() {
    suiteSetup(asyncTest(() async {
      await waitForActivation();
    }));

    test('command is registered', asyncTest(() async {
      final commands = await vscode.commands.getCommands().toDart;
      assertOk(
        commands.toDart.contains('myExtension.sayHello'.toJS),
        'Command should be registered',
      );
    }));
  }));
}
```

## API Modules

| Module | Description |
|--------|-------------|
| `commands.dart` | Command registration and execution |
| `window.dart` | Messages, input boxes, quick picks |
| `output_channel.dart` | Output channel creation and logging |
| `status_bar.dart` | Status bar items |
| `tree_view.dart` | Tree view creation and providers |
| `workspace.dart` | Workspace folders and configuration |
| `webview.dart` | Webview panels |
| `disposable.dart` | Resource management |
| `event_emitter.dart` | Custom event handling |
| `mocha.dart` | Testing utilities |

## Example

See [too_many_cooks_vscode_extension](https://github.com/melbournedeveloper/dart_node/tree/main/examples/too_many_cooks_vscode_extension) for a complete real-world example.

## Source Code

The source code is available on [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_vsix).
