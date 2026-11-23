"use strict";
/**
 * Signal-based state management using @preact/signals-core.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.locksByFile = exports.agentDetails = exports.expiredLocks = exports.activeLocks = exports.unreadMessageCount = exports.messageCount = exports.lockCount = exports.agentCount = exports.plans = exports.messages = exports.locks = exports.agents = exports.connectionStatus = void 0;
exports.resetState = resetState;
const signals_core_1 = require("@preact/signals-core");
exports.connectionStatus = (0, signals_core_1.signal)('disconnected');
// Core data signals
exports.agents = (0, signals_core_1.signal)([]);
exports.locks = (0, signals_core_1.signal)([]);
exports.messages = (0, signals_core_1.signal)([]);
exports.plans = (0, signals_core_1.signal)([]);
// Computed values
exports.agentCount = (0, signals_core_1.computed)(() => exports.agents.value.length);
exports.lockCount = (0, signals_core_1.computed)(() => exports.locks.value.length);
exports.messageCount = (0, signals_core_1.computed)(() => exports.messages.value.length);
exports.unreadMessageCount = (0, signals_core_1.computed)(() => exports.messages.value.filter((m) => m.readAt === undefined).length);
exports.activeLocks = (0, signals_core_1.computed)(() => exports.locks.value.filter((l) => l.expiresAt > Date.now()));
exports.expiredLocks = (0, signals_core_1.computed)(() => exports.locks.value.filter((l) => l.expiresAt <= Date.now()));
exports.agentDetails = (0, signals_core_1.computed)(() => exports.agents.value.map((agent) => ({
    agent,
    locks: exports.locks.value.filter((l) => l.agentName === agent.agentName),
    plan: exports.plans.value.find((p) => p.agentName === agent.agentName),
    sentMessages: exports.messages.value.filter((m) => m.fromAgent === agent.agentName),
    receivedMessages: exports.messages.value.filter((m) => m.toAgent === agent.agentName || m.toAgent === '*'),
})));
/** Locks grouped by file path. */
exports.locksByFile = (0, signals_core_1.computed)(() => {
    const byFile = new Map();
    for (const lock of exports.locks.value) {
        byFile.set(lock.filePath, lock);
    }
    return byFile;
});
/** Reset all state. */
function resetState() {
    exports.connectionStatus.value = 'disconnected';
    exports.agents.value = [];
    exports.locks.value = [];
    exports.messages.value = [];
    exports.plans.value = [];
}
//# sourceMappingURL=signals.js.map