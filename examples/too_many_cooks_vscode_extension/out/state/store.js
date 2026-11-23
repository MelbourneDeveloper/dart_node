"use strict";
/**
 * State store - manages MCP client and syncs with signals.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.Store = void 0;
const client_1 = require("../mcp/client");
const signals_1 = require("./signals");
function getOutputChannel() {
    // Get the output channel created by extension.ts
    return globalThis._tooManyCooksOutput;
}
function log(message) {
    const timestamp = new Date().toISOString();
    const output = getOutputChannel();
    if (output) {
        output.appendLine(`[${timestamp}] [Store] ${message}`);
    }
}
class Store {
    client = null;
    serverPath;
    pollInterval = null;
    constructor(serverPath) {
        this.serverPath = serverPath;
        log(`Store created with serverPath: ${serverPath}`);
    }
    setServerPath(path) {
        this.serverPath = path;
    }
    async connect() {
        log(`connect() called, serverPath: ${this.serverPath}`);
        if (this.client?.isConnected()) {
            log('Already connected, returning');
            return;
        }
        signals_1.connectionStatus.value = 'connecting';
        log('Connection status: connecting');
        try {
            log('Creating McpClient...');
            this.client = new client_1.McpClient(this.serverPath);
            // Handle notifications
            this.client.on('notification', (event) => {
                log(`Notification received: ${event.event}`);
                this.handleNotification(event);
            });
            this.client.on('close', () => {
                log('Client closed');
                signals_1.connectionStatus.value = 'disconnected';
            });
            this.client.on('error', (err) => {
                log(`Client error: ${err}`);
            });
            this.client.on('log', (message) => {
                log(`[MCP Server] ${message.trim()}`);
            });
            log('Calling client.start()...');
            await this.client.start();
            log('Client started, subscribing...');
            await this.client.subscribe(['*']);
            log('Subscribed, refreshing status...');
            await this.refreshStatus();
            signals_1.connectionStatus.value = 'connected';
            log('Connection status: connected');
            // Start polling to pick up changes from other MCP server instances
            // (e.g., Claude Code registering agents in the shared database)
            this.pollInterval = setInterval(() => {
                if (this.isConnected()) {
                    this.refreshStatus().catch((err) => {
                        log(`Polling refresh failed: ${err}`);
                    });
                }
            }, 2000);
            log('Polling started (every 2s)');
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            log(`Connection failed: ${msg}`);
            signals_1.connectionStatus.value = 'disconnected';
            throw err;
        }
    }
    async disconnect() {
        if (this.pollInterval) {
            clearInterval(this.pollInterval);
            this.pollInterval = null;
            log('Polling stopped');
        }
        if (this.client) {
            await this.client.stop();
            this.client = null;
        }
        (0, signals_1.resetState)();
    }
    async refreshStatus() {
        if (!this.client?.isConnected()) {
            throw new Error('Not connected');
        }
        const statusJson = await this.client.callTool('status', {});
        const status = JSON.parse(statusJson);
        // Update agents
        signals_1.agents.value = status.agents.map((a) => ({
            agentName: a.agent_name,
            registeredAt: a.registered_at,
            lastActive: a.last_active,
        }));
        // Update locks
        signals_1.locks.value = status.locks.map((l) => ({
            filePath: l.file_path,
            agentName: l.agent_name,
            acquiredAt: l.acquired_at,
            expiresAt: l.expires_at,
            reason: l.reason,
            version: 1,
        }));
        // Update plans
        signals_1.plans.value = status.plans.map((p) => ({
            agentName: p.agent_name,
            goal: p.goal,
            currentTask: p.current_task,
            updatedAt: p.updated_at,
        }));
        // Update messages
        signals_1.messages.value = status.messages.map((m) => ({
            id: m.id,
            fromAgent: m.from_agent,
            toAgent: m.to_agent,
            content: m.content,
            createdAt: m.created_at,
            readAt: m.read_at,
        }));
    }
    handleNotification(event) {
        const payload = event.payload;
        switch (event.event) {
            case 'agent_registered': {
                const newAgent = {
                    agentName: payload.agent_name,
                    registeredAt: payload.registered_at,
                    lastActive: event.timestamp,
                };
                signals_1.agents.value = [...signals_1.agents.value, newAgent];
                break;
            }
            case 'lock_acquired': {
                const newLock = {
                    filePath: payload.file_path,
                    agentName: payload.agent_name,
                    acquiredAt: event.timestamp,
                    expiresAt: payload.expires_at,
                    reason: payload.reason,
                    version: 1,
                };
                // Remove any existing lock on this file, then add new one
                signals_1.locks.value = [
                    ...signals_1.locks.value.filter((l) => l.filePath !== newLock.filePath),
                    newLock,
                ];
                break;
            }
            case 'lock_released': {
                const filePath = payload.file_path;
                signals_1.locks.value = signals_1.locks.value.filter((l) => l.filePath !== filePath);
                break;
            }
            case 'lock_renewed': {
                const filePath = payload.file_path;
                const expiresAt = payload.expires_at;
                signals_1.locks.value = signals_1.locks.value.map((l) => l.filePath === filePath ? { ...l, expiresAt } : l);
                break;
            }
            case 'message_sent': {
                const newMessage = {
                    id: payload.message_id,
                    fromAgent: payload.from_agent,
                    toAgent: payload.to_agent,
                    content: payload.content,
                    createdAt: event.timestamp,
                    readAt: undefined,
                };
                signals_1.messages.value = [...signals_1.messages.value, newMessage];
                break;
            }
            case 'plan_updated': {
                const agentName = payload.agent_name;
                const newPlan = {
                    agentName,
                    goal: payload.goal,
                    currentTask: payload.current_task,
                    updatedAt: event.timestamp,
                };
                const existingIdx = signals_1.plans.value.findIndex((p) => p.agentName === agentName);
                if (existingIdx >= 0) {
                    signals_1.plans.value = [
                        ...signals_1.plans.value.slice(0, existingIdx),
                        newPlan,
                        ...signals_1.plans.value.slice(existingIdx + 1),
                    ];
                }
                else {
                    signals_1.plans.value = [...signals_1.plans.value, newPlan];
                }
                break;
            }
        }
    }
    isConnected() {
        return this.client?.isConnected() ?? false;
    }
    async callTool(name, args) {
        if (!this.client?.isConnected()) {
            throw new Error('Not connected');
        }
        return this.client.callTool(name, args);
    }
}
exports.Store = Store;
//# sourceMappingURL=store.js.map