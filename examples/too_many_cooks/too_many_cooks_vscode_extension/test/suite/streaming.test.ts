// Streaming Tests - PROVE that MCP server streams ALL changes to the VSIX.
// These tests bypass the VSIX's callTool (which calls refreshStatus internally)
// and instead call the MCP server directly via HTTP. The ONLY way tree views
// update is via the admin event stream. NO POLLING. NO MANUAL REFRESH.

import {
  waitForExtensionActivation,
  waitForConnection,
  waitForCondition,
  waitForAgentInTree,
  waitForLockInTree,
  waitForLockGone,
  waitForMessageInTree,
  safeDisconnect,
  getTestAPI,
  extractKeyFromResult,
  resetServerState,
  restoreDialogMocks,
  getLabel,
  hasChildWithLabel,
  dumpTree,
  assertOk,
  assertEqual,
} from './testHelpers';

restoreDialogMocks();

// Direct MCP server call - bypasses VSIX callTool and its refreshStatus().
// The ONLY way the tree can update is via the admin event stream.
const BASE_URL = 'http://localhost:4040';

interface McpSession {
  sessionId: string;
}

async function initDirectMcpSession(): Promise<McpSession> {
  const body = JSON.stringify({
    id: 1,
    jsonrpc: '2.0',
    method: 'initialize',
    params: {
      capabilities: {},
      clientInfo: { name: 'streaming-test-direct', version: '1.0.0' },
      protocolVersion: '2025-03-26',
    },
  });
  const mcpHeaders = { 'accept': 'application/json, text/event-stream', 'content-type': 'application/json' };
  const response = await fetch(`${BASE_URL}/mcp`, {
    body,
    headers: mcpHeaders,
    method: 'POST',
  });
  const sessionId = response.headers.get('mcp-session-id');
  if (!sessionId) { throw new Error('No session ID'); }
  const notifyBody = JSON.stringify({
    jsonrpc: '2.0',
    method: 'notifications/initialized',
    params: {},
  });
  await fetch(`${BASE_URL}/mcp`, {
    body: notifyBody,
    headers: { ...mcpHeaders, 'mcp-session-id': sessionId },
    method: 'POST',
  });
  return { sessionId };
}

async function directToolCall(
  session: McpSession,
  toolName: string,
  args: Record<string, unknown>,
): Promise<string> {
  const body = JSON.stringify({
    id: Date.now(),
    jsonrpc: '2.0',
    method: 'tools/call',
    params: { arguments: args, name: toolName },
  });
  const response = await fetch(`${BASE_URL}/mcp`, {
    body,
    headers: { 'accept': 'application/json, text/event-stream', 'content-type': 'application/json', 'mcp-session-id': session.sessionId },
    method: 'POST',
  });
  const text = await response.text();
  // Parse through possible SSE or JSON-RPC envelope
  const lines = text.split('\n').filter(l => l.startsWith('data: '));
  if (lines.length > 0) {
    const data = lines.map(l => l.substring(6).trim()).join('');
    try {
      const parsed = JSON.parse(data);
      const content = parsed?.result?.content;
      if (Array.isArray(content) && content.length > 0 && typeof content[0]?.text === 'string') {
        return content[0].text;
      }
    } catch { /* fall through */ }
  }
  // Try direct JSON parse
  try {
    const parsed = JSON.parse(text);
    const content = parsed?.result?.content;
    if (Array.isArray(content) && content.length > 0 && typeof content[0]?.text === 'string') {
      return content[0].text;
    }
  } catch { /* fall through */ }
  return text;
}

suite('Streaming - MCP Server Pushes ALL Changes to VSIX', () => {
  let directSession: McpSession;
  let agent1Key = '';
  let agent2Key = '';
  const testId = Date.now();
  const agent1Name = `stream-agent-${testId}-1`;
  const agent2Name = `stream-agent-${testId}-2`;

  suiteSetup(async () => {
    await waitForExtensionActivation();
    // Ensure server is running before resetting
    const api = getTestAPI();
    if (!api.isConnected()) {
      await api.connect();
      await waitForConnection();
    }
    await resetServerState();
    // Reset pushes an event — wait for store to clear via streaming
    await waitForCondition(
      () => getTestAPI().getAgentCount() === 0,
      'Store to clear after reset',
    );
    directSession = await initDirectMcpSession();
  });

  suiteTeardown(async () => {
    await safeDisconnect();
  });

  // =========================================================================
  // AGENT REGISTRATION - streamed to VSIX tree
  // =========================================================================

  test('STREAM: Register agent via direct HTTP → agent APPEARS in tree WITHOUT refreshStatus', async () => {
    const result = await directToolCall(directSession, 'register', { name: agent1Name });
    agent1Key = extractKeyFromResult(result);
    assertOk(agent1Key.length > 0, 'Should return agent key');

    // DO NOT call refreshStatus. The event stream MUST push this.
    await waitForAgentInTree(getTestAPI(), agent1Name);

    const agentItem = getTestAPI().findAgentInTree(agent1Name);
    assertOk(agentItem, `${agent1Name} MUST appear in tree via streaming`);
    assertEqual(getLabel(agentItem!), agent1Name, 'Label must match agent name');
  });

  test('STREAM: Register second agent via direct HTTP → both agents visible', async () => {
    const result = await directToolCall(directSession, 'register', { name: agent2Name });
    agent2Key = extractKeyFromResult(result);

    await waitForCondition(
      () => getTestAPI().getAgentsTreeSnapshot().length >= 2,
      '2 agents in tree via streaming',
    );

    assertOk(getTestAPI().findAgentInTree(agent1Name), `${agent1Name} MUST still be in tree`);
    assertOk(getTestAPI().findAgentInTree(agent2Name), `${agent2Name} MUST be in tree via streaming`);
  });

  // =========================================================================
  // LOCK OPERATIONS - streamed to VSIX tree
  // =========================================================================

  test('STREAM: Acquire lock via direct HTTP → lock APPEARS in locks tree', async () => {
    await directToolCall(directSession, 'lock', {
      action: 'acquire',
      agent_key: agent1Key,
      agent_name: agent1Name,
      file_path: '/stream/test.ts',
      reason: 'Streaming test',
    });

    await waitForLockInTree(getTestAPI(), '/stream/test.ts');

    const lockItem = getTestAPI().findLockInTree('/stream/test.ts');
    dumpTree('LOCKS after streamed acquire', getTestAPI().getLocksTreeSnapshot());
    assertOk(lockItem, '/stream/test.ts MUST appear in locks tree via streaming');
  });

  test('STREAM: Acquire second lock → both locks visible in tree', async () => {
    await directToolCall(directSession, 'lock', {
      action: 'acquire',
      agent_key: agent2Key,
      agent_name: agent2Name,
      file_path: '/stream/utils.ts',
      reason: 'Streaming test 2',
    });

    await waitForLockInTree(getTestAPI(), '/stream/utils.ts');

    assertOk(getTestAPI().findLockInTree('/stream/test.ts'), '/stream/test.ts MUST still be in tree');
    assertOk(getTestAPI().findLockInTree('/stream/utils.ts'), '/stream/utils.ts MUST be in tree via streaming');
  });

  test('STREAM: Release lock via direct HTTP → lock DISAPPEARS from tree', async () => {
    await directToolCall(directSession, 'lock', {
      action: 'release',
      agent_key: agent1Key,
      agent_name: agent1Name,
      file_path: '/stream/test.ts',
    });

    await waitForLockGone(getTestAPI(), '/stream/test.ts');

    assertEqual(getTestAPI().findLockInTree('/stream/test.ts'), null, '/stream/test.ts MUST NOT be in tree');
    assertOk(getTestAPI().findLockInTree('/stream/utils.ts'), '/stream/utils.ts MUST still be in tree');
  });

  // =========================================================================
  // PLAN UPDATES - streamed to VSIX tree
  // =========================================================================

  test('STREAM: Update plan via direct HTTP → plan APPEARS in agent children', async () => {
    await directToolCall(directSession, 'plan', {
      action: 'update',
      agent_key: agent1Key,
      agent_name: agent1Name,
      current_task: 'Proving streaming works',
      goal: 'Stream all the things',
    });

    await waitForCondition(() => {
      const agentItem = getTestAPI().findAgentInTree(agent1Name);
      if (!agentItem) { return false; }
      return hasChildWithLabel(agentItem, 'Stream all the things');
    }, 'Plan to appear in agent children via streaming');

    const agentItem = getTestAPI().findAgentInTree(agent1Name);
    assertOk(agentItem, `${agent1Name} MUST be in tree`);
    assertOk(
      hasChildWithLabel(agentItem!, 'Stream all the things'),
      'Plan goal MUST appear in agent children via streaming',
    );
  });

  // =========================================================================
  // MESSAGES - streamed to VSIX tree
  // =========================================================================

  test('STREAM: Send message via direct HTTP → message APPEARS in messages tree', async () => {
    await directToolCall(directSession, 'message', {
      action: 'send',
      agent_key: agent1Key,
      agent_name: agent1Name,
      content: 'Streamed message proof',
      to_agent: agent2Name,
    });

    await waitForMessageInTree(getTestAPI(), 'Streamed message');

    const msgItem = getTestAPI().findMessageInTree('Streamed message');
    assertOk(msgItem, 'Message MUST appear in messages tree via streaming');

    const msgLabel = getLabel(msgItem!);
    assertOk(msgLabel.includes(agent1Name), `Message label should contain sender, got: ${msgLabel}`);
  });

  test('STREAM: Broadcast message via direct HTTP → broadcast APPEARS in tree', async () => {
    await directToolCall(directSession, 'message', {
      action: 'send',
      agent_key: agent2Key,
      agent_name: agent2Name,
      content: 'STREAM BROADCAST to all',
      to_agent: '*',
    });

    await waitForMessageInTree(getTestAPI(), 'STREAM BROADCAST');

    const broadcastMsg = getTestAPI().findMessageInTree('STREAM BROADCAST');
    assertOk(broadcastMsg, 'Broadcast MUST appear in tree via streaming');

    const label = getLabel(broadcastMsg!);
    assertOk(label.includes('all'), `Broadcast should show "all" for recipient, got: ${label}`);
  });

  // =========================================================================
  // CONNECT DOES NOT RESET SERVER
  // =========================================================================

  test('STREAM: Reconnect still receives streamed events', async () => {
    const api = getTestAPI();

    // Disconnect and reconnect
    await safeDisconnect();
    assertEqual(api.isConnected(), false, 'Should be disconnected');

    await api.connect();
    await waitForConnection();

    // Re-init direct session after reconnect
    directSession = await initDirectMcpSession();

    // Register a new agent via direct HTTP after reconnect
    const reconnectAgent = `stream-reconnect-${Date.now()}`;
    const result = await directToolCall(directSession, 'register', { name: reconnectAgent });
    const reconnectKey = extractKeyFromResult(result);
    assertOk(reconnectKey.length > 0, 'Should get key after reconnect');

    // Agent MUST appear via streaming after reconnect
    await waitForAgentInTree(api, reconnectAgent);
    assertOk(api.findAgentInTree(reconnectAgent), `${reconnectAgent} MUST appear via streaming after reconnect`);
  });

  // =========================================================================
  // FULL ROUND TRIP - all operations streamed, verified at tree level
  // =========================================================================

  test('STREAM: Full round trip - register, lock, plan, message all stream to tree', async () => {
    // Re-init direct session after reconnect
    directSession = await initDirectMcpSession();

    const roundTripAgent = `stream-roundtrip-${testId}`;
    const rtResult = await directToolCall(directSession, 'register', { name: roundTripAgent });
    const rtKey = extractKeyFromResult(rtResult);

    // Wait for agent to appear via stream
    await waitForAgentInTree(getTestAPI(), roundTripAgent);

    // Acquire lock via stream
    await directToolCall(directSession, 'lock', {
      action: 'acquire',
      agent_key: rtKey,
      agent_name: roundTripAgent,
      file_path: '/stream/roundtrip.ts',
      reason: 'Full round trip',
    });
    await waitForLockInTree(getTestAPI(), '/stream/roundtrip.ts');

    // Update plan via stream
    await directToolCall(directSession, 'plan', {
      action: 'update',
      agent_key: rtKey,
      agent_name: roundTripAgent,
      current_task: 'Round trip task',
      goal: 'Round trip goal',
    });
    await waitForCondition(() => {
      const item = getTestAPI().findAgentInTree(roundTripAgent);
      if (!item) { return false; }
      return hasChildWithLabel(item, 'Round trip goal');
    }, 'Round trip plan in tree');

    // Send message via stream
    await directToolCall(directSession, 'message', {
      action: 'send',
      agent_key: rtKey,
      agent_name: roundTripAgent,
      content: 'Round trip message proof',
      to_agent: '*',
    });
    await waitForMessageInTree(getTestAPI(), 'Round trip message');

    // ALL operations verified at tree/DOM level via streaming
    dumpTree('FINAL AGENTS', getTestAPI().getAgentsTreeSnapshot());
    dumpTree('FINAL LOCKS', getTestAPI().getLocksTreeSnapshot());
    dumpTree('FINAL MESSAGES', getTestAPI().getMessagesTreeSnapshot());

    assertOk(getTestAPI().findAgentInTree(roundTripAgent), 'Round trip agent in tree');
    assertOk(getTestAPI().findLockInTree('/stream/roundtrip.ts'), 'Round trip lock in tree');
    assertOk(getTestAPI().findMessageInTree('Round trip message'), 'Round trip message in tree');

    const agentItem = getTestAPI().findAgentInTree(roundTripAgent);
    assertOk(agentItem, 'Round trip agent MUST exist');
    assertOk(hasChildWithLabel(agentItem!, 'Round trip goal'), 'Round trip plan in agent children');
    assertOk(hasChildWithLabel(agentItem!, '/stream/roundtrip.ts'), 'Round trip lock in agent children');
  });
});
