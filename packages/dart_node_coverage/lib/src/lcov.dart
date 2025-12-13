/// LCOV format output generator for coverage data.
library;

import 'dart:io';

import 'package:nadz/nadz.dart';

/// Coverage data for a single file
typedef FileCoverage = ({
  String filePath,
  Map<int, int> lineCounts, // line number -> execution count
});

/// Generate LCOV format output from coverage data
Result<String, String> generateLcov(List<FileCoverage> coverage) {
  try {
    final buffer = StringBuffer();
    for (final file in coverage) {
      buffer.writeln('SF:${file.filePath}');

      final entries = file.lineCounts.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (final entry in entries) {
        buffer.writeln('DA:${entry.key},${entry.value}');
      }

      final linesFound = file.lineCounts.length;
      final linesHit = file.lineCounts.values
          .where((count) => count > 0)
          .length;

      buffer
        ..writeln('LF:$linesFound')
        ..writeln('LH:$linesHit')
        ..writeln('end_of_record');
    }

    return Success(buffer.toString());
  } on Exception catch (e) {
    return Error('Failed to generate LCOV: $e');
  }
}

/// Write LCOV data to a file
Result<void, String> writeLcovFile(
  String outputPath,
  List<FileCoverage> coverage,
) {
  final lcovResult = generateLcov(coverage);

  return switch (lcovResult) {
    Success(value: final lcovData) => _writeFile(outputPath, lcovData),
    Error(error: final err) => Error(err),
  };
}

Result<void, String> _writeFile(String path, String content) {
  try {
    File(path).writeAsStringSync(content);
    return const Success(null);
  } on Exception catch (e) {
    return Error('Failed to write file: $e');
  }
}
