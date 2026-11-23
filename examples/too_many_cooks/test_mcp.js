const { McpServer } = require('@modelcontextprotocol/sdk/server/mcp.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');

async function main() {
  const server = new McpServer({ name: 'test', version: '1.0.0' });
  
  // Register a simple tool
  server.tool('echo', { description: 'Echo tool' }, async (args) => {
    return { content: [{ type: 'text', text: JSON.stringify(args) }] };
  });

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);
