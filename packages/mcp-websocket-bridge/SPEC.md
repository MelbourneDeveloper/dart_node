# MCP-WebSocket Bridge Specification

## Overview

This library **IS** an MCP server that translates between MCP protocol and existing WebSocket/HTTP services.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              MCP SERVER                                 │
│                        (this library)                                   │
│                                                                         │
│  ┌─────────────────┐         ┌─────────────────┐                       │
│  │   Transport     │         │   Service       │                       │
│  │   (data in/out) │         │   Connection    │                       │
│  │                 │         │                 │                       │
│  │  ┌───────────┐  │         │  ┌───────────┐  │                       │
│  │  │  stdio    │  │         │  │ WebSocket │  │                       │
│  │  └───────────┘  │         │  └───────────┘  │                       │
│  │       OR        │         │      AND/OR     │                       │
│  │  ┌───────────┐  │         │  ┌───────────┐  │                       │
│  │  │  HTTP     │  │         │  │   HTTP    │  │                       │
│  │  └───────────┘  │         │  └───────────┘  │                       │
│  └────────┬────────┘         └────────┬────────┘                       │
│           │                           │                                 │
│           ▼                           ▼                                 │
│  ┌─────────────────────────────────────────────────────────────┐       │
│  │                     BRIDGE CORE                              │       │
│  │                                                              │       │
│  │  • Parses MCP JSON-RPC messages                             │       │
│  │  • Routes tool calls to handlers                            │       │
│  │  • Forwards service messages to agent                       │       │
│  │  • Manages sessions                                         │       │
│  └─────────────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────────┘
           │                                     │
           │ MCP Protocol                        │ Your Protocol
           │ (JSON-RPC)                          │ (whatever your service speaks)
           ▼                                     ▼
    ┌─────────────┐                     ┌─────────────────────┐
    │   Agent     │                     │   Your Service      │
    │  (Claude)   │                     │   (not our concern) │
    └─────────────┘                     └─────────────────────┘
```

## Transport Layer

The transport layer is abstracted. Both stdio and HTTP are just data in/out:

```typescript
type Transport = {
  onMessage: (handler: (msg: TransportMessage) => Promise<void>) => void;
  send: (data: string) => void;
  start: () => void;
  stop: () => void;
};

type TransportMessage = {
  data: string;                      // incoming data
  respond: (response: string) => void; // send response back
};
```

**stdio transport:**
- Reads lines from stdin
- Writes lines to stdout
- Used by CLI tools like Claude Desktop

**HTTP transport:**
- POST /mcp for requests
- GET /sse for server-sent events
- Used by web clients

The bridge core doesn't know or care which transport is in use.

## Data Flow

### Agent → Service (tool calls)

```
Agent sends:     {"jsonrpc":"2.0","method":"tools/call","params":{"name":"send_message",...},"id":1}
                                    │
                                    ▼
Transport:       receives data string, calls onMessage handler
                                    │
                                    ▼
Bridge:          parses JSON-RPC, looks up tool, calls your handler
                                    │
                                    ▼
Your handler:    translates to your service's protocol, sends via WebSocket
                                    │
                                    ▼
Your service:    receives message in its native format
```

### Service → Agent (notifications)

```
Your service:    sends message via WebSocket
                                    │
                                    ▼
Bridge:          receives via onServiceMessage handler
                                    │
                                    ▼
Your handler:    calls context.notifyAgent(payload)
                                    │
                                    ▼
Transport:       sends data string (via SSE or stdout)
                                    │
                                    ▼
Agent:           receives notification
```

## What You Configure

1. **Tools** - capabilities exposed to the agent
2. **Tool handler** - translates MCP tool calls → your service's protocol
3. **Service message handler** - translates your service's messages → agent notifications
4. **Service URL** - where your service lives

## What This Library Handles

1. MCP protocol (JSON-RPC format, method routing)
2. Transport abstraction (stdio vs HTTP)
3. Session management
4. SSE for server→agent notifications

## What This Library Does NOT Handle

- Your service's protocol (you translate it)
- Your service's authentication (you handle it)
- Your service's error codes (you map them)

The underlying service is a black box.
