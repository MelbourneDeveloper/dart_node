import 'package:dart_node_react/dart_node_react.dart';
import 'package:markdown_editor/markdown_editor.dart';

void main() {
  final root = Document.getElementById('root');
  (root != null)
      ? ReactDOM.createRoot(root).render(EditorApp())
      : throw StateError('Root element not found');
}
