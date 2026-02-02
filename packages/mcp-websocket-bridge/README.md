# MCP-WebSocket Bridge

This library **IS** an MCP server. It translates between the MCP protocol (spoken to AI agents like Claude) and your existing WebSocket/HTTP service.

```
┌─────────────┐      MCP (Streamable HTTP)      ┌─────────────────────┐
│   Agent     │◄──────────────────────────────►│  MCP-WebSocket      │
│  (Claude)   │      POST /mcp + SSE            │  Bridge             │
└─────────────┘                                 │  (THIS IS THE       │
                                                │   MCP SERVER)       │
                                                └──────────┬──────────┘
                                                           │
                                                           │ WebSocket / HTTP
                                                           ▼
                                                ┌─────────────────────┐
                                                │  Your Service       │
                                                │  (not our concern)  │
                                                └─────────────────────┘
```

**Key point:** The bridge handles all MCP protocol details. You only configure how to translate between MCP tool calls and your service's WebSocket/HTTP protocol.

## Installation

```bash
npm install mcp-websocket-bridge
```

## Quick Start

```typescript
import {
  createBridge,
  defineTool,
  onToolCall,
  onServiceMessage,
  connectService,
  listen,
} from 'mcp-websocket-bridge';

// Create the MCP server (the bridge)
const bridge = createBridge({
  name: 'my-service',
  version: '1.0.0',
});

// Define what tools agents can call
defineTool(bridge, {
  name: 'send_message',
  description: 'Send a message to the chat room',
  inputSchema: {
    type: 'object',
    properties: {
      room: { type: 'string' },
      content: { type: 'string' },
    },
    required: ['room', 'content'],
  },
});

// Translate tool calls to your service's protocol
onToolCall(bridge, async (toolName, args, context) => {
  if (toolName === 'send_message') {
    // Send to your service using whatever protocol it expects
    context.ws.send(JSON.stringify({
      type: 'message',
      room: args.room,
      content: args.content,
    }));
    return { success: true };
  }
});

// Translate your service's messages to agent notifications
onServiceMessage(bridge, async (message, context) => {
  const data = JSON.parse(message.toString());

  if (data.type === 'new_message') {
    // Push to agent via SSE
    await context.notifyAgent({
      type: 'chat_message',
      from: data.from,
      content: data.content,
    });
  }
});

// Connect to your existing service
connectService(bridge, 'wss://your-service.example.com');

// Start the MCP server
listen(bridge, 3000);
```

## What This Library Does

1. **Speaks MCP** - Handles `POST /mcp` and `GET /sse` endpoints per the MCP spec
2. **Exposes tools** - Agents discover and call tools you define
3. **Routes calls** - Translates MCP tool calls to your service's protocol
4. **Pushes events** - Forwards your service's messages to agents via SSE

## What You Provide

1. **Tool definitions** - What capabilities to expose to agents
2. **Translation logic** - How to convert between MCP and your service's protocol
3. **Your service URL** - Where to connect

The underlying service is a black box to this library. It could be a chat server, database, IoT controller, or anything with a WebSocket or HTTP interface.

## API

See the [examples](./examples) directory for complete usage examples.

## License

MIT
