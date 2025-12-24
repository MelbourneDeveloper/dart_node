// ignore_for_file: avoid_print

/// Switch Dependencies Tool
///
/// Switches internal package dependencies between local path references
/// (for development) and versioned pub.dev references (for release).
///
/// ## Usage
///
/// ```bash
/// # Switch to local path dependencies for development:
/// dart tools/switch_deps.dart local
///
/// # Switch to versioned pub.dev dependencies for release:
/// dart tools/switch_deps.dart release
/// ```
///
/// ## What it does
///
/// **Local mode** (`local`):
/// Changes dependencies like `dart_node_core: ^0.11.0` to:
/// ```yaml
/// dart_node_core:
///   path: ../dart_node_core
/// ```
///
/// **Release mode** (`release`):
/// Changes path dependencies back to versioned references:
/// ```yaml
/// dart_node_core: ^0.11.0
/// ```
///
/// The version number is read from the first publishable package's pubspec.
///
/// ## After running
///
/// Run `dart pub get` in each affected package to update dependencies.
import 'dart:io';

import 'lib/packages.dart';

void main(List<String> args) {
  if (args.isEmpty || (args[0] != 'local' && args[0] != 'release')) {
    print('Usage: dart tools/switch_deps.dart <local|release>');
    print('  local   - Use path dependencies for local development');
    print('  release - Use versioned pub.dev dependencies for release');
    exit(1);
  }

  final mode = args[0];
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final repoRoot = scriptDir.parent.path;
  final packagesDir = Directory('$repoRoot/packages');

  // Read version from first package's pubspec (they should all match)
  final version = _readCurrentVersion(repoRoot);

  print('Switching to $mode mode...\n');

  final packages = getPublishablePackages();
  for (final pkg in packages) {
    final deps = getInternalDependencies(repoRoot, pkg.name);

    if (deps.isEmpty) {
      print('${pkg.name}: No internal dependencies, skipping');
      continue;
    }

    final pubspecFile = File('${packagesDir.path}/${pkg.name}/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('${pkg.name}: pubspec.yaml not found, skipping');
      continue;
    }

    var content = pubspecFile.readAsStringSync();

    for (final dep in deps) {
      content = _switchDependency(content, dep, mode, version);
    }

    pubspecFile.writeAsStringSync(content);
    print('${pkg.name}: Updated ${deps.join(", ")}');
  }

  print('\nDone! Run "dart pub get" in each package to update dependencies.');
}

String _readCurrentVersion(String repoRoot) {
  final packages = getPublishablePackages();
  if (packages.isEmpty) return '0.0.0';

  final pubspec = File(
    '$repoRoot/packages/${packages.first.name}/pubspec.yaml',
  );
  if (!pubspec.existsSync()) return '0.0.0';

  final content = pubspec.readAsStringSync();
  final match = RegExp(r'version:\s*(\S+)').firstMatch(content);
  return match?.group(1) ?? '0.0.0';
}

String _switchDependency(
  String content,
  String depName,
  String mode,
  String version,
) {
  final pathPattern = RegExp(
    '$depName:\\s*\\n\\s*path:\\s*[^\\n]+',
    multiLine: true,
  );
  final versionPattern = RegExp('$depName:\\s*\\^?[^\\n]+');

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
