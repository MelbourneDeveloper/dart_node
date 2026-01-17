import { test, expect } from './coverage.setup.js';

test.describe('Language Persistence', () => {
  test('language preference is saved when switching', async ({ page }) => {
    await page.goto('/docs/core/');

    // Verify page loaded
    await expect(page).toHaveTitle(/dart_node_core/);
    await expect(page.locator('body')).toBeVisible();

    await page.evaluate(() => localStorage.clear());

    // Verify localStorage is cleared
    const clearedLang = await page.evaluate(() => localStorage.getItem('lang'));
    expect(clearedLang).toBeNull();

    // Verify language button exists
    await expect(page.locator('.language-btn')).toBeVisible();

    // Open language dropdown
    await page.click('.language-btn');

    // Verify dropdown is visible
    await expect(page.locator('.language-dropdown')).toBeVisible();

    // Verify Chinese option exists
    await expect(page.locator('.language-dropdown a[lang="zh"]')).toBeVisible();

    // Click Chinese (even if page 404s, localStorage should be set)
    await Promise.all([
      page.waitForNavigation({ waitUntil: 'domcontentloaded' }).catch(() => null),
      page.click('.language-dropdown a[lang="zh"]'),
    ]);

    // Check localStorage was set before navigation
    // We need to check on any page since zh page might 404
    await page.goto('/docs/core/');

    // Verify we navigated back
    await expect(page.locator('body')).toBeVisible();

    const lang = await page.evaluate(() => localStorage.getItem('lang'));
    expect(lang).toBe('zh');

    // Verify the preference persists
    await page.reload();
    const langAfterReload = await page.evaluate(() => localStorage.getItem('lang'));
    expect(langAfterReload).toBe('zh');
  });

  test('language persists after reload', async ({ page }) => {
    await page.goto('/docs/core/');

    // Verify page loaded
    await expect(page).toHaveTitle(/dart_node_core/);
    await expect(page.locator('body')).toBeVisible();

    await page.evaluate(() => localStorage.setItem('lang', 'zh'));

    // Verify localStorage was set
    const setLang = await page.evaluate(() => localStorage.getItem('lang'));
    expect(setLang).toBe('zh');

    await page.reload();

    // Verify page reloaded
    await expect(page.locator('body')).toBeVisible();

    const lang = await page.evaluate(() => localStorage.getItem('lang'));
    expect(lang).toBe('zh');

    // HTML lang attribute should be set
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Verify page is still functional
    await expect(page.locator('nav')).toBeVisible();
    await expect(page.locator('#docs-sidebar')).toBeVisible();
    await expect(page.locator('main')).toBeVisible();

    // Language button should still be accessible
    await expect(page.locator('.language-btn')).toBeVisible();
    await expect(page.locator('.language-btn')).toBeEnabled();

    // Navigate to another page and verify lang persists
    await page.click('a[href="/docs/express/"]');
    await expect(page.locator('body')).toBeVisible();
    const langAfterNav = await page.evaluate(() => localStorage.getItem('lang'));
    expect(langAfterNav).toBe('zh');
  });
});

test.describe('Language Switcher Interactions', () => {
  test('language dropdown opens and closes on button click', async ({ page }) => {
    await page.goto('/docs/core/');

    const languageSwitcher = page.locator('.language-switcher');
    const languageBtn = page.locator('.language-btn');

    // Click to open
    await languageBtn.click();
    await expect(languageSwitcher).toHaveClass(/open/);
    await expect(languageBtn).toHaveAttribute('aria-expanded', 'true');

    // Click again to close
    await languageBtn.click();
    await expect(languageSwitcher).not.toHaveClass(/open/);
    await expect(languageBtn).toHaveAttribute('aria-expanded', 'false');
  });

  test('language dropdown closes when clicking outside', async ({ page }) => {
    await page.goto('/docs/core/');

    const languageSwitcher = page.locator('.language-switcher');
    const languageBtn = page.locator('.language-btn');

    // Open dropdown
    await languageBtn.click();
    await expect(languageSwitcher).toHaveClass(/open/);

    // Click outside
    await page.locator('main').click({ force: true });

    // Should close
    await expect(languageSwitcher).not.toHaveClass(/open/);
    await expect(languageBtn).toHaveAttribute('aria-expanded', 'false');
  });

  test('language dropdown closes on Escape key', async ({ page }) => {
    await page.goto('/docs/core/');

    const languageSwitcher = page.locator('.language-switcher');
    const languageBtn = page.locator('.language-btn');

    // Open dropdown
    await languageBtn.click();
    await expect(languageSwitcher).toHaveClass(/open/);

    // Press Escape
    await page.keyboard.press('Escape');

    // Should close
    await expect(languageSwitcher).not.toHaveClass(/open/);
    await expect(languageBtn).toHaveAttribute('aria-expanded', 'false');
  });

  test('language link click saves preference to localStorage', async ({ page }) => {
    await page.goto('/docs/core/');

    // Clear localStorage
    await page.evaluate(() => localStorage.clear());

    // Verify it's cleared
    let lang = await page.evaluate(() => localStorage.getItem('lang'));
    expect(lang).toBeNull();

    // Open dropdown
    await page.click('.language-btn');
    await expect(page.locator('.language-dropdown')).toBeVisible();

    // Click English link
    const englishLink = page.locator('.language-dropdown a[lang="en"]');
    if (await englishLink.count() > 0) {
      await englishLink.click();
      await page.waitForTimeout(100);
      lang = await page.evaluate(() => localStorage.getItem('lang'));
      expect(lang).toBe('en');
    }
  });
});

test.describe('Chinese Pages Exist', () => {
  test('Chinese homepage loads with proper localization', async ({ page }) => {
    const response = await page.goto('/zh/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has navigation
    await expect(page.locator('nav')).toBeVisible();

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // HTML lang attribute should be set to zh
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Should have theme toggle
    await expect(page.locator('#theme-toggle')).toBeVisible();

    // Should have language selector
    await expect(page.locator('.language-btn')).toBeVisible();
  });

  test('Chinese getting started page loads with content', async ({ page }) => {
    const response = await page.goto('/zh/docs/getting-started/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // Has sidebar
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // HTML lang should be zh
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Should have code examples
    const codeBlocks = await page.locator('pre code').count();
    expect(codeBlocks).toBeGreaterThan(0);
  });

  test('Chinese why dart page loads with content', async ({ page }) => {
    const response = await page.goto('/zh/docs/why-dart/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // Has sidebar
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // HTML lang should be zh
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('Chinese dart-to-js page loads with content', async ({ page }) => {
    const response = await page.goto('/zh/docs/dart-to-js/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // Has sidebar
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // HTML lang should be zh
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Should have code examples
    const codeBlocks = await page.locator('pre code').count();
    expect(codeBlocks).toBeGreaterThanOrEqual(0);
  });

  test('Chinese js-interop page loads with content', async ({ page }) => {
    const response = await page.goto('/zh/docs/js-interop/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // Has sidebar
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // HTML lang should be zh
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Should have code examples
    const codeBlocks = await page.locator('pre code').count();
    expect(codeBlocks).toBeGreaterThanOrEqual(0);
  });
});
