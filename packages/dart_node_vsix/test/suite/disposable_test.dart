/// Disposable API Tests
library;

import 'package:dart_node_vsix/dart_node_vsix.dart'
    hide consoleError, consoleLog;

import 'test_helpers.dart';

void main() {
  consoleLog('[DISPOSABLE TEST] main() called');

  suite(
    'Disposable API',
    syncTest(() {
      suiteSetup(
        asyncTest(() async {
          await waitForExtensionActivation();
        }),
      );

      test(
        'createDisposable works correctly',
        syncTest(() {
          var disposed = false;
          final disposable = createDisposable(() => disposed = true);
          assertOk(!disposed, 'Should not be disposed yet');
          disposable.dispose();
          assertOk(disposed, 'Should be disposed after dispose()');
        }),
      );

      test(
        'createDisposable creates disposable',
        syncTest(() {
          var disposed = false;
          final disposable = createDisposable(() => disposed = true);
          assertOk(!disposed, 'Should not be disposed yet');
          disposable.dispose();
          assertOk(disposed, 'Should be disposed after dispose()');
        }),
      );

      test(
        'Multiple disposables can be created',
        syncTest(() {
          var count = 0;
          final d1 = createDisposable(() => count++);
          final d2 = createDisposable(() => count++);
          final d3 = createDisposable(() => count++);
          assertEqual(count, 0);
          d1.dispose();
          assertEqual(count, 1);
          d2.dispose();
          assertEqual(count, 2);
          d3.dispose();
          assertEqual(count, 3);
        }),
      );
    }),
  );
}
