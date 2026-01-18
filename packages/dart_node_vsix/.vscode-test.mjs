import { defineConfig } from '@vscode/test-cli';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { mkdirSync } from 'fs';
import { tmpdir } from 'os';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Use short temp path for user-data to avoid IPC socket path >103 chars error
const userDataDir = join(tmpdir(), 'vsix-test');
mkdirSync(userDataDir, { recursive: true });

console.log('[.vscode-test.mjs] User data dir: ' + userDataDir);

export default defineConfig({
  files: 'out/test/suite/**/*.test.js',
  version: 'stable',
  workspaceFolder: '.',
  extensionDevelopmentPath: __dirname,
  launchArgs: [
    '--user-data-dir=' + userDataDir,
  ],
  mocha: {
    ui: 'tdd',
    timeout: 60000,
  },
});
