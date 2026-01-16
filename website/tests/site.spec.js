import { test, expect } from '@playwright/test';

test.describe('Theme Persistence', () => {
  test('dark theme persists after page reload', async ({ page }) => {
    await page.goto('/docs/core/');

    // Click dark mode toggle
    await page.click('#theme-toggle');

    // Verify theme is dark
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');

    // Verify localStorage
    const theme = await page.evaluate(() => localStorage.getItem('theme'));
    expect(theme).toBe('dark');

    // Reload page
    await page.reload();

    // Theme should still be dark
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');

    // localStorage should still have dark
    const themeAfterReload = await page.evaluate(() => localStorage.getItem('theme'));
    expect(themeAfterReload).toBe('dark');
  });

  test('light theme persists after page reload', async ({ page }) => {
    // Start fresh
    await page.goto('/docs/core/');
    await page.evaluate(() => localStorage.clear());
    await page.reload();

    // Get current theme
    const initialTheme = await page.evaluate(() => document.documentElement.getAttribute('data-theme'));

    // If dark, click to make light
    if (initialTheme === 'dark') {
      await page.click('#theme-toggle');
    }

    // Verify theme is light
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');

    // Reload page
    await page.reload();

    // Theme should still be light
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  });

  test('theme toggle switches between dark and light', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.evaluate(() => localStorage.clear());
    await page.reload();

    const initialTheme = await page.evaluate(() => document.documentElement.getAttribute('data-theme'));

    // Click toggle
    await page.click('#theme-toggle');

    // Theme should be opposite
    const expectedTheme = initialTheme === 'dark' ? 'light' : 'dark';
    await expect(page.locator('html')).toHaveAttribute('data-theme', expectedTheme);

    // Click again
    await page.click('#theme-toggle');

    // Should be back to initial
    await expect(page.locator('html')).toHaveAttribute('data-theme', initialTheme);
  });
});

test.describe('Language Persistence', () => {
  test('language preference is saved when switching', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.evaluate(() => localStorage.clear());

    // Open language dropdown
    await page.click('.language-btn');

    // Click Chinese (even if page 404s, localStorage should be set)
    const [response] = await Promise.all([
      page.waitForNavigation({ waitUntil: 'domcontentloaded' }).catch(() => null),
      page.click('.language-dropdown a[lang="zh"]'),
    ]);

    // Check localStorage was set before navigation
    // We need to check on any page since zh page might 404
    await page.goto('/docs/core/');
    const lang = await page.evaluate(() => localStorage.getItem('lang'));
    expect(lang).toBe('zh');
  });

  test('language persists after reload', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.evaluate(() => localStorage.setItem('lang', 'zh'));
    await page.reload();

    const lang = await page.evaluate(() => localStorage.getItem('lang'));
    expect(lang).toBe('zh');

    // HTML lang attribute should be set
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });
});

test.describe('README to Docs Sync', () => {
  test('docs page shows README content', async ({ page }) => {
    await page.goto('/docs/core/');

    // Page should load successfully
    await expect(page).toHaveTitle(/dart_node_core/);

    // Should have Installation section (from README)
    await expect(page.locator('text=Installation')).toBeVisible();

    // Should have code blocks
    const codeBlockCount = await page.locator('pre code').count();
    expect(codeBlockCount).toBeGreaterThan(0);
  });

  test('all package docs pages load', async ({ page }) => {
    const packages = [
      'core',
      'express',
      'react',
      'react-native',
      'websockets',
      'sqlite',
      'mcp',
      'logging',
      'reflux',
      'jsx',
    ];

    for (const pkg of packages) {
      const response = await page.goto(`/docs/${pkg}/`);
      expect(response?.status()).toBe(200);
    }
  });
});

test.describe('Navigation', () => {
  test('sidebar navigation works', async ({ page }) => {
    await page.goto('/docs/core/');

    // Click on express in sidebar
    await page.click('a[href="/docs/express/"]');

    // Should navigate to express page
    await expect(page).toHaveURL(/\/docs\/express\//);
    await expect(page).toHaveTitle(/dart_node_express/);
  });

  test('header navigation works', async ({ page }) => {
    await page.goto('/');

    // Click Docs link
    await page.click('a[href="/docs/getting-started/"]');

    // Should navigate to getting started
    await expect(page).toHaveURL(/\/docs\/getting-started\//);
  });
});

test.describe('Code Blocks', () => {
  test('copy button appears on hover', async ({ page }) => {
    await page.goto('/docs/core/');

    // Find a code block wrapper
    const codeWrapper = page.locator('pre').first().locator('..');

    // Hover over it
    await codeWrapper.hover();

    // Copy button should be visible
    await expect(codeWrapper.locator('.copy-btn')).toBeVisible();
  });
});
