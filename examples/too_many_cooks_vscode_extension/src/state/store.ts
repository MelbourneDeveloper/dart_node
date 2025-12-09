/**
 * State store - manages MCP client and syncs with signals.
 */

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

export class Store {
  private client: McpClient | null = null;
  private serverPath: string;

  constructor(serverPath: string) {
    this.serverPath = serverPath;
  }

  setServerPath(path: string): void {
    this.serverPath = path;
  }

  async connect(): Promise<void> {
    if (this.client?.isConnected()) {
      return;
    }

    connectionStatus.value = 'connecting';

    try {
      this.client = new McpClient(this.serverPath);

      // Handle notifications
      this.client.on('notification', (event: NotificationEvent) => {
        this.handleNotification(event);
      });

      this.client.on('close', () => {
        connectionStatus.value = 'disconnected';
      });

      this.client.on('error', (err) => {
        console.error('MCP client error:', err);
      });

      await this.client.start();
      await this.client.subscribe(['*']);
      await this.refreshStatus();

      connectionStatus.value = 'connected';
    } catch (err) {
      connectionStatus.value = 'disconnected';
      throw err;
    }
  }

  async disconnect(): Promise<void> {
    if (this.client) {
      await this.client.stop();
      this.client = null;
    }
    resetState();
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
        agentName: a.name,
        registeredAt: 0,
        lastActive: a.last_active,
      })
    );

    // Update locks
    locks.value = status.locks.map(
      (l): FileLock => ({
        filePath: l.file_path,
        agentName: l.agent_name,
        acquiredAt: 0,
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
}
