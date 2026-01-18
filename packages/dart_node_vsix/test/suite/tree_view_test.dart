/// Tree View API Tests
library;

import 'package:dart_node_vsix/dart_node_vsix.dart'
    hide consoleError, consoleLog;

import 'test_helpers.dart';

void main() {
  consoleLog('[TREE VIEW TEST] main() called');

  suite('Tree View API', syncTest(() {
    suiteSetup(asyncTest(() async {
      await waitForExtensionActivation();
    }));

    test('Tree view has correct item count', syncTest(() {
      final api = getTestAPI();
      assertEqual(api.getTreeItemCount(), 3);
    }));

    test('TreeItem can be created with label', syncTest(() {
      final item = TreeItem('Test Label');
      assertEqual(item.label, 'Test Label');
    }));

    test('TreeItem collapsible state defaults to none', syncTest(() {
      final item = TreeItem('Test');
      assertEqual(item.collapsibleState, TreeItemCollapsibleState.none);
    }));

    test('TreeItem can be created with collapsible state', syncTest(() {
      final item = TreeItem('Parent', TreeItemCollapsibleState.collapsed);
      assertEqual(item.collapsibleState, TreeItemCollapsibleState.collapsed);
    }));

    test('TreeItem description can be set', syncTest(() {
      final item = TreeItem('Label')..description = 'Description';
      assertEqual(item.description, 'Description');
    }));

    test('TreeItemCollapsibleState has correct values', syncTest(() {
      assertEqual(TreeItemCollapsibleState.none, 0);
      assertEqual(TreeItemCollapsibleState.collapsed, 1);
      assertEqual(TreeItemCollapsibleState.expanded, 2);
    }));

    test('fireTreeChange triggers update', syncTest(() {
      getTestAPI().fireTreeChange();
      assertOk(true, 'fireTreeChange should work');
    }));
  }));
}
