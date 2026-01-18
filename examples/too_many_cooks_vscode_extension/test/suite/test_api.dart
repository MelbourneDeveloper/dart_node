/// TestAPI interface for accessing extension exports in integration tests.
///
/// This mirrors the TestAPI exposed by the Dart extension for testing.
/// Uses typed extension types from dart_node_vsix for type-safe access.
library;

import 'dart:js_interop';

// Import JS interop types explicitly (not exported from main library to avoid
// conflicts with app's internal typedef records like AgentDetails, FileLock).
import 'package:dart_node_vsix/src/js_helpers.dart'
    show
        JSAgentDetails,
        JSAgentIdentity,
        JSAgentPlan,
        JSFileLock,
        JSMessage,
        JSTreeItemSnapshot;

/// TestAPI wrapper for the extension's exported test interface.
///
/// All methods return strongly-typed values that match the TypeScript
/// TestAPI interface. No raw JSObject exposure.
extension type TestAPI(JSObject _) implements JSObject {
  // ==========================================================================
  // State getters - return typed arrays matching TypeScript interfaces
  // ==========================================================================

  /// Get all registered agents.
  external JSArray<JSAgentIdentity> getAgents();

  /// Get all active file locks.
  external JSArray<JSFileLock> getLocks();

  /// Get all messages.
  external JSArray<JSMessage> getMessages();

  /// Get all agent plans.
  external JSArray<JSAgentPlan> getPlans();

  /// Get current connection status ('connected', 'connecting', 'disconnected').
  external String getConnectionStatus();

  // ==========================================================================
  // Computed getters
  // ==========================================================================

  /// Get the number of registered agents.
  external int getAgentCount();

  /// Get the number of active locks.
  external int getLockCount();

  /// Get the total number of messages.
  external int getMessageCount();

  /// Get the number of unread messages.
  external int getUnreadMessageCount();

  /// Get detailed info for each agent (agent + their locks, messages, plan).
  external JSArray<JSAgentDetails> getAgentDetails();

  // ==========================================================================
  // Store actions
  // ==========================================================================

  /// Connect to the MCP server.
  external JSPromise<JSAny?> connect();

  /// Disconnect from the MCP server.
  external JSPromise<JSAny?> disconnect();

  /// Refresh state from the MCP server.
  external JSPromise<JSAny?> refreshStatus();

  /// Check if currently connected to the MCP server.
  external bool isConnected();

  /// Check if currently connecting to the MCP server.
  external bool isConnecting();

  /// Call an MCP tool by name with the given arguments.
  external JSPromise<JSString> callTool(String name, JSObject args);

  /// Force release a lock (admin operation).
  external JSPromise<JSAny?> forceReleaseLock(String filePath);

  /// Delete an agent (admin operation).
  external JSPromise<JSAny?> deleteAgent(String agentName);

  /// Send a message from one agent to another.
  external JSPromise<JSAny?> sendMessage(
    String fromAgent,
    String toAgent,
    String content,
  );

  // ==========================================================================
  // Tree view queries
  // ==========================================================================

  /// Get the number of items in the locks tree.
  external int getLockTreeItemCount();

  /// Get the number of items in the messages tree.
  external int getMessageTreeItemCount();

  // ==========================================================================
  // Tree snapshots - return typed TreeItemSnapshot arrays
  // ==========================================================================

  /// Get a snapshot of the agents tree view.
  external JSArray<JSTreeItemSnapshot> getAgentsTreeSnapshot();

  /// Get a snapshot of the locks tree view.
  external JSArray<JSTreeItemSnapshot> getLocksTreeSnapshot();

  /// Get a snapshot of the messages tree view.
  external JSArray<JSTreeItemSnapshot> getMessagesTreeSnapshot();

  // ==========================================================================
  // Find in tree - return typed TreeItemSnapshot
  // ==========================================================================

  /// Find an agent in the tree by name.
  external JSTreeItemSnapshot? findAgentInTree(String agentName);

  /// Find a lock in the tree by file path.
  external JSTreeItemSnapshot? findLockInTree(String filePath);

  /// Find a message in the tree by content.
  external JSTreeItemSnapshot? findMessageInTree(String content);

  // ==========================================================================
  // Logging
  // ==========================================================================

  /// Get all log messages produced by the extension.
  external JSArray<JSString> getLogMessages();
}
