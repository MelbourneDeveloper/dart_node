# Too Many Cooks - Fix Plan

## The Problem

Currently the VSCode extension spawns its OWN MCP server process. Claude Code also spawns its OWN MCP server process. They are completely separate:

- Different processes
- Different SQLite databases
- No shared state

When Claude Code registers an agent, the VSCode extension doesn't see it because they're talking to different servers.

## The Solution

**ONE PROCESS. ONE DATABASE.**

### Option A: Shared Database File (Simplest)

All MCP server instances use the SAME database file path. The database is the source of truth.

1. **Fix the database path** in `examples/too_many_cooks/lib/src/config.dart`:
   - Use an absolute path in a known location (e.g., `~/.too_many_cooks/data.db`)
   - NOT relative to cwd

2. **Polling for changes**: VSCode extension polls the database periodically via `refreshStatus()` since it can't receive notifications from Claude Code's server.

3. **SQLite handles concurrency**: Multiple readers, single writer. WAL mode already enabled.

### Option B: HTTP Server (Better but more work)

Run a single HTTP server that both Claude Code and VSCode connect to.

1. **Start server once**: A daemon process or the first client starts it
2. **Both clients connect**: Via HTTP/WebSocket to same server
3. **Real-time updates**: Server broadcasts changes to all connected clients

### Option C: Unix Socket / Named Pipe

Similar to HTTP but using local IPC.

---

## Recommended: Option A (Shared Database)

### Step 1: Fix Database Path

In `examples/too_many_cooks/lib/src/config.dart`, change:

```dart
// FROM: relative path (different per process cwd)
static String get dbPath => '.too_many_cooks.db';

// TO: absolute path in user home directory
static String get dbPath {
  final home = Platform.environment['HOME'] ?? '/tmp';
  return '$home/.too_many_cooks/data.db';
}
```

### Step 2: Create Directory on Startup

In `examples/too_many_cooks/lib/src/db/db.dart`, ensure the directory exists:

```dart
Future<void> init() async {
  final dir = Directory(path.dirname(config.dbPath));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  // ... rest of init
}
```

### Step 3: VSCode Extension Polls for Changes

In `examples/too_many_cooks_vscode_extension/src/state/store.ts`:

```typescript
// Poll every 2 seconds when connected
private pollInterval: NodeJS.Timeout | null = null;

async connect(): Promise<void> {
  // ... existing connect code ...

  // Start polling
  this.pollInterval = setInterval(() => {
    this.refreshStatus().catch(console.error);
  }, 2000);
}

async disconnect(): Promise<void> {
  if (this.pollInterval) {
    clearInterval(this.pollInterval);
    this.pollInterval = null;
  }
  // ... existing disconnect code ...
}
```

### Step 4: Rebuild Everything

```bash
cd examples/too_many_cooks && ./build.sh
cd ../too_many_cooks_vscode_extension && ./install.sh
```

### Step 5: Verify

1. Claude Code registers an agent
2. VSCode extension sees it within 2 seconds
3. VSCode locks a file
4. Claude Code sees it via `mcp__too-many-cooks__status`

---

## Files to Modify

1. `examples/too_many_cooks/lib/src/config.dart` - Absolute DB path
2. `examples/too_many_cooks/lib/src/db/db.dart` - Create directory
3. `examples/too_many_cooks_vscode_extension/src/state/store.ts` - Add polling
4. Rebuild MCP server and VSCode extension

---

## Testing

After implementation, the E2E test should:

1. Start MCP server (via extension)
2. Register agent via `callTool('register', ...)`
3. **Separately** call status to verify DB has the agent
4. Verify tree view shows the agent

The current tests already do this - they just need the shared database to work in production.
