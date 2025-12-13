// ignore_for_file: avoid_print
import 'dart:io';

const version = '0.2.0-beta';

const packageDeps = <String, List<String>>{
  // Tier 1 - no internal deps
  'dart_logging': [],
  'dart_node_core': [],
  'dart_jsx': [],
  // Tier 2 - depends on tier 1
  'reflux': ['dart_logging'],
  'dart_node_express': ['dart_node_core'],
  'dart_node_ws': ['dart_node_core'],
  'dart_node_better_sqlite3': ['dart_node_core'],
  'dart_node_mcp': ['dart_node_core'],
  // Tier 3 - depends on tier 1
  'dart_node_react': ['dart_node_core'],
  'dart_node_react_native': ['dart_node_core', 'dart_node_react'],
};

void main(List<String> args) {
  if (args.isEmpty || (args[0] != 'local' && args[0] != 'release')) {
    print('Usage: dart tools/switch_deps.dart <local|release>');
    print('  local   - Use path dependencies for local development');
    print('  release - Use versioned pub.dev dependencies for release');
    exit(1);
  }

  final mode = args[0];
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final repoRoot = scriptDir.parent;
  final packagesDir = Directory('${repoRoot.path}/packages');

  print('Switching to $mode mode...\n');

  for (final entry in packageDeps.entries) {
    final packageName = entry.key;
    final deps = entry.value;

    if (deps.isEmpty) {
      print('$packageName: No internal dependencies, skipping');
      continue;
    }

    final pubspecFile = File('${packagesDir.path}/$packageName/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('$packageName: pubspec.yaml not found, skipping');
      continue;
    }

    var content = pubspecFile.readAsStringSync();

    for (final dep in deps) {
      content = _switchDependency(content, dep, mode);
    }

    pubspecFile.writeAsStringSync(content);
    print('$packageName: Updated ${deps.join(", ")}');
  }

  print('\nDone! Run "dart pub get" in each package to update dependencies.');
}

String _switchDependency(String content, String depName, String mode) {
  final pathPattern = RegExp(
    '$depName:\\s*\\n\\s*path:\\s*[^\\n]+',
    multiLine: true,
  );
  final versionPattern = RegExp('$depName:\\s*\\^[^\\n]+');

  if (mode == 'local') {
    final relativePath = '../$depName';
    final replacement = '$depName:\n    path: $relativePath';

    if (pathPattern.hasMatch(content)) {
      return content.replaceFirst(pathPattern, replacement);
    }
    if (versionPattern.hasMatch(content)) {
      return content.replaceFirst(versionPattern, replacement);
    }
  } else {
    final replacement = '$depName: ^$version';

    if (versionPattern.hasMatch(content)) {
      return content.replaceFirst(versionPattern, replacement);
    }
    if (pathPattern.hasMatch(content)) {
      return content.replaceFirst(pathPattern, replacement);
    }
  }

  return content;
}
