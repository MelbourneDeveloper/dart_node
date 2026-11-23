/// Test helpers for JSX demo tests.
library;

import 'package:dart_node_react/src/testing_library.dart';

/// Wait for text to appear in rendered output
Future<void> waitForText(
  TestRenderResult result,
  String text, {
  int maxAttempts = 20,
  Duration interval = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxAttempts; i++) {
    if (result.container.textContent.contains(text)) return;
    await Future<void>.delayed(interval);
  }
  throw StateError('Text "$text" not found after $maxAttempts attempts');
}
