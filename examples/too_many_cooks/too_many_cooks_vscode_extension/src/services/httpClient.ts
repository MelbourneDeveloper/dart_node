// HTTP client utilities for MCP server communication.

const CONTENT_TYPE_JSON: string = 'application/json';
const MCP_ACCEPT_HEADER: string = 'application/json, text/event-stream';
const DATA_PREFIX: string = 'data: ';

function buildMcpHeaders(sessionId: string | null): Headers {
  const headers: Headers = new Headers();
  headers.set('accept', MCP_ACCEPT_HEADER);
  headers.set('content-type', CONTENT_TYPE_JSON);
  if (sessionId !== null) {
    headers.set('mcp-session-id', sessionId);
  }
  return headers;
}

export async function streamableHttpPost(
  url: string,
  body: string,
  sessionId: string | null,
): Promise<Response> {
  return await fetch(url, {
    body,
    headers: buildMcpHeaders(sessionId),
    method: 'POST',
  });
}

export async function postJsonRequest(
  url: string,
  body: Readonly<Record<string, unknown>>,
): Promise<string> {
  const headers: Headers = new Headers();
  headers.set('content-type', CONTENT_TYPE_JSON);
  const response: Response = await fetch(url, {
    body: JSON.stringify(body),
    headers,
    method: 'POST',
  });
  return response.text();
}

export async function checkServerAvailable(baseUrl: string): Promise<boolean> {
  try {
    const response: Response = await fetch(`${baseUrl}/admin/status`);
    return response.ok;
  } catch {
    return false;
  }
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function parseStreamableHttpResponse(text: string): Record<string, unknown> {
  if (text.trimStart().startsWith('{')) {
    const parsed: unknown = JSON.parse(text);
    if (isRecord(parsed)) {
      return parsed;
    }
    throw new Error('Invalid JSON response');
  }

  for (const line of text.split('\n')) {
    if (line.startsWith(DATA_PREFIX)) {
      const lineData: string = line.substring(DATA_PREFIX.length);
      try {
        const parsed: unknown = JSON.parse(lineData);
        if (isRecord(parsed)) {
          return parsed;
        }
      } catch {
        // Skip unparseable event-stream lines
      }
    }
  }

  throw new Error('Could not parse Streamable HTTP response');
}
