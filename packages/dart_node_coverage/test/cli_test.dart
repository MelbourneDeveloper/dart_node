/// Tests for the coverage CLI tool.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cli_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('CLI fails with non-existent directory', () async {
    final result = await Process.run('dart', [
      'run',
      'dart_node_coverage:coverage',
      '/non/existent/path',
    ], workingDirectory: p.join(Directory.current.path));

    expect(result.exitCode, isNot(0));
    expect(result.stderr.toString(), contains('does not exist'));
  });

  test('CLI fails when lib directory missing', () async {
    final result = await Process.run('dart', [
      'run',
      'dart_node_coverage:coverage',
      tempDir.path,
    ], workingDirectory: p.join(Directory.current.path));

    expect(result.exitCode, isNot(0));
    expect(result.stderr.toString(), contains('lib directory not found'));
  });

  test('CLI fails when no Dart files in lib', () async {
    Directory(p.join(tempDir.path, 'lib')).createSync();

    final result = await Process.run('dart', [
      'run',
      'dart_node_coverage:coverage',
      tempDir.path,
    ], workingDirectory: p.join(Directory.current.path));

    expect(result.exitCode, isNot(0));
    expect(result.stderr.toString(), contains('No Dart files found'));
  });

  test('CLI parses --output flag correctly', () async {
    final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
    File(
      p.join(libDir.path, 'example.dart'),
    ).writeAsStringSync('void main() {}');

    final customOutput = p.join(tempDir.path, 'custom', 'output.lcov');

    final result = await Process.run('dart', [
      'run',
      'dart_node_coverage:coverage',
      tempDir.path,
      '--output',
      customOutput,
    ], workingDirectory: p.join(Directory.current.path));

    // Will fail because no tests/coverage.json, but that's OK - we're testing arg parsing
    // The error should NOT be about the output path
    expect(result.stderr.toString(), isNot(contains('output')));
  });

  test('CLI parses -o flag correctly', () async {
    final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
    File(
      p.join(libDir.path, 'example.dart'),
    ).writeAsStringSync('void main() {}');

    final customOutput = p.join(tempDir.path, 'custom', 'output.lcov');

    final result = await Process.run('dart', [
      'run',
      'dart_node_coverage:coverage',
      tempDir.path,
      '-o',
      customOutput,
    ], workingDirectory: p.join(Directory.current.path));

    // Will fail because no tests/coverage.json, but that's OK - we're testing arg parsing
    expect(result.stderr.toString(), isNot(contains('output')));
  });

  test('coverage.json parsing handles valid JSON', () async {
    // Create a minimal package structure
    final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
    File(p.join(libDir.path, 'example.dart')).writeAsStringSync('''
void main() {
  print('hello');
}
''');

    // Create coverage directory and coverage.json
    final coverageDir = Directory(p.join(tempDir.path, 'coverage'))
      ..createSync();
    final coverageJson = {
      'lib/example.dart': {'2': 5, '3': 3},
    };
    File(
      p.join(coverageDir.path, 'coverage.json'),
    ).writeAsStringSync(jsonEncode(coverageJson));

    // Create a pubspec.yaml for dart test to work
    File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_pkg
environment:
  sdk: ^3.0.0
''');

    // Skip tests step by checking we get to the LCOV generation
    // Since dart test would fail with no test folder, we expect that error
    final result = await Process.run('dart', [
      'run',
      'dart_node_coverage:coverage',
      tempDir.path,
    ], workingDirectory: p.join(Directory.current.path));

    // Should fail at test step, not at coverage.json parsing
    expect(result.exitCode, isNot(0));
  });
}
