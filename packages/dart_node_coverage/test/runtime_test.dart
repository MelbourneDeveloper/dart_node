/// Tests for runtime coverage collection on Node.js.
@TestOn('node')
library;

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);

  test('cov records line execution', () {
    cov('test_file.dart', 5);
    cov('test_file.dart', 5);
    cov('test_file.dart', 10);

    final json = getCoverageJson();

    expect(json, contains('"test_file.dart"'));
    expect(json, contains('"5"'));
    expect(json, contains('"10"'));
  });

  test('cov tracks multiple files', () {
    cov('file_a.dart', 1);
    cov('file_b.dart', 2);

    final json = getCoverageJson();

    expect(json, contains('"file_a.dart"'));
    expect(json, contains('"file_b.dart"'));
  });

  test('cov increments hit count', () {
    cov('counter.dart', 7);
    cov('counter.dart', 7);
    cov('counter.dart', 7);

    final json = getCoverageJson();

    expect(json, contains('"counter.dart"'));
    expect(json, contains('"7"'));
    // Count should be 3
    expect(json, contains('3'));
  });

  test('getCoverageJson returns valid JSON', () {
    cov('json_test.dart', 1);

    final json = getCoverageJson();

    expect(json, startsWith('{'));
    expect(json, endsWith('}'));
  });
}
