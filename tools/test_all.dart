// ignore_for_file: avoid_print
import 'dart:io';

import 'lib/packages.dart';

void main() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final repoRoot = scriptDir.parent.path;
  final coverageCli = '$repoRoot/packages/dart_node_coverage/bin/coverage.dart';

  print('============================================');
  print('Running all tests with coverage');
  print('============================================');

  final passed = <String>[];
  final failed = <String>[];

  // Node.js packages
  print('\n--- Node.js Packages (with coverage) ---');
  for (final pkg in getPackagesByTestPlatform(TestPlatform.node)) {
    final result = _runNodeCoverage(repoRoot, pkg.name, coverageCli);
    (result ? passed : failed).add(pkg.name);
  }

  // VM packages
  print('\n--- VM Packages ---');
  for (final pkg in getPackagesByTestPlatform(TestPlatform.vm)) {
    final result = _runVmTest(repoRoot, pkg.name);
    (result ? passed : failed).add(pkg.name);
  }

  // Browser packages
  print('\n--- Browser Packages ---');
  for (final pkg in getPackagesByTestPlatform(TestPlatform.browser)) {
    final result = _runBrowserTest(repoRoot, pkg.name);
    (result ? passed : failed).add(pkg.name);
  }

  // Examples
  print('\n--- Examples ---');
  final examplesDir = Directory('$repoRoot/examples');
  if (examplesDir.existsSync()) {
    for (final dir in examplesDir.listSync().whereType<Directory>()) {
      final name = dir.path.split('/').last;
      final testDir = Directory('${dir.path}/test');
      if (testDir.existsSync()) {
        final result = _runExampleTest(dir.path, name);
        (result ? passed : failed).add('examples/$name');
      } else {
        print('\n\x1B[33mSKIP\x1B[0m examples/$name (no tests)');
      }
    }
  }

  // Summary
  print('\n============================================');
  print('SUMMARY');
  print('============================================');
  print('\x1B[32mPassed:\x1B[0m ${passed.length}');
  for (final p in passed) {
    print('  ✓ $p');
  }

  if (failed.isNotEmpty) {
    print('\x1B[31mFailed:\x1B[0m ${failed.length}');
    for (final f in failed) {
      print('  ✗ $f');
    }
    exit(1);
  } else {
    print('\n\x1B[32mAll tests passed!\x1B[0m');
  }
}

bool _runNodeCoverage(String repoRoot, String pkg, String coverageCli) {
  final pkgDir = '$repoRoot/packages/$pkg';
  if (!Directory(pkgDir).existsSync()) {
    print('\n\x1B[33mSKIP\x1B[0m $pkg (not found)');
    return true;
  }

  print('\n\x1B[33mTesting\x1B[0m $pkg (Node.js + coverage)...');

  var result = Process.runSync('dart', ['pub', 'get'], workingDirectory: pkgDir);
  if (result.exitCode != 0) {
    print('\x1B[31mFAIL\x1B[0m $pkg (pub get failed)');
    return false;
  }

  result = Process.runSync('dart', ['run', coverageCli], workingDirectory: pkgDir);
  if (result.exitCode != 0) {
    print('\x1B[31mFAIL\x1B[0m $pkg');
    print(result.stdout);
    print(result.stderr);
    return false;
  }

  print('\x1B[32mPASS\x1B[0m $pkg');
  return true;
}

bool _runVmTest(String repoRoot, String pkg) {
  final pkgDir = '$repoRoot/packages/$pkg';
  if (!Directory(pkgDir).existsSync()) {
    print('\n\x1B[33mSKIP\x1B[0m $pkg (not found)');
    return true;
  }

  print('\n\x1B[33mTesting\x1B[0m $pkg (VM)...');

  var result = Process.runSync('dart', ['pub', 'get'], workingDirectory: pkgDir);
  if (result.exitCode != 0) {
    print('\x1B[31mFAIL\x1B[0m $pkg (pub get failed)');
    return false;
  }

  result = Process.runSync('dart', ['test'], workingDirectory: pkgDir);
  if (result.exitCode != 0) {
    print('\x1B[31mFAIL\x1B[0m $pkg');
    print(result.stdout);
    print(result.stderr);
    return false;
  }

  print('\x1B[32mPASS\x1B[0m $pkg');
  return true;
}

bool _runBrowserTest(String repoRoot, String pkg) {
  final pkgDir = '$repoRoot/packages/$pkg';
  if (!Directory(pkgDir).existsSync()) {
    print('\n\x1B[33mSKIP\x1B[0m $pkg (not found)');
    return true;
  }

  print('\n\x1B[33mTesting\x1B[0m $pkg (Browser)...');

  var result = Process.runSync('dart', ['pub', 'get'], workingDirectory: pkgDir);
  if (result.exitCode != 0) {
    print('\x1B[31mFAIL\x1B[0m $pkg (pub get failed)');
    return false;
  }

  result = Process.runSync('dart', ['test'], workingDirectory: pkgDir);
  if (result.exitCode != 0) {
    print('\x1B[31mFAIL\x1B[0m $pkg');
    print(result.stdout);
    print(result.stderr);
    return false;
  }

  print('\x1B[32mPASS\x1B[0m $pkg');
  return true;
}

bool _runExampleTest(String exampleDir, String name) {
  print('\n\x1B[33mTesting\x1B[0m examples/$name...');

  var result = Process.runSync('dart', ['pub', 'get'], workingDirectory: exampleDir);
  if (result.exitCode != 0) {
    print('\x1B[31mFAIL\x1B[0m examples/$name (pub get failed)');
    return false;
  }

  result = Process.runSync('dart', ['test'], workingDirectory: exampleDir);
  if (result.exitCode != 0) {
    print('\x1B[31mFAIL\x1B[0m examples/$name');
    print(result.stdout);
    print(result.stderr);
    return false;
  }

  print('\x1B[32mPASS\x1B[0m examples/$name');
  return true;
}
