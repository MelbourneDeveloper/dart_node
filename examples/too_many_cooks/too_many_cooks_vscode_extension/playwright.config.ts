import { defineConfig } from '@playwright/test';

// Empty config to prevent Playwright Test for VSCode from
// trying to discover tests in this folder.
// This project uses @vscode/test-cli with Mocha, not Playwright.
export default defineConfig({
  testDir: './playwright-tests-do-not-exist',
  testMatch: /^$/, // Match nothing
});
