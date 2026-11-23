/**
 * MCP Client - communicates with Too Many Cooks server via stdio JSON-RPC.
 */

import { spawn, ChildProcess } from 'child_process';
import { EventEmitter } from 'events';
import type { JsonRpcMessage, NotificationEvent, ToolCallResult } from './types';

export interface McpClientEvents {
  notification: (event: NotificationEvent) => void;
  log: (message: string) => void;
  error: (error: Error) => void;
  close: () => void;
}

export class McpClient extends EventEmitter {
  private process: ChildProcess | null = null;
  private buffer = '';
  private pending = new Map<
    number,
    { resolve: (value: unknown) => void; reject: (error: Error) => void }
  >();
  private nextId = 1;
  private serverPath: string | undefined;
  private initialized = false;

  /**
   * @param serverPath Optional path to server JS file. If not provided, uses 'npx too-many-cooks'.
   *                   Pass a path for testing with local builds.
   */
  constructor(serverPath?: string) {
    super();
    this.serverPath = serverPath;
  }

  override on<K extends keyof McpClientEvents>(
    event: K,
    listener: McpClientEvents[K]
  ): this {
    return super.on(event, listener);
  }

  override emit<K extends keyof McpClientEvents>(
    event: K,
    ...args: Parameters<McpClientEvents[K]>
  ): boolean {
    return super.emit(event, ...args);
  }

  async start(): Promise<void> {
    // If serverPath is provided (testing), use node with that path
    // Otherwise use npx to run the globally installed too-many-cooks package
    // This ensures VSCode extension uses the SAME server as Claude Code
    const [cmd, args] = this.serverPath
      ? ['node', [this.serverPath]]
      : ['npx', ['too-many-cooks']];

    this.process = spawn(cmd, args, {
      stdio: ['pipe', 'pipe', 'pipe'],
      shell: !this.serverPath, // Only use shell for npx
    });

    this.process.stdout?.on('data', (chunk: Buffer) => this.onData(chunk));
    this.process.stderr?.on('data', (chunk: Buffer) => {
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
      clientInfo: { name: 'too-many-cooks-vscode', version: '0.3.0' },
    });

    // Send initialized notification
    this.notify('notifications/initialized', {});
    this.initialized = true;
  }

  async callTool(
    name: string,
    args: Record<string, unknown>
  ): Promise<string> {
    const result = (await this.request('tools/call', {
      name,
      arguments: args,
    })) as ToolCallResult;

    const content = result.content[0];
    if (result.isError) {
      throw new Error(content?.text ?? 'Unknown error');
    }
    return content?.text ?? '{}';
  }

  async subscribe(events: string[] = ['*']): Promise<void> {
    await this.callTool('subscribe', {
      action: 'subscribe',
      subscriber_id: 'vscode-extension',
      events,
    });
  }

  async unsubscribe(): Promise<void> {
    try {
      await this.callTool('subscribe', {
        action: 'unsubscribe',
        subscriber_id: 'vscode-extension',
      });
    } catch {
      // Ignore errors during unsubscribe
    }
  }

  private request(
    method: string,
    params: Record<string, unknown>
  ): Promise<unknown> {
    return new Promise((resolve, reject) => {
      const id = this.nextId++;
      this.pending.set(id, { resolve, reject });
      this.send({ jsonrpc: '2.0', id, method, params });
    });
  }

  private notify(method: string, params: Record<string, unknown>): void {
    this.send({ jsonrpc: '2.0', method, params });
  }

  private send(message: JsonRpcMessage): void {
    // MCP SDK stdio uses newline-delimited JSON (not Content-Length framing)
    const body = JSON.stringify(message) + '\n';
    this.process?.stdin?.write(body);
  }

  private onData(chunk: Buffer): void {
    this.buffer += chunk.toString();
    this.processBuffer();
  }

  private processBuffer(): void {
    // MCP SDK stdio uses newline-delimited JSON
    let newlineIndex = this.buffer.indexOf('\n');
    while (newlineIndex !== -1) {

      const line = this.buffer.substring(0, newlineIndex).replace(/\r$/, '');
      this.buffer = this.buffer.substring(newlineIndex + 1);

      if (line.length === 0) continue;

      try {
        this.handleMessage(JSON.parse(line) as JsonRpcMessage);
      } catch (e) {
        this.emit('error', e instanceof Error ? e : new Error(String(e)));
      }
      newlineIndex = this.buffer.indexOf('\n');
    }
  }

  private handleMessage(msg: JsonRpcMessage): void {
    // Handle responses
    if (msg.id !== undefined && this.pending.has(msg.id)) {
      const handler = this.pending.get(msg.id)!;
      this.pending.delete(msg.id);
      if (msg.error) {
        handler.reject(new Error(msg.error.message));
      } else {
        handler.resolve(msg.result);
      }
      return;
    }

    // Handle notifications (logging messages from server)
    if (msg.method === 'notifications/message') {
      const params = msg.params as { level?: string; data?: unknown } | undefined;
      const data = params?.data as NotificationEvent | undefined;
      if (data?.event) {
        this.emit('notification', data);
      }
    }
  }

  async stop(): Promise<void> {
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

  isConnected(): boolean {
    return this.process !== null && !this.process.killed && this.initialized;
  }
}
