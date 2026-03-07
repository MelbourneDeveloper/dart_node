// Parse server status JSON into typed state objects.

import type { AgentIdentity, AgentPlan, FileLock, Message } from 'state/types';

// Parsed status response from the server.
export interface StatusData {
  readonly agents: readonly AgentIdentity[];
  readonly locks: readonly FileLock[];
  readonly messages: readonly Message[];
  readonly plans: readonly AgentPlan[];
}

function stringField(record: Readonly<Record<string, unknown>>, key: string): string {
  const value: unknown = record[key];
  if (typeof value === 'string') {
    return value;
  }
  return '';
}

function numberField(record: Readonly<Record<string, unknown>>, key: string): number {
  const value: unknown = record[key];
  if (typeof value === 'number') {
    return value;
  }
  return 0;
}

function nullableStringField(record: Readonly<Record<string, unknown>>, key: string): string | null {
  const value: unknown = record[key];
  if (typeof value === 'string') {
    return value;
  }
  return null;
}

function nullableNumberField(record: Readonly<Record<string, unknown>>, key: string): number | null {
  const value: unknown = record[key];
  if (typeof value === 'number') {
    return value;
  }
  return null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function parseAgent(raw: Readonly<Record<string, unknown>>): AgentIdentity {
  return {
    agentName: stringField(raw, 'agent_name'),
    lastActive: numberField(raw, 'last_active'),
    registeredAt: numberField(raw, 'registered_at'),
  };
}

function parseLock(raw: Readonly<Record<string, unknown>>): FileLock {
  return {
    acquiredAt: numberField(raw, 'acquired_at'),
    agentName: stringField(raw, 'agent_name'),
    expiresAt: numberField(raw, 'expires_at'),
    filePath: stringField(raw, 'file_path'),
    reason: nullableStringField(raw, 'reason'),
    version: numberField(raw, 'version'),
  };
}

function parsePlan(raw: Readonly<Record<string, unknown>>): AgentPlan {
  return {
    agentName: stringField(raw, 'agent_name'),
    currentTask: stringField(raw, 'current_task'),
    goal: stringField(raw, 'goal'),
    updatedAt: numberField(raw, 'updated_at'),
  };
}

function parseMessage(raw: Readonly<Record<string, unknown>>): Message {
  return {
    content: stringField(raw, 'content'),
    createdAt: numberField(raw, 'created_at'),
    fromAgent: stringField(raw, 'from_agent'),
    id: stringField(raw, 'id'),
    readAt: nullableNumberField(raw, 'read_at'),
    toAgent: stringField(raw, 'to_agent'),
  };
}

function parseArray<T>(data: unknown, mapper: (raw: Readonly<Record<string, unknown>>) => T): T[] {
  if (!Array.isArray(data)) {
    return [];
  }
  return data
    .filter((item: unknown): item is Record<string, unknown> => {
      return isRecord(item);
    })
    .map(mapper);
}

export function parseStatusResponse(json: Readonly<Record<string, unknown>>): StatusData {
  return {
    agents: parseArray(json.agents, parseAgent),
    locks: parseArray(json.locks, parseLock),
    messages: parseArray(json.messages, parseMessage),
    plans: parseArray(json.plans, parsePlan),
  };
}
