/// Tests for LCOV generation (VM-only due to file I/O)
@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_node_coverage/src/lcov.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  test('generateLcov produces correct LCOV format', () {
    final coverage = [
      (filePath: '/path/to/file.dart', lineCounts: {5: 3, 8: 0, 10: 1}),
    ];

    final result = generateLcov(coverage);

    expect(result, isA<Success<String, String>>());
    final lcov = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Expected Success'),
    };

    expect(lcov, contains('SF:/path/to/file.dart'));
    expect(lcov, contains('DA:5,3'));
    expect(lcov, contains('DA:8,0'));
    expect(lcov, contains('DA:10,1'));
    expect(lcov, contains('LF:3'));
    expect(lcov, contains('LH:2'));
    expect(lcov, contains('end_of_record'));
  });

  test('generateLcov sorts line numbers', () {
    final coverage = [
      (filePath: '/path/to/file.dart', lineCounts: {10: 1, 5: 3, 8: 0}),
    ];

    final result = generateLcov(coverage);

    expect(result, isA<Success<String, String>>());
    final lcov = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Expected Success'),
    };

    final lines = lcov.split('\n');
    final daLines = lines.where((l) => l.startsWith('DA:')).toList();
    expect(daLines, ['DA:5,3', 'DA:8,0', 'DA:10,1']);
  });

  test('generateLcov handles multiple files', () {
    final coverage = [
      (filePath: '/path/to/file1.dart', lineCounts: {5: 3}),
      (filePath: '/path/to/file2.dart', lineCounts: {10: 1}),
    ];

    final result = generateLcov(coverage);

    expect(result, isA<Success<String, String>>());
    final lcov = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Expected Success'),
    };

    expect(lcov, contains('SF:/path/to/file1.dart'));
    expect(lcov, contains('SF:/path/to/file2.dart'));
    final endRecordCount = 'end_of_record'.allMatches(lcov).length;
    expect(endRecordCount, 2);
  });

  test('writeLcovFile creates file with correct content', () {
    final tempDir = Directory.systemTemp.createTempSync('lcov_test_');
    final outputPath = '${tempDir.path}/coverage.lcov';

    final coverage = [
      (filePath: '/path/to/file.dart', lineCounts: {5: 3, 8: 0}),
    ];

    final result = writeLcovFile(outputPath, coverage);

    expect(result, isA<Success<void, String>>());

    final file = File(outputPath);
    expect(file.existsSync(), isTrue);

    final content = file.readAsStringSync();
    expect(content, contains('SF:/path/to/file.dart'));
    expect(content, contains('DA:5,3'));
    expect(content, contains('DA:8,0'));
    expect(content, contains('LF:2'));
    expect(content, contains('LH:1'));

    tempDir.deleteSync(recursive: true);
  });
}
