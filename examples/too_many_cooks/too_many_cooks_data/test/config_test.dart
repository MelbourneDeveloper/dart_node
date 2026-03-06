/// Tests for configuration utilities.
library;

import 'package:test/test.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

void main() {
  test('resolveDbPath returns correct path', () {
    final path = resolveDbPath('/workspace/project');
    expect(path, '/workspace/project/.too_many_cooks/data.db');
  });

  test('createDataConfig uses provided values', () {
    final config = createDataConfig(
      dbPath: '/custom/path.db',
      lockTimeoutMs: 30000,
      maxMessageLength: 500,
      maxPlanLength: 200,
    );
    expect(config.dbPath, '/custom/path.db');
    expect(config.lockTimeoutMs, 30000);
    expect(config.maxMessageLength, 500);
    expect(config.maxPlanLength, 200);
  });

  test('createDataConfig uses defaults', () {
    final config = createDataConfig(dbPath: '/path.db');
    expect(config.dbPath, '/path.db');
    expect(config.lockTimeoutMs, defaultLockTimeoutMs);
    expect(config.maxMessageLength, defaultMaxMessageLength);
    expect(config.maxPlanLength, defaultMaxPlanLength);
  });

  test('createDataConfigFromWorkspace creates config with resolved path', () {
    final config = createDataConfigFromWorkspace('/my/workspace');
    expect(config.dbPath, '/my/workspace/.too_many_cooks/data.db');
    expect(config.lockTimeoutMs, defaultLockTimeoutMs);
    expect(config.maxMessageLength, defaultMaxMessageLength);
    expect(config.maxPlanLength, defaultMaxPlanLength);
  });

  test('default constants have expected values', () {
    expect(defaultLockTimeoutMs, 600000);
    expect(defaultMaxMessageLength, 200);
    expect(defaultMaxPlanLength, 100);
  });

  test('getWorkspaceFolder returns a non-empty string', () {
    final folder = getWorkspaceFolder();
    expect(folder, isNotEmpty);
  });

  test('defaultConfig uses getWorkspaceFolder for dbPath', () {
    final expected = resolveDbPath(getWorkspaceFolder());
    expect(defaultConfig.dbPath, expected);
  });

  test('defaultConfig dbPath always ends with .too_many_cooks/data.db', () {
    expect(defaultConfig.dbPath, endsWith('.too_many_cooks/data.db'));
  });

  test('defaultConfig uses default timeout and limits', () {
    expect(defaultConfig.lockTimeoutMs, defaultLockTimeoutMs);
    expect(defaultConfig.maxMessageLength, defaultMaxMessageLength);
    expect(defaultConfig.maxPlanLength, defaultMaxPlanLength);
  });

  test('defaultConfig dbPath matches createDataConfigFromWorkspace', () {
    final fromWorkspace = createDataConfigFromWorkspace(getWorkspaceFolder());
    expect(defaultConfig.dbPath, fromWorkspace.dbPath);
  });
}
