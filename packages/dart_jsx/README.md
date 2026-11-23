# dart_jsx

JSX transpiler for Dart - transforms JSX syntax to dart_node_react calls.

## Usage

Write JSX inside `jsx()` calls in your Dart files:

```dart
final element = jsx(<div className="app">
  <h1>Hello World</h1>
  <button onClick={handleClick}>Click me</button>
</div>);
```

The transpiler converts this to:

```dart
final element = $div(className: 'app') >> [
  $h1 >> 'Hello World',
  $button(onClick: handleClick) >> 'Click me',
];
```

## VSCode Extension

A companion VSCode extension provides syntax highlighting for `.jsx` Dart files. See [.vscode/extensions/dart-jsx](../../.vscode/extensions/dart-jsx).

## Part of dart_node

[GitHub](https://github.com/MelbourneDeveloper/dart_node)
