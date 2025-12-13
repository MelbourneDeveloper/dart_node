// ignore_for_file: avoid_print
import 'dart:io';

/// Package dependency graph - order matters for publishing
/// Packages with no dependencies must be published first
const packageDeps = <String, List<String>>{
  // Tier 1 - no internal dependencies
  'dart_logging': [],
  'dart_node_core': [],
  'dart_jsx': [],
  // Tier 2 - depends on tier 1
  'reflux': ['dart_logging'],
  'dart_node_express': ['dart_node_core'],
  'dart_node_ws': ['dart_node_core'],
  'dart_node_better_sqlite3': ['dart_node_core'],
  'dart_node_mcp': ['dart_node_core'],
  // Tier 3 - depends on tier 2
  'dart_node_react': ['dart_node_core'],
  'dart_node_react_native': ['dart_node_core', 'dart_node_react'],
};

/// Publishing order based on dependency graph (topological sort)
const publishOrder = [
  // Tier 1
  'dart_logging',
  'dart_node_core',
  'dart_jsx',
  // Tier 2
  'reflux',
  'dart_node_express',
  'dart_node_ws',
  'dart_node_better_sqlite3',
  'dart_node_mcp',
  // Tier 3
  'dart_node_react',
  'dart_node_react_native',
];

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart tools/prepare_publish.dart <version>');
    print('  version - The version to set (e.g., 0.2.0-beta)');
    print('');
    print('This script prepares all packages for publishing by:');
    print('  1. Setting the version in all pubspec.yaml files');
    print('  2. Updating interdependencies to use pub.dev versions');
    print('  3. Removing publish_to: none from all pubspec.yaml files');
    exit(1);
  }

  final version = args[0];
  if (!_isValidVersion(version)) {
    print('Error: Invalid version format: $version');
    print('Expected format: X.Y.Z or X.Y.Z-prerelease');
    exit(1);
  }

  final scriptDir = File(Platform.script.toFilePath()).parent;
  final repoRoot = scriptDir.parent;
  final packagesDir = Directory('${repoRoot.path}/packages');

  print('Preparing packages for publishing version $version\n');

  for (final packageName in publishOrder) {
    _preparePackage(packagesDir, packageName, version);
  }

  print('\nAll packages prepared for publishing!');
  print('Publishing order: ${publishOrder.join(' -> ')}');
}

void _preparePackage(
  Directory packagesDir,
  String packageName,
  String version,
) {
  final pubspecFile = File('${packagesDir.path}/$packageName/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: $packageName/pubspec.yaml not found');
    exit(1);
  }

  var content = pubspecFile.readAsStringSync();
  final changes = <String>[];

  // 1. Update version
  final versionPattern = RegExp(r'version:\s*[^\n]+');
  if (versionPattern.hasMatch(content)) {
    content = content.replaceFirst(versionPattern, 'version: $version');
    changes.add('version -> $version');
  }

  // 2. Remove publish_to: none
  final publishToPattern = RegExp(r'publish_to:\s*none\n?');
  if (publishToPattern.hasMatch(content)) {
    content = content.replaceFirst(publishToPattern, '');
    changes.add('removed publish_to: none');
  }

  // 3. Update interdependencies to pub.dev versions
  final deps = packageDeps[packageName] ?? [];
  for (final dep in deps) {
    content = _switchToPubDevDependency(content, dep, version);
    changes.add('$dep -> $version');
  }

  pubspecFile.writeAsStringSync(content);
  print('$packageName: ${changes.join(", ")}');
}

String _switchToPubDevDependency(
  String content,
  String depName,
  String version,
) {
  // Match path dependency format
  final pathPattern = RegExp(
    '$depName:\\s*\\n\\s*path:\\s*[^\\n]+',
    multiLine: true,
  );

  // Match existing version dependency format (with or without caret)
  final versionPattern = RegExp('$depName:\\s*\\^?[^\\n]+');

  final replacement = '$depName: $version';

  if (pathPattern.hasMatch(content)) {
    return content.replaceFirst(pathPattern, replacement);
  }
  if (versionPattern.hasMatch(content)) {
    return content.replaceFirst(versionPattern, replacement);
  }

  return content;
}

bool _isValidVersion(String version) {
  // Match semantic versioning with optional prerelease
  final versionRegex = RegExp(r'^\d+\.\d+\.\d+(-[\w.]+)?$');
  return versionRegex.hasMatch(version);
}
