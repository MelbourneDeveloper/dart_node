import { createServer, type IncomingMessage, type ServerResponse } from 'http';
import { createInterface } from 'readline';

export type TransportMessage = {
  data: string;
  respond: (response: string) => void;
};

export type TransportConfig =
  | { type: 'stdio' }
  | { type: 'http'; port: number; host?: string };

export type Transport = {
  onMessage: (handler: (msg: TransportMessage) => Promise<void>) => void;
  send: (data: string) => void;
  start: () => void;
  stop: () => void;
};

export const createStdioTransport = (): Transport => {
  let messageHandler: ((msg: TransportMessage) => Promise<void>) | null = null;
  let rl: ReturnType<typeof createInterface> | null = null;

  return {
    onMessage: (handler) => {
      messageHandler = handler;
    },
    send: (data) => {
      process.stdout.write(data + '\n');
    },
    start: () => {
      rl = createInterface({ input: process.stdin, output: process.stdout, terminal: false });
      rl.on('line', async (line) => {
        if (messageHandler) {
          await messageHandler({
            data: line,
            respond: (response) => process.stdout.write(response + '\n'),
          });
        }
      });
    },
    stop: () => {
      rl?.close();
    },
  };
};

export const createHttpTransport = (port: number, host = '0.0.0.0'): Transport => {
  let messageHandler: ((msg: TransportMessage) => Promise<void>) | null = null;
  let server: ReturnType<typeof createServer> | null = null;
  const sseClients: Set<ServerResponse> = new Set();

  const handleRequest = async (req: IncomingMessage, res: ServerResponse) => {
    const url = new URL(req.url ?? '/', `http://${req.headers.host}`);

    if (req.method === 'GET' && url.pathname === '/sse') {
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
        'Access-Control-Allow-Origin': '*',
      });
      sseClients.add(res);
      req.on('close', () => sseClients.delete(res));
      return;
    }

    if (req.method === 'POST' && url.pathname === '/mcp') {
      const chunks: Buffer[] = [];
      for await (const chunk of req) chunks.push(chunk);
      const body = Buffer.concat(chunks).toString();

      if (messageHandler) {
        await messageHandler({
          data: body,
          respond: (response) => {
            res.writeHead(200, {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
            });
            res.end(response);
          },
        });
      }
      return;
    }

    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      });
      res.end();
      return;
    }

    res.writeHead(404);
    res.end('Not found');
  };

  return {
    onMessage: (handler) => {
      messageHandler = handler;
    },
    send: (data) => {
      sseClients.forEach((client) => client.write(`data: ${data}\n\n`));
    },
    start: () => {
      server = createServer((req, res) => {
        handleRequest(req, res).catch((err) => {
          console.error('Request error:', err);
          res.writeHead(500);
          res.end('Internal error');
        });
      });
      server.listen(port, host, () => {
        console.log(`MCP server listening on ${host}:${port}`);
      });
    },
    stop: () => {
      sseClients.forEach((client) => client.end());
      sseClients.clear();
      server?.close();
    },
  };
};

export const createTransport = (config: TransportConfig): Transport =>
  config.type === 'stdio'
    ? createStdioTransport()
    : createHttpTransport(config.port, config.host);
