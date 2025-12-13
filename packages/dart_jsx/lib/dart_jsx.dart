/// JSX transpiler for Dart.
///
/// Transforms JSX syntax in Dart files to dart_node_react element calls.
///
/// ## Usage
///
/// In your Dart file, use JSX inside `jsx()` calls:
/// ```dart
/// final element = jsx(<div className="app">
///   <h1>Hello World</h1>
///   <button onClick={handleClick}>Click me</button>
/// </div>);
/// ```
///
/// The transpiler converts this to:
/// ```dart
/// final element = $div(className: 'app') >> [
///   $h1 >> 'Hello World',
///   $button(onClick: handleClick) >> 'Click me',
/// ];
/// ```
library;

export 'src/parser.dart';
export 'src/result_aliases.dart';
export 'src/transformer.dart';
export 'src/transpiler.dart';
