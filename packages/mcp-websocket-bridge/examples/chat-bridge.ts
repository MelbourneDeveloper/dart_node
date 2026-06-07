import {
  createBridge,
  defineTool,
  defineNotification,
  onToolCall,
  onServiceMessage,
  connectService,
  start,
} from '../src/index.js';

// Create the bridge
const bridge = createBridge({
  name: 'chat-bridge',
  version: '1.0.0',
});

// Define tools
defineTool(bridge, {
  name: 'list_rooms',
  description: 'List available chat rooms',
  inputSchema: { type: 'object', properties: {} },
});

defineTool(bridge, {
  name: 'join_room',
  description: 'Join a chat room to receive messages',
  inputSchema: {
    type: 'object',
    properties: {
      room: { type: 'string', description: 'Room name or ID' },
    },
    required: ['room'],
  },
});

defineTool(bridge, {
  name: 'send_message',
  description: 'Send a message to a room',
  inputSchema: {
    type: 'object',
    properties: {
      room: { type: 'string' },
      content: { type: 'string' },
    },
    required: ['room', 'content'],
  },
});

defineTool(bridge, {
  name: 'leave_room',
  description: 'Leave a chat room',
  inputSchema: {
    type: 'object',
    properties: {
      room: { type: 'string' },
    },
    required: ['room'],
  },
});

// Define notifications
defineNotification(bridge, {
  name: 'message_received',
  description: 'A new message arrived in a joined room',
  schema: {
    type: 'object',
    properties: {
      room: { type: 'string' },
      from: { type: 'string' },
      content: { type: 'string' },
      timestamp: { type: 'string' },
    },
  },
});

defineNotification(bridge, {
  name: 'user_joined',
  description: 'A user joined a room',
  schema: {
    type: 'object',
    properties: {
      room: { type: 'string' },
      user: { type: 'string' },
    },
  },
});

// Handle agent tool calls
onToolCall(bridge, async (tool, args, ctx) => {
  const ws = ctx.ws;

  switch (tool) {
    case 'list_rooms':
      ws.send(JSON.stringify({ action: 'list_rooms' }));
      return { status: 'fetching' };

    case 'join_room':
      ws.send(JSON.stringify({ action: 'join', room: args.room }));
      return { joined: args.room };

    case 'send_message':
      ws.send(JSON.stringify({
        action: 'message',
        room: args.room,
        content: args.content,
      }));
      return { sent: true };

    case 'leave_room':
      ws.send(JSON.stringify({ action: 'leave', room: args.room }));
      return { left: args.room };

    default:
      throw new Error(`Unknown tool: ${tool}`);
  }
});

// Handle messages from chat service
onServiceMessage(bridge, async (raw, ctx) => {
  const msg = JSON.parse(raw.toString()) as {
    type: string;
    rooms?: string[];
    room?: string;
    from?: string;
    content?: string;
    timestamp?: string;
    user?: string;
  };

  switch (msg.type) {
    case 'room_list':
      await ctx.notifyAgent({
        notification: 'room_list',
        rooms: msg.rooms,
      });
      break;

    case 'message':
      await ctx.notifyAgent({
        notification: 'message_received',
        room: msg.room,
        from: msg.from,
        content: msg.content,
        timestamp: msg.timestamp,
      });
      break;

    case 'user_joined':
      await ctx.notifyAgent({
        notification: 'user_joined',
        room: msg.room,
        user: msg.user,
      });
      break;
  }
});

// Connect to your chat service
connectService(bridge, 'wss://chat.example.com/ws');

// Start with stdio (for Claude Desktop) or HTTP (for web)
const transport = process.argv.includes('--http')
  ? { type: 'http' as const, port: 3000 }
  : { type: 'stdio' as const };

start(bridge, transport);
