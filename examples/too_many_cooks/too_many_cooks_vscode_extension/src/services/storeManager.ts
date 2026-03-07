// Store manager - HTTP client for the MCP server.
// Talks to the MCP server via:
// - /admin/* REST endpoints for VSIX operations
// - /admin/events Streamable HTTP for real-time push (no polling)
// - /mcp Streamable HTTP for MCP tool calls (tests)

import type { ChildProcess } from 'child_process';
import { spawn } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import { Store } from '../state/store';
import type { AgentIdentity, AgentPlan, AppState, FileLock, Message } from '../state/types';

// Server binary relative path (output of build_mcp.sh).
const SERVER_BINARY = 'build/bin/server_node.js';

const BASE_URL = 'http://localhost:4040';

const MCP_ACCEPT = 'application/json, text/event-stream';

type LogFn = (msg: string) => void;

export class StoreManager {
  private readonly store: Store;
  readonly workspaceFolder: string;
  private serverProcess: ChildProcess | null = null;
  private usingExternalServer = false;
  private connectPromise: Promise<void> | null = null;
  private mcpSessionId: string | null = null;
  private eventAbortController: AbortController | null = null;
  private readonly log: LogFn;

  constructor(workspaceFolder: string, log: LogFn = console.log) {
    this.workspaceFolder = workspaceFolder;
    this.store = new Store();
    this.log = log;
  }

  get state(): AppState {
    return this.store.getState();
  }

  subscribe(listener: () => void): () => void {
    return this.store.subscribe(listener);
  }

  get isConnected(): boolean {
    return this.serverProcess !== null || this.usingExternalServer;
  }

  get isConnecting(): boolean {
    return this.connectPromise !== null;
  }

  async connect(): Promise<void> {
    this.log('[StoreManager] connect() called');
    if (this.connectPromise) {
      this.log('[StoreManager] Already connecting...');
      return this.connectPromise;
    }

    if (this.serverProcess !== null) {
      this.log('[StoreManager] Already connected');
      return;
    }

    this.log('[StoreManager] Starting connection...');
    this.store.dispatch({ type: 'SetConnectionStatus', status: 'connecting' });

    this.connectPromise = this.doConnect();
    try {
      await this.connectPromise;
      this.log('[StoreManager] Connected');
    } finally {
      this.connectPromise = null;
    }
  }

  private async doConnect(): Promise<void> {
    this.log(`[StoreManager] workspace: ${this.workspaceFolder}`);

    // Check if external server is already running
    const externalRunning = await this.isServerAvailable();

    if (externalRunning) {
      this.log('[StoreManager] External server detected — resetting state');
      await this.resetServer();
      this.usingExternalServer = true;
    } else {
      this.log('[StoreManager] Spawning server...');
      const serverPath = this.findServerPath();
      this.log(`[StoreManager] server path: ${serverPath}`);

      const proc = spawn('node', [serverPath], {
        stdio: ['pipe', 'pipe', 'pipe'],
        env: { ...process.env, TMC_WORKSPACE: this.workspaceFolder },
      });

      this.serverProcess = proc;
      const capturedProcess = proc;

      proc.stderr.on('data', (data: Buffer) => {
        this.log(`[StoreManager] Server stderr: ${data}`);
      });

      proc.on('exit', (code: number | null) => {
        this.log(`[StoreManager] Server exited: ${code}`);
        if (this.serverProcess === capturedProcess) {
          this.serverProcess = null;
          this.store.dispatch({ type: 'SetConnectionStatus', status: 'disconnected' });
        }
      });

      proc.on('error', (err: Error) => {
        this.log(`[StoreManager] Server error: ${err}`);
      });

      this.usingExternalServer = false;
      await this.waitForServer();
    }

    // Get initial state via REST
    await this.refreshStatus();
    this.log('[StoreManager] refreshStatus completed');

    // Connect to Streamable HTTP event stream for real-time push
    this.connectEventStream();

    this.store.dispatch({ type: 'SetConnectionStatus', status: 'connected' });
  }

  // Connect to /admin/events via Streamable HTTP.
  // Initializes an MCP session then opens a GET stream
  // For server-pushed notifications. No polling.
  private connectEventStream(): void {
    this.eventAbortController?.abort();
    this.eventAbortController = new AbortController();

    this.log('[StoreManager] Connecting to admin event stream...');

    this.initAdminSession()
      .then(sessionId => {
        this.log(`[StoreManager] Admin session: ${sessionId}`);
        this.listenAdminEvents(sessionId);
      })
      .catch(err => {
        this.log(`[StoreManager] Admin session error: ${err}`);
      });
  }

  // Initialize an admin MCP session at /admin/events.
  private async initAdminSession(): Promise<string> {
    const body = JSON.stringify({
      jsonrpc: '2.0',
      id: 1,
      method: 'initialize',
      params: {
        protocolVersion: '2025-03-26',
        capabilities: {},
        clientInfo: { name: 'too-many-cooks-vsix-admin', version: '1.0.0' },
      },
    });

    const response = await this.streamableHttpFetch(`${BASE_URL}/admin/events`, body);
    const sessionId = response.headers.get('mcp-session-id');
    if (!sessionId) {
      throw new Error('No admin session ID in response');
    }

    // Send initialized notification
    const notifyBody = JSON.stringify({
      jsonrpc: '2.0',
      method: 'notifications/initialized',
      params: {},
    });
    await this.streamableHttpFetch(`${BASE_URL}/admin/events`, notifyBody, sessionId);

    return sessionId;
  }

  // Listen for admin push events via GET /admin/events.
  private listenAdminEvents(sessionId: string): void {
    const signal = this.eventAbortController?.signal;

    fetch(`${BASE_URL}/admin/events`, {
      method: 'GET',
      headers: {
        'Accept': MCP_ACCEPT,
        'mcp-session-id': sessionId,
      },
      signal,
    }).then(async response => {
      if (!response.ok || !response.body) {
        this.log(`[StoreManager] Admin GET failed: ${response.status}`);
        return;
      }

      this.log('[StoreManager] Admin event stream connected');
      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) { break; }

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() ?? '';

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.substring(6).trim();
            if (data) {
              this.handleAdminEvent(data);
            }
          }
        }
      }

      this.log('[StoreManager] Admin event stream ended');
    }).catch(err => {
      if (signal && !signal.aborted) {
        this.log(`[StoreManager] Admin stream error: ${err}`);
      }
    });
  }

  // Handle an admin push event by refreshing status.
  private handleAdminEvent(data: string): void {
    this.log('[StoreManager] Admin event received');
    this.refreshStatus().catch(() => {});
  }

  // POST to a Streamable HTTP endpoint.
  private async streamableHttpFetch(
    url: string,
    body: string,
    sessionId?: string,
  ): Promise<Response> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': MCP_ACCEPT,
    };
    if (sessionId) {
      headers['mcp-session-id'] = sessionId;
    }
    return fetch(url, { method: 'POST', headers, body });
  }

  private async isServerAvailable(): Promise<boolean> {
    try {
      const response = await fetch(`${BASE_URL}/admin/status`);
      return response.ok;
    } catch {
      return false;
    }
  }

  private async resetServer(): Promise<void> {
    this.log('[StoreManager] POST /admin/reset');
    try {
      await fetch(`${BASE_URL}/admin/reset`, { method: 'POST' });
    } catch (e) {
      this.log(`[StoreManager] Reset failed: ${e}`);
    }
  }

  private async waitForServer(): Promise<void> {
    this.log('[StoreManager] Waiting for server...');
    for (let i = 0; i < 30; i++) {
      try {
        const response = await fetch(`${BASE_URL}/admin/status`);
        if (response.ok) {
          this.log('[StoreManager] Server is ready');
          return;
        }
        this.log(`[StoreManager] Poll ${i}: not ok`);
      } catch (e) {
        if (i === 0 || i % 5 === 0) {
          this.log(`[StoreManager] Poll ${i}: ${e}`);
        }
      }
      await new Promise(resolve => {return setTimeout(resolve, 200)});
    }
    throw new Error('Server failed to start');
  }

  private findServerPath(): string {
    const candidates = [
      path.join(this.workspaceFolder, SERVER_BINARY),
      path.join(this.workspaceFolder, `../too_many_cooks/${SERVER_BINARY}`),
    ];

    for (const candidate of candidates) {
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }

    throw new Error(
      'MCP server binary not found. Run scripts/mcp.sh build first.'
    );
  }

  async disconnect(): Promise<void> {
    this.log('[StoreManager] disconnect() called');
    this.connectPromise = null;
    this.mcpSessionId = null;

    // Abort the event stream
    this.eventAbortController?.abort();
    this.eventAbortController = null;

    const proc = this.serverProcess;
    this.serverProcess = null;
    this.usingExternalServer = false;
    if (proc) {
      proc.kill();
    }

    this.store.dispatch({ type: 'ResetState' });
    this.store.dispatch({ type: 'SetConnectionStatus', status: 'disconnected' });
  }

  async refreshStatus(): Promise<void> {
    if (!this.isConnected) {
      throw new Error('Not connected');
    }

    const response = await fetch(`${BASE_URL}/admin/status`);
    if (!response.ok) { return; }
    const json = await response.json() as Record<string, unknown>;
    this.parseAndDispatchStatus(json);
  }

  private parseAndDispatchStatus(json: Record<string, unknown>): void {
    if (Array.isArray(json.agents)) {
      const agents: AgentIdentity[] = json.agents.map((a: Record<string, unknown>) => {return {
        agentName: (a.agent_name as string) ?? '',
        registeredAt: (a.registered_at as number) ?? 0,
        lastActive: (a.last_active as number) ?? 0,
      }});
      this.store.dispatch({ type: 'SetAgents', agents });
    }

    if (Array.isArray(json.locks)) {
      const locks: FileLock[] = json.locks.map((l: Record<string, unknown>) => {return {
        filePath: (l.file_path as string) ?? '',
        agentName: (l.agent_name as string) ?? '',
        acquiredAt: (l.acquired_at as number) ?? 0,
        expiresAt: (l.expires_at as number) ?? 0,
        reason: (l.reason as string) ?? null,
        version: (l.version as number) ?? 0,
      }});
      this.store.dispatch({ type: 'SetLocks', locks });
    }

    if (Array.isArray(json.plans)) {
      const plans: AgentPlan[] = json.plans.map((p: Record<string, unknown>) => {return {
        agentName: (p.agent_name as string) ?? '',
        goal: (p.goal as string) ?? '',
        currentTask: (p.current_task as string) ?? '',
        updatedAt: (p.updated_at as number) ?? 0,
      }});
      this.store.dispatch({ type: 'SetPlans', plans });
    }

    if (Array.isArray(json.messages)) {
      const messages: Message[] = json.messages.map((m: Record<string, unknown>) => {return {
        id: (m.id as string) ?? '',
        fromAgent: (m.from_agent as string) ?? '',
        toAgent: (m.to_agent as string) ?? '',
        content: (m.content as string) ?? '',
        createdAt: (m.created_at as number) ?? 0,
        readAt: (m.read_at as number) ?? null,
      }});
      this.store.dispatch({ type: 'SetMessages', messages });
    }
  }

  async forceReleaseLock(filePath: string): Promise<void> {
    await this.postJson(`${BASE_URL}/admin/delete-lock`, { filePath });
    this.log(`[StoreManager] Lock released: ${filePath}`);
    await this.refreshStatus();
  }

  async deleteAgent(agentName: string): Promise<void> {
    await this.postJson(`${BASE_URL}/admin/delete-agent`, { agentName });
    this.log(`[StoreManager] Agent deleted: ${agentName}`);
    await this.refreshStatus();
  }

  async sendMessage(fromAgent: string, toAgent: string, content: string): Promise<void> {
    await this.postJson(`${BASE_URL}/admin/send-message`, { fromAgent, toAgent, content });
    this.log('[StoreManager] Message sent');
    await this.refreshStatus();
  }

  // Call an MCP tool via Streamable HTTP at /mcp.
  async callTool(name: string, args: Record<string, unknown>): Promise<string> {
    if (!this.isConnected) {
      return '{"error":"Not connected"}';
    }

    try {
      if (!this.mcpSessionId) {
        this.mcpSessionId = await this.initMcpSession();
      }

      const result = await this.mcpRequest('tools/call', { name, arguments: args });
      const content = (result.content as Array<Record<string, unknown>>)[0];
      const text = (content?.text as string) ?? '{"error":"No text content"}';

      // Refresh state immediately so tree views update without waiting for event stream
      await this.refreshStatus();

      return text;
    } catch (e) {
      this.mcpSessionId = null;
      return `{"error":"${e}"}`;
    }
  }

  // Initialize an MCP session via Streamable HTTP POST /mcp.
  private async initMcpSession(): Promise<string> {
    const body = JSON.stringify({
      jsonrpc: '2.0',
      id: 1,
      method: 'initialize',
      params: {
        protocolVersion: '2025-03-26',
        capabilities: {},
        clientInfo: { name: 'too-many-cooks-vsix', version: '1.0.0' },
      },
    });

    const response = await this.mcpFetch(body);
    const sessionId = response.headers.get('mcp-session-id');
    if (!sessionId) {
      throw new Error('No session ID in response');
    }

    // Send initialized notification
    const notifyBody = JSON.stringify({
      jsonrpc: '2.0',
      method: 'notifications/initialized',
      params: {},
    });
    await this.mcpFetch(notifyBody, sessionId);

    return sessionId;
  }

  // Make an MCP JSON-RPC request via Streamable HTTP POST /mcp.
  private async mcpRequest(
    method: string,
    params: Record<string, unknown>,
  ): Promise<Record<string, unknown>> {
    const body = JSON.stringify({
      jsonrpc: '2.0',
      id: Date.now(),
      method,
      params,
    });

    const response = await this.mcpFetch(body, this.mcpSessionId ?? undefined);
    const text = await response.text();

    if (!text) {
      throw new Error('Empty response');
    }

    const json = this.parseStreamableHttpResponse(text);

    if (json.error) {
      const error = json.error as Record<string, unknown>;
      throw new Error((error.message as string) ?? 'Error');
    }

    return (json.result as Record<string, unknown>) ?? {};
  }

  // POST to /mcp with Streamable HTTP headers.
  private async mcpFetch(body: string, sessionId?: string): Promise<Response> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': MCP_ACCEPT,
    };
    if (sessionId) {
      headers['mcp-session-id'] = sessionId;
    }

    return fetch(`${BASE_URL}/mcp`, { method: 'POST', headers, body });
  }

  // Parse Streamable HTTP response (may be JSON or event-stream with data lines).
  private parseStreamableHttpResponse(text: string): Record<string, unknown> {
    // Try direct JSON first
    if (text.trimStart().startsWith('{')) {
      return JSON.parse(text);
    }

    // Parse event-stream: extract data from "data: {...}" lines
    for (const line of text.split('\n')) {
      if (line.startsWith('data: ')) {
        const data = line.substring(6);
        try {
          return JSON.parse(data);
        } catch {
          continue;
        }
      }
    }

    throw new Error('Could not parse Streamable HTTP response');
  }

  // POST JSON to a URL.
  private async postJson(url: string, body: Record<string, unknown>): Promise<string> {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    return response.text();
  }
}
