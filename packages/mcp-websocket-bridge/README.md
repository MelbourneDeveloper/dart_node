# MCP-WebSocket Bridge

This library **IS** an MCP server. It translates between MCP protocol (spoken to AI agents) and your existing WebSocket/HTTP service.

```
┌─────────────┐                                 ┌─────────────────────┐
│   Agent     │◄── stdio or HTTP ─────────────►│  MCP-WebSocket      │
│  (Claude)   │     (just data in/out)          │  Bridge             │
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

**Key points:**
- Transport is abstracted: stdio or HTTP are just data in/out
- The bridge handles all MCP protocol details
- You only configure how to translate between MCP tool calls and your service

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
  start,
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
    await context.notifyAgent({
      type: 'chat_message',
      from: data.from,
      content: data.content,
    });
  }
});

// Connect to your existing service
connectService(bridge, 'wss://your-service.example.com');

// Start with stdio (for CLI tools like Claude Desktop)
start(bridge, { type: 'stdio' });

// Or start with HTTP (for web clients)
// start(bridge, { type: 'http', port: 3000 });
```

## Transport Options

```typescript
// stdio - for CLI integrations (Claude Desktop, etc.)
start(bridge, { type: 'stdio' });

// HTTP - for web clients
start(bridge, { type: 'http', port: 3000, host: '0.0.0.0' });
```

Both transports handle the same data format - the bridge doesn't care how data arrives, just what's in it.

## What This Library Does

1. **Speaks MCP** - Handles JSON-RPC messages per the MCP spec
2. **Exposes tools** - Agents discover and call tools you define
3. **Routes calls** - Translates MCP tool calls to your service's protocol
4. **Pushes events** - Forwards your service's messages to agents

## What You Provide

1. **Tool definitions** - What capabilities to expose to agents
2. **Translation logic** - How to convert between MCP and your service's protocol
3. **Your service URL** - Where to connect

The underlying service is a black box. It could be a chat server, database, IoT controller, or anything with a WebSocket or HTTP interface.

## API

See the [examples](./examples) directory for complete usage examples.

## License

MIT
