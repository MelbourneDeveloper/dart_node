/// Main app entry point.
///
/// This file imports the generated .g.dart files.
/// Run `dart run dart_jsx:jsx --watch .` to auto-generate them.
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart';

// Import the transpiled components
import 'package:jsx_demo/counter.g.dart';
import 'package:jsx_demo/tabs_example.g.dart';

void main() {
  final root = createRoot(document.getElementById('root')!);
  root.render(App());
}

/// The main app component - shows counter and tabs.
ReactElement App() => $div(className: 'app') >> [Counter(), TabsExample()];

@JS('document')
external JSObject get document;

extension on JSObject {
  external JSObject? getElementById(String id);
}
