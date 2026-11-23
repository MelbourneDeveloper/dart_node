/// JSX transpiler CLI.
///
/// Usage:
///   dart run dart_jsx:jsx <input.dart> [output.dart]
///   dart run dart_jsx:jsx --watch <directory>
///
/// If output is not specified, writes to stdout.
/// Use --watch to watch a directory for changes.
import 'dart:io';

import 'package:dart_jsx/dart_jsx.dart';
import 'package:nadz/nadz.dart';

void main(List<String> args) {
  final hasArgs = args.isNotEmpty;
  if (!hasArgs) {
    _printUsage();
    exit(1);
  }

  final isWatch = args.first == '--watch';
  isWatch ? _watchMode(args.sublist(1)) : _transpileMode(args);
}

void _printUsage() {
  stderr.writeln('JSX Transpiler for Dart');
  stderr.writeln('');
  stderr.writeln('Usage:');
  stderr.writeln('  dart run dart_jsx:jsx <input.jsx> [output.dart]');
  stderr.writeln('  dart run dart_jsx:jsx --watch <directory>');
  stderr.writeln('');
  stderr.writeln('Options:');
  stderr.writeln('  --watch  Watch directory for .jsx files');
  stderr.writeln('');
  stderr.writeln('Examples:');
  stderr.writeln('  dart run dart_jsx:jsx app.jsx app.dart');
  stderr.writeln('  dart run dart_jsx:jsx --watch lib/');
}

void _transpileMode(List<String> args) {
  final inputPath = args.first;
  final outputPath = args.length > 1 ? args[1] : null;

  final inputFile = File(inputPath);
  final exists = inputFile.existsSync();
  if (!exists) {
    stderr.writeln('Error: File not found: $inputPath');
    exit(1);
  }

  final source = inputFile.readAsStringSync();
  final result = transpileJsx(source);

  result.match(
    onSuccess: (output) {
      final hasOutput = outputPath != null;
      if (hasOutput) {
        final header =
            '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
            '// Generated from: ${inputPath.split('/').last}\n\n';
        File(outputPath).writeAsStringSync(header + output);
      } else {
        stdout.write(output);
      }
    },
    onError: (error) {
      stderr.writeln('Error: $error');
      exit(1);
    },
  );
}

void _watchMode(List<String> args) {
  final hasDir = args.isNotEmpty;
  if (!hasDir) {
    stderr.writeln('Error: --watch requires a directory');
    exit(1);
  }

  final dirPath = args.first;
  final dir = Directory(dirPath);
  final exists = dir.existsSync();
  if (!exists) {
    stderr.writeln('Error: Directory not found: $dirPath');
    exit(1);
  }

  stdout.writeln('Watching $dirPath for .jsx files...');

  // Initial transpile of all .jsx files
  _transpileDirectory(dir);

  // Watch for changes
  dir.watch(recursive: true).listen((event) {
    final isJsxFile =
        event.path.endsWith('.jsx') && !event.path.endsWith('.g.dart');
    if (!isJsxFile) return;

    final isModifyOrCreate =
        event.type == FileSystemEvent.modify ||
        event.type == FileSystemEvent.create;

    if (isModifyOrCreate) {
      stdout.writeln('Transpiling: ${event.path}');
      _transpileFile(event.path);
    }
  });
}

void _transpileDirectory(Directory dir) {
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.jsx'));

  for (final file in files) {
    stdout.writeln('Transpiling: ${file.path}');
    _transpileFile(file.path);
  }
}

void _transpileFile(String inputPath) {
  final inputFile = File(inputPath);
  final exists = inputFile.existsSync();
  if (!exists) return;

  // .jsx -> .g.dart
  final outputPath = inputPath.replaceAll('.jsx', '.g.dart');

  final source = inputFile.readAsStringSync();
  final result = transpileJsx(source);

  result.match(
    onSuccess: (output) {
      // Add generated file header
      final header =
          '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
          '// Generated from: ${inputPath.split('/').last}\n\n';
      File(outputPath).writeAsStringSync(header + output);
      stdout.writeln('  -> $outputPath');
    },
    onError: (error) {
      stderr.writeln('Error in $inputPath: $error');
    },
  );
}
