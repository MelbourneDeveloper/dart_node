# dart_jsx

Dart 的 JSX 转译器 - 将 JSX 语法转换为 dart_node_react 调用。

## 安装

```yaml
dependencies:
  dart_jsx: ^0.1.0
```

## 使用方法

在 Dart 文件中的 `jsx()` 调用内编写 JSX：

```dart
final element = jsx(<div className="app">
  <h1>Hello World</h1>
  <button onClick={handleClick}>Click me</button>
</div>);
```

转译器将其转换为：

```dart
final element = $div(className: 'app') >> [
  $h1 >> 'Hello World',
  $button(onClick: handleClick) >> 'Click me',
];
```

## VSCode 扩展

配套的 VSCode 扩展为 `.jsx` Dart 文件提供语法高亮。请参阅 [.vscode/extensions/dart-jsx](../../.vscode/extensions/dart-jsx)。

## dart_node 的一部分

[GitHub](https://github.com/MelbourneDeveloper/dart_node)
