import { test as base, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const coverageDir = path.join(__dirname, '..', 'coverage');

// Ensure coverage directory exists
if (!fs.existsSync(coverageDir)) {
  fs.mkdirSync(coverageDir, { recursive: true });
}

// Extend base test to collect V8 coverage
export const test = base.extend({
  page: async ({ page }, use) => {
    // Start V8 JS coverage
    await page.coverage.startJSCoverage({
      resetOnNavigation: false,
      reportAnonymousScripts: true,
    });

    // Use the page for the test
    await use(page);

    // Stop coverage and collect results
    const coverage = await page.coverage.stopJSCoverage();

    // Filter to only include our main.js file
    const relevantCoverage = coverage.filter(entry =>
      entry.url.includes('/assets/js/') || entry.url.includes('main.js')
    );

    // Save V8 coverage data to a unique file
    if (relevantCoverage.length > 0) {
      const coverageFile = path.join(
        coverageDir,
        `coverage-${Date.now()}-${Math.random().toString(36).slice(2)}.json`
      );
      fs.writeFileSync(coverageFile, JSON.stringify(relevantCoverage, null, 2));
    }
  },
});

export { expect };
