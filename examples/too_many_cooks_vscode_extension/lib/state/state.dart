/// State management for Too Many Cooks VSCode extension using Reflux.
///
/// This is the Dart port of signals.ts, using Reflux for Redux-style
/// state management instead of Preact signals.
library;

import 'package:reflux/reflux.dart';

import 'package:too_many_cooks_vscode_extension/mcp/types.dart';

// Re-export types for convenience
export 'package:too_many_cooks_vscode_extension/mcp/types.dart'
    show AgentIdentity, AgentPlan, FileLock, Message;

/// Connection status to the MCP server.
enum ConnectionStatus {
  /// Not connected to the MCP server.
  disconnected,

  /// Currently establishing connection to the MCP server.
  connecting,

  /// Successfully connected to the MCP server.
  connected,
}

/// Agent with their associated data (computed/derived state).
typedef AgentDetails = ({
  AgentIdentity agent,
  List<FileLock> locks,
  AgentPlan? plan,
  List<Message> sentMessages,
  List<Message> receivedMessages,
});

/// The complete application state.
typedef AppState = ({
  ConnectionStatus connectionStatus,
  List<AgentIdentity> agents,
  List<FileLock> locks,
  List<Message> messages,
  List<AgentPlan> plans,
});

/// Initial state.
const AppState initialState = (
  connectionStatus: ConnectionStatus.disconnected,
  agents: [],
  locks: [],
  messages: [],
  plans: [],
);

// ============================================================================
// Actions
// ============================================================================

/// Base action for all state changes.
sealed class AppAction extends Action {}

/// Set connection status.
final class SetConnectionStatus extends AppAction {
  /// Creates a set connection status action.
  SetConnectionStatus(this.status);

  /// The new connection status.
  final ConnectionStatus status;
}

/// Set all agents.
final class SetAgents extends AppAction {
  /// Creates a set agents action.
  SetAgents(this.agents);

  /// The list of agents to set.
  final List<AgentIdentity> agents;
}

/// Add a single agent.
final class AddAgent extends AppAction {
  /// Creates an add agent action.
  AddAgent(this.agent);

  /// The agent to add.
  final AgentIdentity agent;
}

/// Remove an agent.
final class RemoveAgent extends AppAction {
  /// Creates a remove agent action.
  RemoveAgent(this.agentName);

  /// The name of the agent to remove.
  final String agentName;
}

/// Set all locks.
final class SetLocks extends AppAction {
  /// Creates a set locks action.
  SetLocks(this.locks);

  /// The list of locks to set.
  final List<FileLock> locks;
}

/// Add or update a lock.
final class UpsertLock extends AppAction {
  /// Creates an upsert lock action.
  UpsertLock(this.lock);

  /// The lock to add or update.
  final FileLock lock;
}

/// Remove a lock by file path.
final class RemoveLock extends AppAction {
  /// Creates a remove lock action.
  RemoveLock(this.filePath);

  /// The file path of the lock to remove.
  final String filePath;
}

/// Renew a lock's expiry time.
final class RenewLock extends AppAction {
  /// Creates a renew lock action.
  RenewLock(this.filePath, this.expiresAt);

  /// The file path of the lock to renew.
  final String filePath;

  /// The new expiration timestamp.
  final int expiresAt;
}

/// Set all messages.
final class SetMessages extends AppAction {
  /// Creates a set messages action.
  SetMessages(this.messages);

  /// The list of messages to set.
  final List<Message> messages;
}

/// Add a message.
final class AddMessage extends AppAction {
  /// Creates an add message action.
  AddMessage(this.message);

  /// The message to add.
  final Message message;
}

/// Set all plans.
final class SetPlans extends AppAction {
  /// Creates a set plans action.
  SetPlans(this.plans);

  /// The list of plans to set.
  final List<AgentPlan> plans;
}

/// Update or add a plan.
final class UpsertPlan extends AppAction {
  /// Creates an upsert plan action.
  UpsertPlan(this.plan);

  /// The plan to add or update.
  final AgentPlan plan;
}

/// Reset all state to initial values.
final class ResetState extends AppAction {}

// ============================================================================
// Reducer
// ============================================================================

/// Main reducer for the application state.
AppState appReducer(AppState state, Action action) => switch (action) {
  SetConnectionStatus(:final status) => (
    connectionStatus: status,
    agents: state.agents,
    locks: state.locks,
    messages: state.messages,
    plans: state.plans,
  ),
  SetAgents(:final agents) => (
    connectionStatus: state.connectionStatus,
    agents: agents,
    locks: state.locks,
    messages: state.messages,
    plans: state.plans,
  ),
  AddAgent(:final agent) => (
    connectionStatus: state.connectionStatus,
    agents: [...state.agents, agent],
    locks: state.locks,
    messages: state.messages,
    plans: state.plans,
  ),
  RemoveAgent(:final agentName) => (
    connectionStatus: state.connectionStatus,
    agents: state.agents.where((a) => a.agentName != agentName).toList(),
    locks: state.locks.where((l) => l.agentName != agentName).toList(),
    messages: state.messages,
    plans: state.plans.where((p) => p.agentName != agentName).toList(),
  ),
  SetLocks(:final locks) => (
    connectionStatus: state.connectionStatus,
    agents: state.agents,
    locks: locks,
    messages: state.messages,
    plans: state.plans,
  ),
  UpsertLock(:final lock) => (
    connectionStatus: state.connectionStatus,
    agents: state.agents,
    locks: [...state.locks.where((l) => l.filePath != lock.filePath), lock],
    messages: state.messages,
    plans: state.plans,
  ),
  RemoveLock(:final filePath) => (
    connectionStatus: state.connectionStatus,
    agents: state.agents,
    locks: state.locks.where((l) => l.filePath != filePath).toList(),
    messages: state.messages,
    plans: state.plans,
  ),
  RenewLock(:final filePath, :final expiresAt) => (
    connectionStatus: state.connectionStatus,
    agents: state.agents,
    locks: state.locks.map((l) {
      if (l.filePath == filePath) {
        return (
          filePath: l.filePath,
          agentName: l.agentName,
          acquiredAt: l.acquiredAt,
          expiresAt: expiresAt,
          reason: l.reason,
          version: l.version,
        );
      }
      return l;
    }).toList(),
    messages: state.messages,
    plans: state.plans,
  ),
  SetMessages(:final messages) => (
    connectionStatus: state.connectionStatus,
    agents: state.agents,
    locks: state.locks,
    messages: messages,
    plans: state.plans,
  ),
  AddMessage(:final message) => (
    connectionStatus: state.connectionStatus,
    agents: state.agents,
    locks: state.locks,
    messages: [...state.messages, message],
    plans: state.plans,
  ),
  SetPlans(:final plans) => (
    connectionStatus: state.connectionStatus,
    agents: state.agents,
    locks: state.locks,
    messages: state.messages,
    plans: plans,
  ),
  UpsertPlan(:final plan) => (
    connectionStatus: state.connectionStatus,
    agents: state.agents,
    locks: state.locks,
    messages: state.messages,
    plans: [...state.plans.where((p) => p.agentName != plan.agentName), plan],
  ),
  ResetState() => initialState,
  _ => state,
};

// ============================================================================
// Selectors (computed values, equivalent to computed() in signals)
// ============================================================================

/// Select connection status.
ConnectionStatus selectConnectionStatus(AppState state) =>
    state.connectionStatus;

/// Select all agents.
List<AgentIdentity> selectAgents(AppState state) => state.agents;

/// Select all locks.
List<FileLock> selectLocks(AppState state) => state.locks;

/// Select all messages.
List<Message> selectMessages(AppState state) => state.messages;

/// Select all plans.
List<AgentPlan> selectPlans(AppState state) => state.plans;

/// Select agent count.
int selectAgentCount(AppState state) => state.agents.length;

/// Select lock count.
int selectLockCount(AppState state) => state.locks.length;

/// Select message count.
int selectMessageCount(AppState state) => state.messages.length;

/// Select unread message count.
final selectUnreadMessageCount = createSelector1<AppState, List<Message>, int>(
  selectMessages,
  (messages) => messages.where((m) => m.readAt == null).length,
);

/// Select active locks (not expired).
final selectActiveLocks =
    createSelector1<AppState, List<FileLock>, List<FileLock>>(selectLocks, (
      locks,
    ) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return locks.where((l) => l.expiresAt > now).toList();
    });

/// Select expired locks.
final selectExpiredLocks =
    createSelector1<AppState, List<FileLock>, List<FileLock>>(selectLocks, (
      locks,
    ) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return locks.where((l) => l.expiresAt <= now).toList();
    });

/// Select agent details (agent with their associated data).
final selectAgentDetails =
    createSelector4<
      AppState,
      List<AgentIdentity>,
      List<FileLock>,
      List<AgentPlan>,
      List<Message>,
      List<AgentDetails>
    >(
      selectAgents,
      selectLocks,
      selectPlans,
      selectMessages,
      (agents, locks, plans, messages) => agents
          .map(
            (agent) => (
              agent: agent,
              locks: locks
                  .where((l) => l.agentName == agent.agentName)
                  .toList(),
              plan: plans
                  .where((p) => p.agentName == agent.agentName)
                  .firstOrNull,
              sentMessages: messages
                  .where((m) => m.fromAgent == agent.agentName)
                  .toList(),
              receivedMessages: messages
                  .where(
                    (m) => m.toAgent == agent.agentName || m.toAgent == '*',
                  )
                  .toList(),
            ),
          )
          .toList(),
    );

// ============================================================================
// Store creation helper
// ============================================================================

/// Create the application store.
Store<AppState> createAppStore() => createStore(appReducer, initialState);
