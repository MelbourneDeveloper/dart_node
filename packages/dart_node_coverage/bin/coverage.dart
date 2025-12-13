/// CLI tool for orchestrating Dart coverage collection.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_node_coverage/src/instrumenter.dart';
import 'package:dart_node_coverage/src/lcov.dart';
import 'package:dart_node_coverage/src/parser.dart';
import 'package:nadz/nadz.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final argsResult = _parseArgs(args);

  final config = switch (argsResult) {
    Success(:final value) => value,
    Error(:final error) => _exit(error),
  };

  final workflowResult = await _runCoverageWorkflow(config);

  switch (workflowResult) {
    case Success(:final value):
      stdout.writeln('Coverage collection completed successfully');
      stdout.writeln('LCOV file written to: $value');
    case Error(:final error):
      _exit(error);
  }
}

Never _exit(String message) {
  stderr.writeln('Error: $message');
  exit(1);
}

typedef _Config = ({String packageDir, String outputPath});

Result<_Config, String> _parseArgs(List<String> args) {
  final packageDir = args.isEmpty ? Directory.current.path : args[0];
  final outputPath = _findOutputPath(args);

  return Directory(packageDir).existsSync()
      ? Success((packageDir: packageDir, outputPath: outputPath))
      : Error<_Config, String>('Package directory does not exist: $packageDir');
}

String _findOutputPath(List<String> args) {
  for (var i = 0; i < args.length - 1; i++) {
    final shouldUseNext = args[i] == '--output' || args[i] == '-o';
    if (shouldUseNext) return args[i + 1];
  }
  return 'coverage/lcov.info';
}

Future<Result<String, String>> _runCoverageWorkflow(_Config config) async {
  final backupDir = Directory.systemTemp.createTempSync('dart_cov_bak_');

  try {
    return await _runWorkflowSteps(config, backupDir.path);
  } finally {
    backupDir.deleteSync(recursive: true);
  }
}

Future<Result<String, String>> _runWorkflowSteps(
  _Config config,
  String backupDir,
) async {
  final filesResult = _findDartFiles(config.packageDir);
  switch (filesResult) {
    case Success(:final value):
      // Backup original files
      _backupFiles(value, config.packageDir, backupDir);

      // Instrument files in-place
      final instrumentResult = await _instrumentFilesInPlace(
        value,
        config.packageDir,
      );
      switch (instrumentResult) {
        case Success():
          // Run tests with instrumented code
          final testResult = await _runTests(config.packageDir);

          // Restore original files regardless of test result
          _restoreFiles(value, config.packageDir, backupDir);

          switch (testResult) {
            case Success():
              final coverageResult = _generateLcov(
                config.packageDir,
                config.outputPath,
              );
              return switch (coverageResult) {
                Success() => Success<String, String>(config.outputPath),
                Error(:final error) => Error<String, String>(error),
              };
            case Error(:final error):
              return Error<String, String>(error);
          }
        case Error(:final error):
          _restoreFiles(value, config.packageDir, backupDir);
          return Error<String, String>(error);
      }
    case Error(:final error):
      return Error<String, String>(error);
  }
}

void _backupFiles(List<String> files, String packageDir, String backupDir) {
  for (final file in files) {
    final relativePath = p.relative(file, from: packageDir);
    final backupPath = p.join(backupDir, relativePath);
    File(backupPath).parent.createSync(recursive: true);
    File(file).copySync(backupPath);
  }
}

void _restoreFiles(List<String> files, String packageDir, String backupDir) {
  for (final file in files) {
    final relativePath = p.relative(file, from: packageDir);
    final backupPath = p.join(backupDir, relativePath);
    File(backupPath).copySync(file);
  }
}

Result<List<String>, String> _findDartFiles(String packageDir) {
  final libDir = Directory(p.join(packageDir, 'lib'));

  final exists = libDir.existsSync();
  if (!exists) {
    return const Error<List<String>, String>('lib directory not found');
  }

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path)
      .toList();

  return files.isEmpty
      ? const Error<List<String>, String>('No Dart files found in lib/')
      : Success<List<String>, String>(files);
}

Future<Result<void, String>> _instrumentFilesInPlace(
  List<String> files,
  String packageDir,
) async {
  for (final file in files) {
    final result = await _instrumentFileInPlace(file);
    switch (result) {
      case Success():
        continue;
      case Error(:final error):
        return Error<void, String>(error);
    }
  }
  return const Success<void, String>(null);
}

Future<Result<void, String>> _instrumentFileInPlace(String filePath) async {
  final sourceFile = File(filePath);
  final source = sourceFile.readAsStringSync();

  final parseResult = parseExecutableLines(source, filePath);
  switch (parseResult) {
    case Success(:final value):
      final instrumentResult = instrumentSource(
        sourceCode: source,
        filePath: filePath,
        executableLines: value,
      );
      switch (instrumentResult) {
        case Success(:final value):
          sourceFile.writeAsStringSync(value);
          return const Success<void, String>(null);
        case Error(:final error):
          return Error<void, String>(error);
      }
    case Error(:final error):
      return Error<void, String>(error);
  }
}

Future<Result<void, String>> _runTests(String packageDir) async {
  stdout.writeln('Running tests in $packageDir...');
  final result = await Process.run('dart', const [
    'test',
  ], workingDirectory: packageDir);

  stdout.writeln('Test stdout: ${result.stdout}');
  stderr.writeln('Test stderr: ${result.stderr}');

  return result.exitCode == 0
      ? const Success<void, String>(null)
      : Error<void, String>('Tests failed with exit code ${result.exitCode}');
}

Result<void, String> _generateLcov(String packageDir, String outputPath) {
  final coverageJsonPath = p.join(packageDir, 'coverage', 'coverage.json');
  final coverageFile = File(coverageJsonPath);

  final exists = coverageFile.existsSync();
  if (!exists) {
    return const Error<void, String>('Coverage file not found');
  }

  final parseResult = _parseCoverageJson(coverageFile);
  switch (parseResult) {
    case Success(:final value):
      File(outputPath).parent.createSync(recursive: true);
      final lcovResult = writeLcovFile(outputPath, value);
      return switch (lcovResult) {
        Success() => const Success<void, String>(null),
        Error(:final error) => Error<void, String>(error),
      };
    case Error(:final error):
      return Error<void, String>(error);
  }
}

Result<List<FileCoverage>, String> _parseCoverageJson(File coverageFile) {
  try {
    final jsonString = coverageFile.readAsStringSync();
    final jsonData = jsonDecode(jsonString);

    final isMap = jsonData is Map<String, dynamic>;
    if (!isMap) {
      return const Error<List<FileCoverage>, String>(
        'Invalid coverage.json: expected object',
      );
    }

    final coverage = <FileCoverage>[];

    for (final entry in jsonData.entries) {
      final filePath = entry.key;
      final lineData = entry.value;

      final isLineMap = lineData is Map<String, dynamic>;
      if (!isLineMap) continue;

      final lineCounts = <int, int>{};
      for (final lineEntry in lineData.entries) {
        final lineNum = int.tryParse(lineEntry.key);
        final count = lineEntry.value;
        final isValidCount = count is num;
        if (lineNum != null && isValidCount) {
          lineCounts[lineNum] = count.toInt();
        }
      }

      coverage.add((filePath: filePath, lineCounts: lineCounts));
    }

    return Success<List<FileCoverage>, String>(coverage);
  } on FormatException catch (e) {
    return Error<List<FileCoverage>, String>('Invalid JSON: $e');
  } on FileSystemException catch (e) {
    return Error<List<FileCoverage>, String>('Failed to read file: $e');
  }
}
