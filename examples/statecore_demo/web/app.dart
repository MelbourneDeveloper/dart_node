/// Web entry point for the statecore counter demo.
library;

import 'package:dart_node_react/dart_node_react.dart';
import 'package:statecore_demo/web/counter_app.dart';

void main() {
  final root = Document.getElementById('root');
  (root != null)
      ? ReactDOM.createRoot(root).render(counterApp())
      : throw StateError('Root element not found');
}
