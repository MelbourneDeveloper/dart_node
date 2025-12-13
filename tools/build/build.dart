import 'dart:io';

import 'package:node_preamble/preamble.dart' as preamble;

void main(List<String> args) {
  final target = args.isEmpty ? 'backend' : args.first;
  final result = build(target);
  result.isSuccess ? null : print(result.message);
  exit(result.isSuccess ? 0 : 1);
}

({bool isSuccess, String message}) build(String target) {
  final projectRoot = Directory.current.path;

  // Get all package dependencies first
  final packagesResult = _pubGetAllPackages(projectRoot);
  return !packagesResult.isSuccess
      ? packagesResult
      : _buildExample(projectRoot, target);
}

({bool isSuccess, String message}) _buildExample(
  String projectRoot,
  String target,
) {
  final exampleDir = '$projectRoot/examples/$target';
  final dir = Directory(exampleDir);
  return !dir.existsSync()
      ? (
          isSuccess: false,
          message: 'Example "$target" not found at $exampleDir',
        )
      : _buildTarget(exampleDir, target);
}

({bool isSuccess, String message}) _pubGetAllPackages(String projectRoot) {
  print('Getting dependencies for all packages...');
  final packagesDir = Directory('$projectRoot/packages');
  final examplesDir = Directory('$projectRoot/examples');

  final packages = packagesDir.existsSync()
      ? packagesDir.listSync().whereType<Directory>().toList()
      : <Directory>[];

  final examples = examplesDir.existsSync()
      ? examplesDir.listSync().whereType<Directory>().toList()
      : <Directory>[];

  return _pubGetPackages([...packages, ...examples]);
}

({bool isSuccess, String message}) _pubGetPackages(List<Directory> packages) {
  return packages.isEmpty
      ? (isSuccess: true, message: 'All packages ready')
      : _pubGetPackage(packages.first, packages.sublist(1));
}

({bool isSuccess, String message}) _pubGetPackage(
  Directory pkg,
  List<Directory> remaining,
) {
  final hasPubspec = File('${pkg.path}/pubspec.yaml').existsSync();
  return !hasPubspec
      ? _pubGetPackages(remaining)
      : () {
          print('  ${pkg.path.split('/').last}...');
          final result = Process.runSync('dart', [
            'pub',
            'get',
          ], workingDirectory: pkg.path);
          return result.exitCode != 0
              ? (
                  isSuccess: false,
                  message: 'pub get failed for ${pkg.path}:\n${result.stderr}',
                )
              : _npmInstallIfNeeded(pkg, remaining);
        }();
}

({bool isSuccess, String message}) _npmInstallIfNeeded(
  Directory pkg,
  List<Directory> remaining,
) {
  final npmDirs = _findNpmDirs(pkg);
  return _npmInstallDirs(npmDirs, remaining);
}

List<Directory> _findNpmDirs(Directory pkg) {
  final packageJson = File('${pkg.path}/package.json');
  final rnDir = Directory('${pkg.path}/rn');
  final rnPackageJson = File('${rnDir.path}/package.json');

  return [
    packageJson.existsSync() ? pkg : null,
    rnPackageJson.existsSync() ? rnDir : null,
  ].whereType<Directory>().toList();
}

({bool isSuccess, String message}) _npmInstallDirs(
  List<Directory> npmDirs,
  List<Directory> remainingPackages,
) {
  return npmDirs.isEmpty
      ? _pubGetPackages(remainingPackages)
      : _npmInstallDir(npmDirs.first, npmDirs.sublist(1), remainingPackages);
}

({bool isSuccess, String message}) _npmInstallDir(
  Directory dir,
  List<Directory> remainingNpm,
  List<Directory> remainingPackages,
) {
  final hasNodeModules = Directory('${dir.path}/node_modules').existsSync();
  return hasNodeModules
      ? _npmInstallDirs(remainingNpm, remainingPackages)
      : () {
          print('    npm install ${dir.path.split('/').last}...');
          final result = Process.runSync('npm', [
            'install',
          ], workingDirectory: dir.path);
          return result.exitCode != 0
              ? (
                  isSuccess: false,
                  message:
                      'npm install failed for ${dir.path}:\n${result.stderr}',
                )
              : _npmInstallDirs(remainingNpm, remainingPackages);
        }();
}

({bool isSuccess, String message}) _buildTarget(
  String exampleDir,
  String target,
) {
  print('Building $target...');

  // Resolve entry point
  final entryPoint = _findEntryPoint(exampleDir);
  return entryPoint == null
      ? (isSuccess: false, message: 'No entry point found in $exampleDir')
      : _compile(exampleDir, entryPoint, target);
}

String? _findEntryPoint(String exampleDir) {
  final candidates = [
    'bin/server.dart',
    'server.dart',
    'main.dart',
    'app.dart',
    'web/app.dart',
    'web/main.dart',
  ];
  return _searchEntryPoints(exampleDir, candidates);
}

String? _searchEntryPoints(String exampleDir, List<String> remaining) {
  return remaining.isEmpty
      ? null
      : () {
          final file = File('$exampleDir/${remaining.first}');
          return file.existsSync()
              ? file.path
              : _searchEntryPoints(exampleDir, remaining.sublist(1));
        }();
}

({bool isSuccess, String message}) _compile(
  String exampleDir,
  String entryPoint,
  String target,
) {
  final buildDir = '$exampleDir/build';
  Directory(buildDir).createSync(recursive: true);

  // Get dependencies first
  print('  Getting dependencies...');
  final pubGetResult = Process.runSync('dart', [
    'pub',
    'get',
  ], workingDirectory: exampleDir);

  if (pubGetResult.exitCode != 0) {
    return (
      isSuccess: false,
      message:
          'pub get failed:\n${pubGetResult.stdout}\n${pubGetResult.stderr}',
    );
  }

  // Transpile JSX files before compilation
  final jsxResult = _transpileJsxFiles(exampleDir);
  return !jsxResult.isSuccess
      ? jsxResult
      : _compileToJs(exampleDir, entryPoint, target, buildDir);
}

({bool isSuccess, String message}) _compileToJs(
  String exampleDir,
  String entryPoint,
  String target,
  String buildDir,
) {
  // Get output name from entry point (bin/server.dart -> bin/server.js)
  final entryRelative = entryPoint.replaceFirst('$exampleDir/', '');
  final outputPath = entryRelative.replaceAll('.dart', '.js');
  final outputDir =
      '$buildDir/${outputPath.contains('/') ? outputPath.substring(0, outputPath.lastIndexOf('/')) : ''}';
  Directory(outputDir).createSync(recursive: true);
  final outputName = outputPath.split('/').last;
  final tempOutput = '$outputDir/temp_$outputName';
  final finalOutput = '$outputDir/$outputName';

  print('  Compiling Dart to JS...');
  final compileResult = Process.runSync('dart', [
    'compile',
    'js',
    entryRelative,
    '-o',
    tempOutput,
    '-O2',
  ], workingDirectory: exampleDir);

  return compileResult.exitCode != 0
      ? (
          isSuccess: false,
          message:
              'Compilation failed:\n${compileResult.stdout}\n${compileResult.stderr}',
        )
      : _finalizeBuild(tempOutput, finalOutput, target);
}

({bool isSuccess, String message}) _finalizeBuild(
  String tempOutput,
  String finalOutput,
  String target,
) {
  // All targets need preamble - dart2js requires self.* globals
  return _prependPreamble(tempOutput, finalOutput);
}

({bool isSuccess, String message}) _prependPreamble(
  String tempOutput,
  String finalOutput,
) {
  print('  Adding Node.js preamble...');
  final compiledJs = File(tempOutput).readAsStringSync();
  final nodeJs = '${preamble.getPreamble()}\n$compiledJs';

  File(finalOutput).writeAsStringSync(nodeJs);
  File(tempOutput).deleteSync();

  print('  Build complete: $finalOutput');
  return (isSuccess: true, message: 'Build successful');
}

({bool isSuccess, String message}) _transpileJsxFiles(String exampleDir) {
  final dir = Directory(exampleDir);
  final jsxFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.jsx'))
      .toList();

  final hasJsxFiles = jsxFiles.isNotEmpty;
  if (!hasJsxFiles) {
    return (isSuccess: true, message: 'No JSX files to transpile');
  }

  print('  Transpiling ${jsxFiles.length} JSX file(s)...');

  for (final file in jsxFiles) {
    final result = _transpileJsxFile(file.path);
    if (!result.isSuccess) return result;
  }

  return (isSuccess: true, message: 'JSX transpilation complete');
}

({bool isSuccess, String message}) _transpileJsxFile(String inputPath) {
  final outputPath = inputPath.replaceAll('.jsx', '.g.dart');
  final projectRoot = Directory.current.path;

  final result = Process.runSync('dart', [
    'run',
    '$projectRoot/packages/dart_jsx/bin/jsx.dart',
    inputPath,
    outputPath,
  ]);

  return result.exitCode != 0
      ? (
          isSuccess: false,
          message: 'JSX transpilation failed for $inputPath:\n${result.stderr}',
        )
      : (isSuccess: true, message: 'Transpiled $inputPath');
}
