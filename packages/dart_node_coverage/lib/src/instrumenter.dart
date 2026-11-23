/// Source code instrumenter that injects coverage probes.
library;

import 'package:nadz/nadz.dart';

/// Instrument a Dart source file with coverage probes.
///
/// Takes source code and a list of executable line numbers, then injects
/// a `cov(file, line)` probe call at the start of each executable line.
/// Also adds the dart_node_coverage import automatically.
///
/// Example transformation:
/// ```dart
/// // Original
/// void main() {
///   print('hello');
///   final x = 42;
/// }
///
/// // Instrumented
/// import 'package:dart_node_coverage/dart_node_coverage.dart';
/// void main() {
///   cov('file.dart', 2); print('hello');
///   cov('file.dart', 3); final x = 42;
/// }
/// ```
const _coverageImport =
    "import 'package:dart_node_coverage/dart_node_coverage.dart';";

/// Instruments Dart source code by adding coverage probes to executable lines.
Result<String, String> instrumentSource({
  required String sourceCode,
  required String filePath,
  required List<int> executableLines,
}) {
  try {
    final lines = sourceCode.split('\n');
    final executableSet = executableLines.toSet();
    final instrumentedLines = <String>[];
    final insertIndex = _findImportInsertIndex(lines);

    for (var i = 0; i < lines.length; i++) {
      // Insert coverage import at the right spot
      if (i == insertIndex) {
        instrumentedLines.add(_coverageImport);
      }

      final lineNumber = i + 1;
      final line = lines[i];
      final shouldInstrument = executableSet.contains(lineNumber);
      final instrumentedLine = shouldInstrument
          ? _instrumentLine(line, filePath, lineNumber)
          : line;

      instrumentedLines.add(instrumentedLine);
    }

    return Success(instrumentedLines.join('\n'));
  } on Exception catch (e) {
    return Error('Failed to instrument $filePath: $e');
  }
}

/// Find the index where the coverage import should be inserted.
/// After library directive if present, otherwise after existing imports,
/// or at the top if no imports.
int _findImportInsertIndex(List<String> lines) {
  var lastImportIndex = -1;
  var libraryIndex = -1;

  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.startsWith('library')) libraryIndex = i;
    if (trimmed.startsWith('import ')) lastImportIndex = i;
  }

  // Insert after last import, or after library, or at top
  return lastImportIndex >= 0
      ? lastImportIndex + 1
      : libraryIndex >= 0
      ? libraryIndex + 1
      : 0;
}

/// Inject coverage probe at the start of a line.
///
/// Preserves leading whitespace and injects probe before the first
/// non-whitespace character.
String _instrumentLine(String line, String filePath, int lineNumber) {
  final indent = _getLeadingWhitespace(line);
  final content = line.trimLeft();

  final probe = "cov('$filePath', $lineNumber); ";
  return '$indent$probe$content';
}

/// Extract leading whitespace from a line.
String _getLeadingWhitespace(String line) {
  final match = RegExp(r'^\s*').firstMatch(line);
  return (match == null) ? '' : match.group(0) ?? '';
}
