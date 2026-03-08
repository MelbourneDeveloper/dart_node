// Unit tests to ISOLATE why admin event streaming does not work.
// Each test targets one piece of the pipeline in isolation.

const BASE_URL = 'http://localhost:4040';
const ADMIN_EVENTS_PATH = '/admin/events';
const MCP_HEADERS = {
  'accept': 'application/json, text/event-stream',
  'content-type': 'application/json',
};

// ============================================================================
// Helpers - minimal, no VSIX dependency
// ============================================================================

async function initAdminSessionDirect(): Promise<string> {
  const body = JSON.stringify({
    id: 1,
    jsonrpc: '2.0',
    method: 'initialize',
    params: {
      capabilities: {},
      clientInfo: { name: 'streaming-unit-test', version: '1.0.0' },
      protocolVersion: '2025-03-26',
    },
  });
  const response = await fetch(`${BASE_URL}${ADMIN_EVENTS_PATH}`, {
    body,
    headers: MCP_HEADERS,
    method: 'POST',
  });
  const sessionId = response.headers.get('mcp-session-id');
  if (!sessionId) {
    const text = await response.text();
    throw new Error(`No admin session ID. Status: ${response.status}, Body: ${text}`);
  }
  // Send initialized notification
  const notifyBody = JSON.stringify({
    jsonrpc: '2.0',
    method: 'notifications/initialized',
    params: {},
  });
  const notifyResp = await fetch(`${BASE_URL}${ADMIN_EVENTS_PATH}`, {
    body: notifyBody,
    headers: { ...MCP_HEADERS, 'mcp-session-id': sessionId },
    method: 'POST',
  });
  console.log(`[UNIT] Admin session initialized: ${sessionId}, notify status: ${notifyResp.status}`);
  return sessionId;
}

async function initMcpSessionDirect(): Promise<string> {
  const body = JSON.stringify({
    id: 1,
    jsonrpc: '2.0',
    method: 'initialize',
    params: {
      capabilities: {},
      clientInfo: { name: 'streaming-unit-test-mcp', version: '1.0.0' },
      protocolVersion: '2025-03-26',
    },
  });
  const response = await fetch(`${BASE_URL}/mcp`, {
    body,
    headers: MCP_HEADERS,
    method: 'POST',
  });
  const sessionId = response.headers.get('mcp-session-id');
  if (!sessionId) {
    throw new Error(`No MCP session ID. Status: ${response.status}`);
  }
  const notifyBody = JSON.stringify({
    jsonrpc: '2.0',
    method: 'notifications/initialized',
    params: {},
  });
  await fetch(`${BASE_URL}/mcp`, {
    body: notifyBody,
    headers: { ...MCP_HEADERS, 'mcp-session-id': sessionId },
    method: 'POST',
  });
  return sessionId;
}

async function registerAgentDirect(mcpSessionId: string, name: string): Promise<string> {
  const body = JSON.stringify({
    id: Date.now(),
    jsonrpc: '2.0',
    method: 'tools/call',
    params: { arguments: { name }, name: 'register' },
  });
  const response = await fetch(`${BASE_URL}/mcp`, {
    body,
    headers: { ...MCP_HEADERS, 'mcp-session-id': mcpSessionId },
    method: 'POST',
  });
  const text = await response.text();
  console.log(`[UNIT] Register response (first 200): ${text.substring(0, 200)}`);
  return text;
}

function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ============================================================================
// Tests
// ============================================================================

suite('Streaming Unit - Isolate Pipeline', () => {

  // -------------------------------------------------------------------------
  // PIECE 1: Can we even init an admin session?
  // -------------------------------------------------------------------------
  test('UNIT: Admin session initialization returns a session ID', async () => {
    const sessionId = await initAdminSessionDirect();
    console.log(`[UNIT] Got admin session ID: ${sessionId}`);
    if (!sessionId || sessionId.length === 0) {
      throw new Error('Admin session ID is empty');
    }
  });

  // -------------------------------------------------------------------------
  // PIECE 2: Does GET /admin/events return an SSE stream?
  // -------------------------------------------------------------------------
  test('UNIT: GET /admin/events returns SSE stream (content-type check)', async () => {
    const sessionId = await initAdminSessionDirect();

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3000);

    try {
      const response = await fetch(`${BASE_URL}${ADMIN_EVENTS_PATH}`, {
        headers: {
          'accept': 'application/json, text/event-stream',
          'mcp-session-id': sessionId,
        },
        method: 'GET',
        signal: controller.signal,
      });

      console.log(`[UNIT] GET /admin/events status: ${response.status}`);
      console.log(`[UNIT] GET /admin/events content-type: ${response.headers.get('content-type')}`);
      console.log(`[UNIT] GET /admin/events headers:`);
      response.headers.forEach((value, key) => {
        console.log(`[UNIT]   ${key}: ${value}`);
      });

      if (!response.ok) {
        const body = await response.text();
        throw new Error(`GET /admin/events failed: ${response.status} - ${body}`);
      }

      const contentType = response.headers.get('content-type') ?? '';
      console.log(`[UNIT] Content-Type: "${contentType}"`);

      if (!contentType.includes('text/event-stream')) {
        throw new Error(
          `Expected text/event-stream content-type, got: "${contentType}". ` +
          `This means the server is NOT returning an SSE stream!`
        );
      }

      // Check that body is a readable stream
      if (!response.body) {
        throw new Error('Response body is null - no stream available');
      }

      console.log('[UNIT] SSE stream opened successfully');
    } finally {
      clearTimeout(timeout);
      controller.abort();
    }
  });

  // -------------------------------------------------------------------------
  // PIECE 3: Does the server PUSH events when state changes?
  // -------------------------------------------------------------------------
  test('UNIT: Server pushes SSE event when agent registered', async function () {
    this.timeout(10000);

    const adminSessionId = await initAdminSessionDirect();
    const mcpSessionId = await initMcpSessionDirect();

    // Open SSE stream
    const controller = new AbortController();
    const receivedChunks: string[] = [];
    let streamError: string | null = null;

    const streamPromise = fetch(`${BASE_URL}${ADMIN_EVENTS_PATH}`, {
      headers: {
        'accept': 'application/json, text/event-stream',
        'mcp-session-id': adminSessionId,
      },
      method: 'GET',
      signal: controller.signal,
    }).then(async (response) => {
      console.log(`[UNIT] SSE stream response status: ${response.status}`);
      console.log(`[UNIT] SSE stream content-type: ${response.headers.get('content-type')}`);

      if (!response.ok) {
        streamError = `SSE stream failed: ${response.status}`;
        return;
      }
      if (!response.body) {
        streamError = 'SSE stream body is null';
        return;
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();

      try {
        for (;;) {
          const { done, value } = await reader.read();
          if (done) {
            console.log('[UNIT] SSE stream ended (done=true)');
            break;
          }
          const chunk = decoder.decode(value, { stream: true });
          console.log(`[UNIT] SSE chunk received (${chunk.length} bytes): "${chunk.substring(0, 200)}"`);
          receivedChunks.push(chunk);
        }
      } catch (err: unknown) {
        if (!controller.signal.aborted) {
          streamError = `Stream read error: ${String(err)}`;
          console.log(`[UNIT] ${streamError}`);
        }
      }
    }).catch((err: unknown) => {
      if (!controller.signal.aborted) {
        streamError = `Fetch error: ${String(err)}`;
        console.log(`[UNIT] ${streamError}`);
      }
    });

    // Give the stream a moment to establish
    await delay(500);

    // Now trigger a state change by registering an agent
    const agentName = `unit-test-stream-${Date.now()}`;
    console.log(`[UNIT] Registering agent: ${agentName}`);
    await registerAgentDirect(mcpSessionId, agentName);

    // Wait for events to arrive
    console.log('[UNIT] Waiting for SSE events...');
    await delay(2000);

    // Abort the stream
    controller.abort();

    // Wait for stream promise to settle
    await streamPromise.catch(() => {});

    console.log(`[UNIT] Total chunks received: ${receivedChunks.length}`);
    console.log(`[UNIT] Stream error: ${streamError ?? 'none'}`);

    if (streamError) {
      throw new Error(`Stream error: ${streamError}`);
    }

    // Check if we got any SSE data
    const allData = receivedChunks.join('');
    console.log(`[UNIT] All SSE data (${allData.length} bytes): "${allData.substring(0, 500)}"`);

    const dataLines = allData.split('\n').filter(l => l.startsWith('data: '));
    console.log(`[UNIT] SSE data lines: ${dataLines.length}`);
    for (const line of dataLines) {
      console.log(`[UNIT]   ${line.substring(0, 200)}`);
    }

    if (dataLines.length === 0) {
      throw new Error(
        'NO SSE events received after registering agent! ' +
        `Total chunks: ${receivedChunks.length}, total bytes: ${allData.length}. ` +
        'The server is NOT pushing events on state changes.'
      );
    }
  });

  // -------------------------------------------------------------------------
  // PIECE 4: Does readEventStream parse SSE correctly? (In-memory test)
  // -------------------------------------------------------------------------
  test('UNIT: readEventStream parses SSE data lines and calls onEvent', async () => {
    // Simulate an SSE stream using a ReadableStream
    let eventCount = 0;
    const onEvent = (): void => { eventCount += 1; };

    const ssePayload = [
      'event: message\n',
      'data: {"jsonrpc":"2.0","method":"notifications/resources/list_changed"}\n',
      '\n',
      'event: message\n',
      'data: {"jsonrpc":"2.0","method":"notifications/resources/list_changed"}\n',
      '\n',
    ].join('');

    const encoder = new TextEncoder();
    const stream = new ReadableStream<Uint8Array>({
      start(controller) {
        controller.enqueue(encoder.encode(ssePayload));
        controller.close();
      },
    });

    // Replicate the readEventStream logic inline (to test it in isolation)
    const reader = stream.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    const dataPrefix = 'data: ';

    for (;;) {
      const result = await reader.read();
      if (result.done) { break; }
      buffer += decoder.decode(result.value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() ?? '';
      for (const line of lines) {
        if (line.startsWith(dataPrefix)) {
          const lineData = line.substring(dataPrefix.length).trim();
          if (lineData.length > 0) {
            onEvent();
          }
        }
      }
    }

    console.log(`[UNIT] readEventStream parsed ${eventCount} events`);
    if (eventCount !== 2) {
      throw new Error(`Expected 2 events, got ${eventCount}`);
    }
  });

  // -------------------------------------------------------------------------
  // PIECE 5: Does the VSIX admin event stream actually connect and receive?
  // (Uses the actual startAdminEventStream from source)
  // -------------------------------------------------------------------------
  test('UNIT: startAdminEventStream receives events from server', async function () {
    this.timeout(10000);

    // Import the actual function from source
    const { startAdminEventStream } = await import('../../src/services/adminEventStream');

    const mcpSessionId = await initMcpSessionDirect();

    const events: string[] = [];
    const logs: string[] = [];
    const abortController = new AbortController();

    startAdminEventStream(abortController, {
      baseUrl: BASE_URL,
      log: (msg: string) => {
        console.log(`[UNIT-ADMIN] ${msg}`);
        logs.push(msg);
      },
      onEvent: () => {
        events.push(`event-${Date.now()}`);
        console.log(`[UNIT-ADMIN] onEvent fired! Total: ${events.length}`);
      },
    });

    // Wait for the session to initialize
    await delay(1000);

    console.log(`[UNIT] Logs after init: ${logs.length}`);
    for (const log of logs) {
      console.log(`[UNIT]   ${log}`);
    }

    // Check if session started successfully
    const sessionStarted = logs.some(l => l.includes('Session started'));
    const sessionError = logs.some(l => l.includes('Session error'));

    if (sessionError) {
      const errorLog = logs.find(l => l.includes('Session error'));
      throw new Error(`Admin session failed to start: ${errorLog}`);
    }

    if (!sessionStarted) {
      throw new Error(
        `Admin session did not start within 1s. Logs: ${JSON.stringify(logs)}`
      );
    }

    // Now trigger a state change
    const agentName = `unit-admin-stream-${Date.now()}`;
    console.log(`[UNIT] Registering agent to trigger event: ${agentName}`);
    await registerAgentDirect(mcpSessionId, agentName);

    // Wait for event to arrive
    await delay(2000);

    abortController.abort();

    console.log(`[UNIT] Events received: ${events.length}`);
    console.log(`[UNIT] All logs:`);
    for (const log of logs) {
      console.log(`[UNIT]   ${log}`);
    }

    if (events.length === 0) {
      throw new Error(
        'startAdminEventStream received ZERO events after registering agent! ' +
        `Logs: ${JSON.stringify(logs)}`
      );
    }
  });

  // -------------------------------------------------------------------------
  // PIECE 6: Full StoreManager pipeline - does store update via streaming?
  // -------------------------------------------------------------------------
  test('UNIT: StoreManager store updates via admin event stream', async function () {
    this.timeout(15000);

    const { StoreManager } = await import('../../src/services/storeManager');

    const logs: string[] = [];
    const sm = new StoreManager('.', (msg: string) => {
      console.log(`[UNIT-SM] ${msg}`);
      logs.push(msg);
    });

    // Connect (starts admin event stream internally)
    await sm.connect();

    if (!sm.isConnected) {
      throw new Error('StoreManager failed to connect');
    }

    const initialAgents = sm.state.agents.length;
    console.log(`[UNIT] Initial agent count: ${initialAgents}`);

    // Track store changes
    let storeChanged = false;
    const unsub = sm.subscribe(() => {
      storeChanged = true;
      console.log(`[UNIT-SM] Store changed! Agents: ${sm.state.agents.length}`);
    });

    // Register agent via direct MCP call (bypassing StoreManager)
    const mcpSessionId = await initMcpSessionDirect();
    const agentName = `unit-sm-stream-${Date.now()}`;
    console.log(`[UNIT] Registering agent directly: ${agentName}`);
    await registerAgentDirect(mcpSessionId, agentName);

    // Wait for the store to update via streaming
    const start = Date.now();
    const waitTimeout = 5000;
    while (Date.now() - start < waitTimeout) {
      if (sm.state.agents.some(a => a.agentName === agentName)) {
        break;
      }
      await delay(100);
    }

    unsub();

    // Check BEFORE disconnect (disconnect resets state)
    const agentFound = sm.state.agents.some(a => a.agentName === agentName);
    const finalAgentCount = sm.state.agents.length;
    console.log(`[UNIT] Agent found in store: ${agentFound}`);
    console.log(`[UNIT] Store changed: ${storeChanged}`);
    console.log(`[UNIT] Final agent count: ${finalAgentCount}`);
    console.log(`[UNIT] All SM logs:`);
    for (const log of logs) {
      console.log(`[UNIT]   ${log}`);
    }

    sm.disconnect();

    if (!agentFound) {
      throw new Error(
        `Agent "${agentName}" NOT found in store after 5s! ` +
        `Store changed: ${storeChanged}, agents: ${finalAgentCount}. ` +
        `This proves the admin event stream is NOT updating the store. ` +
        `Logs: ${JSON.stringify(logs)}`
      );
    }
  });
});
