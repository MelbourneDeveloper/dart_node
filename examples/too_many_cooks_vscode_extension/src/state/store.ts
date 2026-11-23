/**
 * State store - manages MCP client and syncs with signals.
 */

import * as vscode from 'vscode';
import { McpClient } from '../mcp/client';
import type {
  NotificationEvent,
  StatusResponse,
  AgentIdentity,
  FileLock,
  Message,
  AgentPlan,
} from '../mcp/types';
import {
  agents,
  locks,
  messages,
  plans,
  connectionStatus,
  resetState,
} from './signals';

function getOutputChannel(): vscode.OutputChannel | undefined {
  // Get the output channel created by extension.ts
  return (globalThis as Record<string, unknown>)._tooManyCooksOutput as vscode.OutputChannel | undefined;
}

function log(message: string): void {
  const timestamp = new Date().toISOString();
  const output = getOutputChannel();
  if (output) {
    output.appendLine(`[${timestamp}] [Store] ${message}`);
  }
}

export class Store {
  private client: McpClient | null = null;
  private pollInterval: ReturnType<typeof setInterval> | null = null;
  private serverPath: string | undefined;
  private connectPromise: Promise<void> | null = null;

  /**
   * @param serverPath Optional path to server JS file for testing.
   *                   If not provided, uses 'npx too-many-cooks'.
   */
  constructor(serverPath?: string) {
    this.serverPath = serverPath;
    log(serverPath
      ? `Store created with serverPath: ${serverPath}`
      : 'Store created (will use npx too-many-cooks)');
  }

  async connect(): Promise<void> {
    log('connect() called');

    // If already connecting, wait for that to complete
    if (this.connectPromise) {
      log('Connect already in progress, waiting...');
      return this.connectPromise;
    }

    if (this.client?.isConnected()) {
      log('Already connected, returning');
      return;
    }

    connectionStatus.value = 'connecting';
    log('Connection status: connecting');

    this.connectPromise = this.doConnect();
    try {
      await this.connectPromise;
    } finally {
      this.connectPromise = null;
    }
  }

  private async doConnect(): Promise<void> {
    try {
      log(this.serverPath
        ? `Creating McpClient with path: ${this.serverPath}`
        : 'Creating McpClient (using npx too-many-cooks)...');
      this.client = new McpClient(this.serverPath);

      // Handle notifications
      this.client.on('notification', (event: NotificationEvent) => {
        log(`Notification received: ${event.event}`);
        this.handleNotification(event);
      });

      this.client.on('close', () => {
        log('Client closed');
        connectionStatus.value = 'disconnected';
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

      connectionStatus.value = 'connected';
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
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      log(`Connection failed: ${msg}`);
      connectionStatus.value = 'disconnected';
      throw err;
    }
  }

  async disconnect(): Promise<void> {
    log('disconnect() called');

    // Clear the connect promise - we're aborting any in-progress connection
    this.connectPromise = null;

    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
      log('Polling stopped');
    }
    if (this.client) {
      await this.client.stop();
      this.client = null;
      log('Client stopped');
    }
    resetState();
    connectionStatus.value = 'disconnected';
    log('State reset, disconnected');
  }

  async refreshStatus(): Promise<void> {
    if (!this.client?.isConnected()) {
      throw new Error('Not connected');
    }

    const statusJson = await this.client.callTool('status', {});
    const status: StatusResponse = JSON.parse(statusJson);

    // Update agents
    agents.value = status.agents.map(
      (a): AgentIdentity => ({
        agentName: a.agent_name,
        registeredAt: a.registered_at,
        lastActive: a.last_active,
      })
    );

    // Update locks
    locks.value = status.locks.map(
      (l): FileLock => ({
        filePath: l.file_path,
        agentName: l.agent_name,
        acquiredAt: l.acquired_at,
        expiresAt: l.expires_at,
        reason: l.reason,
        version: 1,
      })
    );

    // Update plans
    plans.value = status.plans.map(
      (p): AgentPlan => ({
        agentName: p.agent_name,
        goal: p.goal,
        currentTask: p.current_task,
        updatedAt: p.updated_at,
      })
    );

    // Update messages
    messages.value = status.messages.map(
      (m): Message => ({
        id: m.id,
        fromAgent: m.from_agent,
        toAgent: m.to_agent,
        content: m.content,
        createdAt: m.created_at,
        readAt: m.read_at,
      })
    );
  }

  private handleNotification(event: NotificationEvent): void {
    const payload = event.payload;

    switch (event.event) {
      case 'agent_registered': {
        const newAgent: AgentIdentity = {
          agentName: payload.agent_name as string,
          registeredAt: payload.registered_at as number,
          lastActive: event.timestamp,
        };
        agents.value = [...agents.value, newAgent];
        break;
      }

      case 'lock_acquired': {
        const newLock: FileLock = {
          filePath: payload.file_path as string,
          agentName: payload.agent_name as string,
          acquiredAt: event.timestamp,
          expiresAt: payload.expires_at as number,
          reason: payload.reason as string | undefined,
          version: 1,
        };
        // Remove any existing lock on this file, then add new one
        locks.value = [
          ...locks.value.filter((l) => l.filePath !== newLock.filePath),
          newLock,
        ];
        break;
      }

      case 'lock_released': {
        const filePath = payload.file_path as string;
        locks.value = locks.value.filter((l) => l.filePath !== filePath);
        break;
      }

      case 'lock_renewed': {
        const filePath = payload.file_path as string;
        const expiresAt = payload.expires_at as number;
        locks.value = locks.value.map((l) =>
          l.filePath === filePath ? { ...l, expiresAt } : l
        );
        break;
      }

      case 'message_sent': {
        const newMessage: Message = {
          id: payload.message_id as string,
          fromAgent: payload.from_agent as string,
          toAgent: payload.to_agent as string,
          content: payload.content as string,
          createdAt: event.timestamp,
          readAt: undefined,
        };
        messages.value = [...messages.value, newMessage];
        break;
      }

      case 'plan_updated': {
        const agentName = payload.agent_name as string;
        const newPlan: AgentPlan = {
          agentName,
          goal: payload.goal as string,
          currentTask: payload.current_task as string,
          updatedAt: event.timestamp,
        };
        const existingIdx = plans.value.findIndex(
          (p) => p.agentName === agentName
        );
        if (existingIdx >= 0) {
          plans.value = [
            ...plans.value.slice(0, existingIdx),
            newPlan,
            ...plans.value.slice(existingIdx + 1),
          ];
        } else {
          plans.value = [...plans.value, newPlan];
        }
        break;
      }
    }
  }

  isConnected(): boolean {
    return this.client?.isConnected() ?? false;
  }

  async callTool(name: string, args: Record<string, unknown>): Promise<string> {
    if (!this.client?.isConnected()) {
      throw new Error('Not connected');
    }
    return this.client.callTool(name, args);
  }

  /**
   * Force release a lock (admin operation).
   * Uses admin tool which can delete any lock regardless of expiry.
   */
  async forceReleaseLock(filePath: string): Promise<void> {
    const result = await this.callTool('admin', {
      action: 'delete_lock',
      file_path: filePath,
    });
    const parsed = JSON.parse(result);
    if (parsed.error) {
      throw new Error(parsed.error);
    }
    // Remove from local state
    locks.value = locks.value.filter((l) => l.filePath !== filePath);
    log(`Force released lock: ${filePath}`);
  }

  /**
   * Delete an agent (admin operation).
   * Requires admin_delete_agent tool on the MCP server.
   */
  async deleteAgent(agentName: string): Promise<void> {
    const result = await this.callTool('admin', {
      action: 'delete_agent',
      agent_name: agentName,
    });
    const parsed = JSON.parse(result);
    if (parsed.error) {
      throw new Error(parsed.error);
    }
    // Remove from local state
    agents.value = agents.value.filter((a) => a.agentName !== agentName);
    plans.value = plans.value.filter((p) => p.agentName !== agentName);
    locks.value = locks.value.filter((l) => l.agentName !== agentName);
    log(`Deleted agent: ${agentName}`);
  }

  /**
   * Send a message from VSCode user to an agent.
   * Registers the sender if needed, then sends the message.
   */
  async sendMessage(
    fromAgent: string,
    toAgent: string,
    content: string
  ): Promise<void> {
    // Register sender and get key
    const registerResult = await this.callTool('register', { name: fromAgent });
    const registerParsed = JSON.parse(registerResult);
    if (registerParsed.error) {
      throw new Error(registerParsed.error);
    }
    const agentKey = registerParsed.agent_key;

    // Send the message
    const sendResult = await this.callTool('message', {
      action: 'send',
      agent_name: fromAgent,
      agent_key: agentKey,
      to_agent: toAgent,
      content: content,
    });
    const sendParsed = JSON.parse(sendResult);
    if (sendParsed.error) {
      throw new Error(sendParsed.error);
    }
    log(`Message sent from ${fromAgent} to ${toAgent}`);
  }
}
