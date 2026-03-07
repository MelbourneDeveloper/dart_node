# Convert Too Many Cooks VSCode Extension from Dart to TypeScript

## Context

The VSCode extension at `examples/too_many_cooks/too_many_cooks_vscode_extension` is written in Dart, compiled to JS via `dart2js`, then wrapped with a bridging script. This creates massive complexity: JS interop boilerplate, `Reflect.get`/`Reflect.set` hacks, `.toJS`/`.toDart` marshalling everywhere, and a fragile build pipeline. Converting to native TypeScript eliminates all of this. The server stays Dart -- only the VSIX client is converted.

## Target File Structure

```
src/
  extension.ts                    # activate/deactivate entry point
  state/
    types.ts                      # AgentIdentity, FileLock, Message, AgentPlan, AppState, actions
    store.ts                      # EventEmitter-based store + reducer
    selectors.ts                  # Derived state (activeLocks, expiredLocks, agentDetails)
  services/
    storeManager.ts               # HTTP client, server spawn, polling, MCP session
  ui/
    statusBar.ts                  # StatusBarManager
    tree/
      treeItems.ts                # AgentTreeItem, LockTreeItem, MessageTreeItem subclasses
      agentsTreeProvider.ts       # TreeDataProvider for agents
      locksTreeProvider.ts        # TreeDataProvider for locks
      messagesTreeProvider.ts     # TreeDataProvider for messages
    webview/
      dashboardPanel.ts           # HTML dashboard webview
  testApi.ts                      # TestAPI interface + factory
test/
  suite/
    index.ts                      # Mocha test runner
    testHelpers.ts                # waitForActivation, waitForConnection, dialog stubs
    *.test.ts                     # Converted test files
```

## Implementation Steps

### Step 1: Scaffold the TypeScript project

- Create `tsconfig.json` (target ES2022, module commonjs, strict, outDir out)
- Update `package.json`:
  - Keep entire `contributes` section unchanged
  - Replace scripts: `compile` -> `tsc -p ./`, `watch` -> `tsc -watch -p ./`
  - Add devDeps: `typescript`, `@types/vscode`, `@types/node`, `@types/mocha`, `eslint`, `@typescript-eslint/*`
  - Remove Dart-specific scripts (wrap, generate-test-manifest)
- Create `.eslintrc.json`
- Run `npm install`

### Step 2: Convert state types (`src/state/types.ts`)

Convert from `lib/state/state.dart` (404 lines).

- Dart typedef records -> TypeScript interfaces: `AgentIdentity`, `FileLock`, `Message`, `AgentPlan`, `AppState`
- `ConnectionStatus` enum -> `type ConnectionStatus = 'disconnected' | 'connecting' | 'connected'`
- 15 Dart action classes -> discriminated union: `type AppAction = { type: 'SetAgents'; agents: AgentIdentity[] } | ...`
- Move all string/number literals to named constants

### Step 3: Convert store + reducer (`src/state/store.ts`)

Replace Reflux with ~30 lines:

```typescript
class Store {
  private state: AppState;
  private listeners: Set<() => void>;
  dispatch(action: AppAction): void { ... }
  subscribe(listener: () => void): () => void { ... }
}
```

- Port `appReducer` switch expression directly
- Each case returns new `AppState` with spread + override

### Step 4: Convert selectors (`src/state/selectors.ts`)

From the selectors in `lib/state/state.dart`:

- `selectActiveLocks(state)` - filter by `expiresAt > Date.now()`
- `selectExpiredLocks(state)` - filter by `expiresAt <= Date.now()`
- `selectUnreadMessageCount(state)` - filter by `readAt === null`
- `selectAgentDetails(state)` - join agents with their locks, plans, messages

### Step 5: Convert StoreManager (`src/services/storeManager.ts`)

From `lib/state/store.dart` (702 lines). The most complex conversion:

- **Server spawning**: `import { spawn } from 'child_process'` directly (no JS interop)
- **HTTP client**: Native `fetch()` (Node 18+) -- remove all `.toJS`/`.toDart` marshalling
- **Polling**: `setInterval` replaces `Timer.periodic`
- **Env vars**: `{ ...process.env, TMC_WORKSPACE: folder }` replaces `Object.assign` interop
- **MCP session**: Same JSON-RPC protocol, just native objects
- **[HTTP STREAMABLE TRANSPORT](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports#streamable-http) parsing**: Port `_parseMcpResponse` carefully (handles both JSON and [HTTP STREAMABLE TRANSPORT](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports#streamable-http) responses)
- **Error handling**: Return discriminated unions or throw typed errors (no nadz Result)

### Step 6: Convert StatusBarManager (`src/ui/statusBar.ts`)

From `lib/ui/status_bar/status_bar_manager.dart` (78 lines). Direct translation using native `vscode.StatusBarItem`.

### Step 7: Convert tree item classes (`src/ui/tree/treeItems.ts`)

Replace `Reflect.get`/`Reflect.set` hacks with proper subclasses:

```typescript
class AgentTreeItem extends vscode.TreeItem {
  constructor(
    label: string,
    collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly agentName?: string,
    public readonly filePath?: string,
  ) {
    super(label, collapsibleState);
  }
}
```

### Step 8: Convert tree providers

In order of complexity:

1. **messagesTreeProvider.ts** (174 lines) - flat list, simplest
2. **locksTreeProvider.ts** (206 lines) - two categories (active/expired)
3. **agentsTreeProvider.ts** (271 lines) - nested tree with locks/messages/plans per agent

Each implements `vscode.TreeDataProvider<T>`, subscribes to store, fires `onDidChangeTreeData`.

### Step 9: Convert dashboard panel (`src/ui/webview/dashboardPanel.ts`)

From `lib/ui/webview/dashboard_panel.dart` (358 lines). The HTML template is already HTML/JS -- just change Dart string interpolation `${}` to JS template literals. Singleton pattern stays the same.

### Step 10: Create TestAPI (`src/testApi.ts`)

Define `TestAPI` interface with all the methods from `_TestAPIImpl` in extension.dart. No marshalling needed -- just return native objects.

### Step 11: Convert extension entry point (`src/extension.ts`)

From `lib/extension.dart` (919 lines). This shrinks dramatically:

- Standard `export function activate(context)` / `export function deactivate()`
- Register 7 commands with native `vscode.commands.registerCommand`
- Create StoreManager, tree providers, status bar
- Auto-connect logic
- Return TestAPI

### Step 12: Convert tests

- Create `test/suite/index.ts` (Mocha runner for `@vscode/test-electron`)
- Convert `test_helpers.dart` -> `testHelpers.ts` (dialog mocking via sinon stubs instead of global queue hack)
- Convert each `*_test.dart` -> `*.test.ts` using Mocha `suite`/`test`

### Step 13: Cleanup

- Delete `lib/` (all Dart source files)
- Delete `scripts/wrap-extension.js`, `wrap-tests.js`, `generate-test-manifest.js`
- Delete `pubspec.yaml`, `analysis_options.yaml`, `dart_test.yaml`
- Delete `playwright.config.ts` (unless needed)
- Keep `media/icons/`, `package.json`, `README.md`, `LICENSE`

## Key Simplifications

| Dart Complexity | TypeScript |
|---|---|
| `@JS()` annotations + external declarations | Direct `vscode.*` API calls |
| `Reflect.get`/`Reflect.set` property hacks | Native class properties |
| `.toJS`/`.toDart` on every value | Direct value passing |
| `_createJSObject()` via `eval('({})')` | `{}` |
| `wrap-extension.js` bridging | Standard `export function` |
| `node_preamble` for dart2js | Not needed |
| Reflux store | 30-line EventEmitter store |
| nadz Result types | TypeScript unions or throw |

## Critical Files to Reference During Conversion

| Dart Source | Lines | TypeScript Target |
|---|---|---|
| `lib/extension.dart` | 919 | `src/extension.ts` + `src/testApi.ts` |
| `lib/state/state.dart` | 404 | `src/state/types.ts` + `src/state/selectors.ts` |
| `lib/state/store.dart` | 702 | `src/state/store.ts` + `src/services/storeManager.ts` |
| `lib/state/log.dart` + variants | ~50 | Eliminated (use `console.log` or `OutputChannel`) |
| `lib/ui/status_bar/status_bar_manager.dart` | 78 | `src/ui/statusBar.ts` |
| `lib/ui/tree/agents_tree_provider.dart` | 271 | `src/ui/tree/agentsTreeProvider.ts` |
| `lib/ui/tree/locks_tree_provider.dart` | 206 | `src/ui/tree/locksTreeProvider.ts` |
| `lib/ui/tree/messages_tree_provider.dart` | 174 | `src/ui/tree/messagesTreeProvider.ts` |
| `lib/ui/webview/dashboard_panel.dart` | 358 | `src/ui/webview/dashboardPanel.ts` |

## Verification

1. `npm run compile` -- no TypeScript errors
2. `npm run lint` -- no ESLint errors
3. Launch extension in Extension Development Host -- verify:
   - Activity bar icon appears
   - Connect command spawns server and connects
   - Tree views populate with agents/locks/messages
   - Status bar shows connection status and counts
   - Dashboard webview renders
   - Delete lock, delete agent, send message commands work
4. `npm run test` -- all integration tests pass
5. `npx vsce package` -- produces valid .vsix
