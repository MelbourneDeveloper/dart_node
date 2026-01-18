import { defineConfig } from '@vscode/test-cli';
import { fileURLToPath } from 'url';
import { dirname, resolve, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import { tmpdir } from 'os';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Server path: MUST use server_node.js (has node_preamble) not server.js!
const serverPath = resolve(__dirname, '../too_many_cooks/build/bin/server_node.js');

// Use short temp path for user-data to avoid IPC socket path >103 chars error
const userDataDir = join(tmpdir(), 'tmc-test');
mkdirSync(userDataDir, { recursive: true });

// Verify server exists
if (!existsSync(serverPath)) {
  console.error('ERROR: Server not found at ' + serverPath);
  console.error('Run: cd ../too_many_cooks && dart compile js -o build/bin/server.js bin/server.dart');
  console.error('Then: dart run tools/build/add_preamble.dart build/bin/server.js build/bin/server_node.js');
  process.exit(1);
}

console.log('[.vscode-test.mjs] Server path: ' + serverPath);
console.log('[.vscode-test.mjs] User data dir: ' + userDataDir);

export default defineConfig({
  files: 'out/test/suite/**/*.test.js',
  version: 'stable',
  workspaceFolder: '.',
  extensionDevelopmentPath: __dirname,
  launchArgs: [
    '--user-data-dir=' + userDataDir,
  ],
  env: {
    TMC_TEST_SERVER_PATH: serverPath,
  },
  mocha: {
    ui: 'tdd',
    timeout: 60000,
  },
});
