"use strict";
/**
 * MCP Client - communicates with Too Many Cooks server via stdio JSON-RPC.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.McpClient = void 0;
const child_process_1 = require("child_process");
const events_1 = require("events");
class McpClient extends events_1.EventEmitter {
    process = null;
    buffer = '';
    pending = new Map();
    nextId = 1;
    serverPath;
    initialized = false;
    constructor(serverPath) {
        super();
        this.serverPath = serverPath;
    }
    on(event, listener) {
        return super.on(event, listener);
    }
    emit(event, ...args) {
        return super.emit(event, ...args);
    }
    async start() {
        this.process = (0, child_process_1.spawn)('node', [this.serverPath], {
            stdio: ['pipe', 'pipe', 'pipe'],
        });
        this.process.stdout?.on('data', (chunk) => this.onData(chunk));
        this.process.stderr?.on('data', (chunk) => {
            this.emit('log', chunk.toString());
        });
        this.process.on('close', () => {
            this.emit('close');
        });
        this.process.on('error', (err) => {
            this.emit('error', err);
        });
        // Initialize MCP connection
        await this.request('initialize', {
            protocolVersion: '2024-11-05',
            capabilities: {},
            clientInfo: { name: 'too-many-cooks-vscode', version: '0.1.0' },
        });
        // Send initialized notification
        this.notify('notifications/initialized', {});
        this.initialized = true;
    }
    async callTool(name, args) {
        const result = (await this.request('tools/call', {
            name,
            arguments: args,
        }));
        const content = result.content[0];
        if (result.isError) {
            throw new Error(content?.text ?? 'Unknown error');
        }
        return content?.text ?? '{}';
    }
    async subscribe(events = ['*']) {
        await this.callTool('subscribe', {
            action: 'subscribe',
            subscriber_id: 'vscode-extension',
            events,
        });
    }
    async unsubscribe() {
        try {
            await this.callTool('subscribe', {
                action: 'unsubscribe',
                subscriber_id: 'vscode-extension',
            });
        }
        catch {
            // Ignore errors during unsubscribe
        }
    }
    request(method, params) {
        return new Promise((resolve, reject) => {
            const id = this.nextId++;
            this.pending.set(id, { resolve, reject });
            this.send({ jsonrpc: '2.0', id, method, params });
        });
    }
    notify(method, params) {
        this.send({ jsonrpc: '2.0', method, params });
    }
    send(message) {
        // MCP SDK stdio uses newline-delimited JSON (not Content-Length framing)
        const body = JSON.stringify(message) + '\n';
        this.process?.stdin?.write(body);
    }
    onData(chunk) {
        this.buffer += chunk.toString();
        this.processBuffer();
    }
    processBuffer() {
        // MCP SDK stdio uses newline-delimited JSON
        while (true) {
            const newlineIndex = this.buffer.indexOf('\n');
            if (newlineIndex === -1)
                return;
            const line = this.buffer.substring(0, newlineIndex).replace(/\r$/, '');
            this.buffer = this.buffer.substring(newlineIndex + 1);
            if (line.length === 0)
                continue;
            try {
                this.handleMessage(JSON.parse(line));
            }
            catch (e) {
                this.emit('error', e instanceof Error ? e : new Error(String(e)));
            }
        }
    }
    handleMessage(msg) {
        // Handle responses
        if (msg.id !== undefined && this.pending.has(msg.id)) {
            const handler = this.pending.get(msg.id);
            this.pending.delete(msg.id);
            if (msg.error) {
                handler.reject(new Error(msg.error.message));
            }
            else {
                handler.resolve(msg.result);
            }
            return;
        }
        // Handle notifications (logging messages from server)
        if (msg.method === 'notifications/message') {
            const params = msg.params;
            const data = params?.data;
            if (data?.event) {
                this.emit('notification', data);
            }
        }
    }
    async stop() {
        // Only try to unsubscribe if we successfully initialized
        if (this.initialized && this.isConnected()) {
            await this.unsubscribe();
        }
        // Reject any pending requests
        for (const [, handler] of this.pending) {
            handler.reject(new Error('Client stopped'));
        }
        this.pending.clear();
        this.process?.kill();
        this.process = null;
        this.initialized = false;
    }
    isConnected() {
        return this.process !== null && !this.process.killed && this.initialized;
    }
}
exports.McpClient = McpClient;
//# sourceMappingURL=client.js.map