# MCP-WebSocket Bridge

A library for exposing WebSocket-based services to AI agents via the Model Context Protocol.

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

const bridge = createBridge({
  name: 'my-service',
  version: '1.0.0',
});

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

onToolCall(bridge, async (toolName, args, context) => {
  if (toolName === 'send_message') {
    await context.ws.send(JSON.stringify({
      type: 'message',
      room: args.room,
      content: args.content,
    }));
    return { success: true };
  }
});

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

connectService(bridge, 'wss://your-service.example.com');
listen(bridge, 3000);
```

## API

See the [examples](./examples) directory for complete usage examples.

## License

MIT
