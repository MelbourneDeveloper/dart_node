/// Aggregate test runner - ensures coverage is collected from all tests.
library;

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:test/test.dart';

import 'db_test.dart' as db_test;
import 'integration_test.dart' as integration_test;
import 'notifications_test.dart' as notifications_test;
import 'server_test.dart' as server_test;
import 'types_test.dart' as types_test;

void main() {
  // Write aggregated coverage at the end of all tests
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  // Run all test suites
  group('types', types_test.main);
  group('db', db_test.main);
  group('server', server_test.main);
  group('notifications', notifications_test.main);
  group('integration', integration_test.main);
}
