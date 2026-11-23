"use strict";
/**
 * Test API exposed for integration tests.
 * This allows tests to inspect internal state and trigger actions.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.addLogMessage = addLogMessage;
exports.getLogMessages = getLogMessages;
exports.clearLogMessages = clearLogMessages;
exports.createTestAPI = createTestAPI;
const signals_1 = require("./state/signals");
// Global log storage for testing
const logMessages = [];
function addLogMessage(message) {
    logMessages.push(message);
}
function getLogMessages() {
    return [...logMessages];
}
function clearLogMessages() {
    logMessages.length = 0;
}
/** Convert a VSCode TreeItem to a serializable snapshot */
function toSnapshot(item, getChildren) {
    const labelStr = typeof item.label === 'string' ? item.label : item.label?.label ?? '';
    const descStr = typeof item.description === 'string' ? item.description : undefined;
    const snapshot = { label: labelStr };
    if (descStr)
        snapshot.description = descStr;
    if (getChildren) {
        const children = getChildren();
        if (children.length > 0)
            snapshot.children = children;
    }
    return snapshot;
}
/** Build agent tree snapshot */
function buildAgentsSnapshot(providers) {
    const items = providers.agents.getChildren() ?? [];
    return items.map(item => toSnapshot(item, () => {
        const children = providers.agents.getChildren(item) ?? [];
        return children.map(child => toSnapshot(child));
    }));
}
/** Build locks tree snapshot */
function buildLocksSnapshot(providers) {
    const categories = providers.locks.getChildren() ?? [];
    return categories.map(cat => toSnapshot(cat, () => {
        const children = providers.locks.getChildren(cat) ?? [];
        return children.map(child => toSnapshot(child));
    }));
}
/** Build messages tree snapshot */
function buildMessagesSnapshot(providers) {
    const items = providers.messages.getChildren() ?? [];
    return items.map(item => toSnapshot(item));
}
/** Build plans tree snapshot */
function buildPlansSnapshot(providers) {
    const items = providers.plans.getChildren() ?? [];
    return items.map(item => toSnapshot(item, () => {
        const children = providers.plans.getChildren(item) ?? [];
        return children.map(child => toSnapshot(child));
    }));
}
/** Search tree items recursively for a label match */
function findInTree(items, predicate) {
    for (const item of items) {
        if (predicate(item))
            return item;
        if (item.children) {
            const found = findInTree(item.children, predicate);
            if (found)
                return found;
        }
    }
    return undefined;
}
function createTestAPI(store, providers) {
    return {
        getAgents: () => signals_1.agents.value,
        getLocks: () => signals_1.locks.value,
        getMessages: () => signals_1.messages.value,
        getPlans: () => signals_1.plans.value,
        getConnectionStatus: () => signals_1.connectionStatus.value,
        getAgentCount: () => signals_1.agentCount.value,
        getLockCount: () => signals_1.lockCount.value,
        getMessageCount: () => signals_1.messageCount.value,
        getUnreadMessageCount: () => signals_1.unreadMessageCount.value,
        getAgentDetails: () => signals_1.agentDetails.value,
        connect: () => store.connect(),
        disconnect: () => store.disconnect(),
        refreshStatus: () => store.refreshStatus(),
        isConnected: () => store.isConnected(),
        callTool: (name, args) => store.callTool(name, args),
        // Tree view queries - these query the ACTUAL tree provider state
        getAgentTreeItems: () => providers.agents.getChildren() ?? [],
        getAgentTreeChildren: (agentName) => {
            const agentItems = providers.agents.getChildren() ?? [];
            const agentItem = agentItems.find((item) => item.agentName === agentName);
            return agentItem ? providers.agents.getChildren(agentItem) ?? [] : [];
        },
        getLockTreeItemCount: () => {
            // Sum lock items across all categories (Active, Expired)
            const categories = providers.locks.getChildren() ?? [];
            return categories.reduce((sum, cat) => {
                const children = providers.locks.getChildren(cat) ?? [];
                return sum + children.length;
            }, 0);
        },
        getMessageTreeItemCount: () => {
            // Count only items with actual messages (not "No messages" placeholder)
            const items = providers.messages.getChildren() ?? [];
            return items.filter((item) => item.message !== undefined).length;
        },
        getPlanTreeItemCount: () => {
            // Count only items with actual plans (not "No plans" placeholder)
            const items = providers.plans.getChildren() ?? [];
            return items.filter((item) => item.plan !== undefined).length;
        },
        // Full tree snapshots - PROOF of what's displayed in UI
        getAgentsTreeSnapshot: () => buildAgentsSnapshot(providers),
        getLocksTreeSnapshot: () => buildLocksSnapshot(providers),
        getMessagesTreeSnapshot: () => buildMessagesSnapshot(providers),
        getPlansTreeSnapshot: () => buildPlansSnapshot(providers),
        // Find specific items - search the tree for exact content
        findAgentInTree: (agentName) => {
            const snapshot = buildAgentsSnapshot(providers);
            return findInTree(snapshot, item => item.label === agentName);
        },
        findLockInTree: (filePath) => {
            const snapshot = buildLocksSnapshot(providers);
            return findInTree(snapshot, item => item.label === filePath);
        },
        findMessageInTree: (content) => {
            const snapshot = buildMessagesSnapshot(providers);
            return findInTree(snapshot, item => item.description?.includes(content) ?? false);
        },
        findPlanInTree: (agentName) => {
            const snapshot = buildPlansSnapshot(providers);
            return findInTree(snapshot, item => item.label === agentName);
        },
        // Logging
        getLogMessages: () => getLogMessages(),
    };
}
//# sourceMappingURL=test-api.js.map