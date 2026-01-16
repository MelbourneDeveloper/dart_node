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

// Extend base test to collect coverage
export const test = base.extend({
  page: async ({ page }, use) => {
    // Start JS coverage with detailed reporting
    await page.coverage.startJSCoverage({ resetOnNavigation: false });

    // Use the page
    await use(page);

    // Stop coverage and collect
    const coverage = await page.coverage.stopJSCoverage();

    // Filter to only our JS files (not external libraries)
    const relevantCoverage = coverage.filter(entry =>
      entry.url.includes('/assets/js/') ||
      entry.url.includes('main.js')
    );

    // Save coverage data with functions
    const coverageFile = path.join(coverageDir, `coverage-${Date.now()}-${Math.random().toString(36).slice(2)}.json`);
    fs.writeFileSync(coverageFile, JSON.stringify(relevantCoverage, null, 2));
  },
});

export { expect };
