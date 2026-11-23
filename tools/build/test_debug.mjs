import { spawn } from 'child_process';

const proc = spawn('node', ['build/bin/debug_server_node.js'], { stdio: ['pipe', 'pipe', 'pipe'] });

proc.stdout.on('data', (chunk) => {
  console.log('STDOUT:', JSON.stringify(chunk.toString()));
});

proc.stderr.on('data', (chunk) => {
  console.log('STDERR:', chunk.toString());
});

const request = {
  jsonrpc: '2.0',
  id: 1,
  method: 'initialize',
  params: {
    protocolVersion: '2024-11-05',
    capabilities: {},
    clientInfo: { name: 'test', version: '1.0.0' }
  }
};

setTimeout(() => {
  console.log('Sending initialize...');
  proc.stdin.write(JSON.stringify(request) + '\n');
}, 500);

setTimeout(() => {
  const notif = {
    jsonrpc: '2.0',
    method: 'notifications/initialized'
  };
  console.log('Sending initialized notification...');
  proc.stdin.write(JSON.stringify(notif) + '\n');
}, 600);

setTimeout(() => {
  // Try echo tool first
  const toolsCall = {
    jsonrpc: '2.0',
    id: 2,
    method: 'tools/call',
    params: { name: 'echo', arguments: { msg: 'hello' } }
  };
  console.log('Sending echo tool call...');
  proc.stdin.write(JSON.stringify(toolsCall) + '\n');
}, 1000);

setTimeout(() => {
  // Try db_test tool
  const toolsCall = {
    jsonrpc: '2.0',
    id: 3,
    method: 'tools/call',
    params: { name: 'db_test', arguments: { name: 'agent-1' } }
  };
  console.log('Sending db_test tool call...');
  proc.stdin.write(JSON.stringify(toolsCall) + '\n');
}, 1500);

setTimeout(() => {
  console.log('Timeout - exiting');
  proc.kill();
  process.exit(0);
}, 5000);
