/// Configuration Tests
/// Verifies configuration settings work correctly.
library;

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Configuration', () {
    test('StoreManager accepts serverPath configuration', () {
      final client = MockMcpClient()..setupDefaultHandlers();
      final manager = StoreManager(serverPath: '/custom/path', client: client);

      expect(manager, isNotNull);

      client.dispose();
    });

    test('StoreManager works without serverPath (defaults to null)', () {
      final client = MockMcpClient()..setupDefaultHandlers();
      final manager = StoreManager(client: client);

      expect(manager, isNotNull);

      client.dispose();
    });
  });
}
