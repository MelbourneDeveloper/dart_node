// Store manager - orchestrates MCP server connection and state.
// The extension NEVER spawns or bundles a server binary.
// It connects to an already-running external server only.

import { checkServerAvailable, isRecord, postJsonRequest } from 'services/httpClient';
import { extractToolResultText, initMcpSession, mcpJsonRpcRequest } from 'services/mcpProtocol';
import type { AppState } from 'state/types';
import { Store } from 'state/store';
import { parseStatusResponse } from 'services/statusParser';
import { startAdminEventStream } from 'services/adminEventStream';

const BASE_URL: string = 'http://localhost:4040';
const SERVER_NOT_RUNNING_MSG: string =
  'MCP server is not running. Start it externally before connecting.';

type LogFn = (msg: string) => void;

export class StoreManager {
  private readonly store: Store;
  public readonly workspaceFolder: string;
  private connected: boolean = false;
  private connectPromise: Promise<void> | null = null;
  private mcpSessionId: string | null = null;
  private eventAbortController: AbortController | null = null;
  private readonly log: LogFn;

  public constructor(workspaceFolder: string, log: LogFn) {
    this.workspaceFolder = workspaceFolder;
    this.store = new Store();
    this.log = log;
  }

  public get state(): AppState {
    return this.store.getState();
  }

  public subscribe(listener: () => void): () => void {
    return this.store.subscribe(listener);
  }

  public get isConnected(): boolean {
    return this.connected;
  }

  public get isConnecting(): boolean {
    return this.connectPromise !== null;
  }

  public async connect(): Promise<void> {
    this.log('[StoreManager] connect() called');
    if (this.connectPromise !== null) {
      await this.connectPromise;
      return;
    }
    if (this.connected) { return; }
    this.store.dispatch({ status: 'connecting', type: 'SetConnectionStatus' });
    this.connectPromise = this.doConnect();
    try {
      await this.connectPromise;
    } catch (err: unknown) {
      this.store.dispatch({ status: 'disconnected', type: 'SetConnectionStatus' });
      throw err;
    } finally {
      this.connectPromise = null;
    }
  }

  private async doConnect(): Promise<void> {
    const externalRunning: boolean = await checkServerAvailable(BASE_URL);
    if (!externalRunning) {
      throw new Error(SERVER_NOT_RUNNING_MSG);
    }
    this.connected = true;
    await this.refreshStatus();
    this.connectEventStream();
    this.store.dispatch({ status: 'connected', type: 'SetConnectionStatus' });
  }

  private connectEventStream(): void {
    this.eventAbortController?.abort();
    this.eventAbortController = new AbortController();
    startAdminEventStream(this.eventAbortController, {
      baseUrl: BASE_URL,
      log: this.log,
      onEvent: (): void => { this.handleAdminEvent(); },
    });
  }

  private handleAdminEvent(): void {
    this.refreshStatus().catch((err: unknown): void => {
      this.log(`[StoreManager] Refresh failed: ${String(err)}`);
    });
  }

  public disconnect(): void {
    this.connectPromise = null;
    this.mcpSessionId = null;
    this.eventAbortController?.abort();
    this.eventAbortController = null;
    this.connected = false;
    this.store.dispatch({ type: 'ResetState' });
    this.store.dispatch({ status: 'disconnected', type: 'SetConnectionStatus' });
  }

  public async refreshStatus(): Promise<void> {
    if (!this.isConnected) { throw new Error('Not connected'); }
    const response: Response = await fetch(`${BASE_URL}/admin/status`);
    if (!response.ok) { return; }
    const json: unknown = await response.json();
    if (!isRecord(json)) { return; }
    const statusData: ReturnType<typeof parseStatusResponse> = parseStatusResponse(json);
    this.store.dispatch({ agents: statusData.agents, type: 'SetAgents' });
    this.store.dispatch({ locks: statusData.locks, type: 'SetLocks' });
    this.store.dispatch({ messages: statusData.messages, type: 'SetMessages' });
    this.store.dispatch({ plans: statusData.plans, type: 'SetPlans' });
  }

  public async forceReleaseLock(filePath: string): Promise<void> {
    await postJsonRequest(`${BASE_URL}/admin/delete-lock`, { filePath });
    await this.refreshStatus();
  }

  public async deleteAgent(agentName: string): Promise<void> {
    await postJsonRequest(`${BASE_URL}/admin/delete-agent`, { agentName });
    await this.refreshStatus();
  }

  public async sendMessage(fromAgent: string, toAgent: string, content: string): Promise<void> {
    await postJsonRequest(`${BASE_URL}/admin/send-message`, { content, fromAgent, toAgent });
    await this.refreshStatus();
  }

  public async callTool(name: string, args: Readonly<Record<string, unknown>>): Promise<string> {
    if (!this.isConnected) { return '{"error":"Not connected"}'; }
    try {
      if (this.mcpSessionId === null) {
        this.mcpSessionId = await initMcpSession(BASE_URL, '/mcp', 'too-many-cooks-vsix');
      }
      const result: Record<string, unknown> = await mcpJsonRpcRequest({
        baseUrl: BASE_URL,
        method: 'tools/call',
        params: { arguments: args, name },
        sessionId: this.mcpSessionId,
      });
      const text: string = extractToolResultText(result);
      await this.refreshStatus();
      return text;
    } catch (err: unknown) {
      this.mcpSessionId = null;
      return `{"error":"${String(err)}"}`;
    }
  }
}
