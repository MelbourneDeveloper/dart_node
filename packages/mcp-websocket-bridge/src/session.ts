import type WebSocket from 'ws';
import type { HttpClient, PendingRequest } from './types.js';

export type Session = {
  id: string;
  ws: WebSocket | null;
  http: HttpClient | null;
  pendingRequests: Map<string, PendingRequest>;
  sseWriters: Set<(data: string) => void>;
  createdAt: number;
};

export type SessionStore = {
  sessions: Map<string, Session>;
};

export const createSessionStore = (): SessionStore => ({
  sessions: new Map(),
});

export const createSession = (store: SessionStore, id: string): Session => {
  const session: Session = {
    id,
    ws: null,
    http: null,
    pendingRequests: new Map(),
    sseWriters: new Set(),
    createdAt: Date.now(),
  };
  store.sessions.set(id, session);
  return session;
};

export const getSession = (store: SessionStore, id: string): Session | undefined =>
  store.sessions.get(id);

export const getOrCreateSession = (store: SessionStore, id: string): Session =>
  store.sessions.get(id) ?? createSession(store, id);

export const deleteSession = (store: SessionStore, id: string): boolean => {
  const session = store.sessions.get(id);
  if (session) {
    session.ws?.close();
    session.sseWriters.clear();
    session.pendingRequests.clear();
  }
  return store.sessions.delete(id);
};

export const setSessionWebSocket = (session: Session, ws: WebSocket): void => {
  session.ws = ws;
};

export const setSessionHttpClient = (session: Session, http: HttpClient): void => {
  session.http = http;
};

export const addSseWriter = (session: Session, writer: (data: string) => void): void => {
  session.sseWriters.add(writer);
};

export const removeSseWriter = (session: Session, writer: (data: string) => void): void => {
  session.sseWriters.delete(writer);
};

export const notifySession = (session: Session, payload: unknown): void => {
  const data = JSON.stringify(payload);
  session.sseWriters.forEach(writer => writer(`data: ${data}\n\n`));
};

export const getAllSessions = (store: SessionStore): Session[] =>
  Array.from(store.sessions.values());

export const getSessionCount = (store: SessionStore): number =>
  store.sessions.size;
