import { defineConfig } from '@vscode/test-cli';

export default defineConfig({
  files: 'out/test/**/*.test.js',
  workspaceFolder: './test-fixtures',
  launchArgs: [
    '--disable-workspace-trust',
    '--disable-gpu',
    '--no-sandbox',
  ],
  mocha: {
    ui: 'tdd',
    timeout: 30000,
    color: true,
    bail: true,
  },
});
