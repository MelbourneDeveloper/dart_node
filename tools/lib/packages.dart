// ignore_for_file: avoid_print
import 'dart:io';

/// Package metadata - single source of truth for all tooling
/// Dependencies are read from pubspec.yaml files
/// Test platforms and tiers are defined here
class PackageConfig {
  final String name;
  final int tier;
  final TestPlatform testPlatform;
  final bool publish;

  const PackageConfig({
    required this.name,
    required this.tier,
    required this.testPlatform,
    this.publish = true,
  });
}

enum TestPlatform { node, vm, browser }

/// Package configurations - defines tier, test platform, and publish status
/// Add new packages here when created
const _packageConfigs = <String, PackageConfig>{
  // Tier 1 - no internal dependencies
  'dart_logging': PackageConfig(
    name: 'dart_logging',
    tier: 1,
    testPlatform: TestPlatform.vm,
  ),
  'dart_node_core': PackageConfig(
    name: 'dart_node_core',
    tier: 1,
    testPlatform: TestPlatform.node,
  ),
  // Tier 2 - depends on tier 1
  'reflux': PackageConfig(
    name: 'reflux',
    tier: 2,
    testPlatform: TestPlatform.vm,
  ),
  'dart_node_express': PackageConfig(
    name: 'dart_node_express',
    tier: 2,
    testPlatform: TestPlatform.node,
  ),
  'dart_node_ws': PackageConfig(
    name: 'dart_node_ws',
    tier: 2,
    testPlatform: TestPlatform.node,
  ),
  'dart_node_better_sqlite3': PackageConfig(
    name: 'dart_node_better_sqlite3',
    tier: 2,
    testPlatform: TestPlatform.node,
  ),
  'dart_node_mcp': PackageConfig(
    name: 'dart_node_mcp',
    tier: 2,
    testPlatform: TestPlatform.node,
  ),
  // Tier 3 - depends on tier 2
  'dart_node_react': PackageConfig(
    name: 'dart_node_react',
    tier: 3,
    testPlatform: TestPlatform.browser,
  ),
  'dart_node_react_native': PackageConfig(
    name: 'dart_node_react_native',
    tier: 3,
    testPlatform: TestPlatform.node,
  ),
  // Non-published packages
  'dart_node_coverage': PackageConfig(
    name: 'dart_node_coverage',
    tier: 0,
    testPlatform: TestPlatform.vm,
    publish: false,
  ),
};

/// Discovers packages from the filesystem that have pubspec.yaml
List<String> discoverPackages(String repoRoot) {
  final packagesDir = Directory('$repoRoot/packages');
  if (!packagesDir.existsSync()) return [];

  return packagesDir
      .listSync()
      .whereType<Directory>()
      .where((d) => File('${d.path}/pubspec.yaml').existsSync())
      .map((d) => d.path.split('/').last)
      .toList()
    ..sort();
}

/// Gets config for a package, returns null if not configured
PackageConfig? getPackageConfig(String name) => _packageConfigs[name];

/// Gets all publishable packages in tier order
List<PackageConfig> getPublishablePackages() {
  final packages =
      _packageConfigs.values.where((p) => p.publish).toList()
        ..sort((a, b) {
          final tierCmp = a.tier.compareTo(b.tier);
          return tierCmp != 0 ? tierCmp : a.name.compareTo(b.name);
        });
  return packages;
}

/// Gets packages by tier
List<PackageConfig> getPackagesByTier(int tier) =>
    _packageConfigs.values.where((p) => p.tier == tier && p.publish).toList();

/// Gets packages by test platform
List<PackageConfig> getPackagesByTestPlatform(TestPlatform platform) =>
    _packageConfigs.values.where((p) => p.testPlatform == platform).toList();

/// Reads internal dependencies from a package's pubspec.yaml
/// Returns list of dependency names that are publishable internal packages
List<String> getInternalDependencies(String repoRoot, String packageName) {
  final pubspecFile =
      File('$repoRoot/packages/$packageName/pubspec.yaml');
  if (!pubspecFile.existsSync()) return [];

  final content = pubspecFile.readAsStringSync();
  final publishablePackages =
      getPublishablePackages().map((p) => p.name).toList();

  return publishablePackages
      .where((pkg) => pkg != packageName && content.contains('$pkg:'))
      .toList();
}

/// Validates that all discovered packages have configs
/// Returns list of packages without configs
List<String> validatePackageConfigs(String repoRoot) {
  final discovered = discoverPackages(repoRoot);
  return discovered.where((p) => !_packageConfigs.containsKey(p)).toList();
}
