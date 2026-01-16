import { test, expect } from './coverage.setup.js';

/**
 * Tests to verify that clicking any link on Chinese pages stays in Chinese.
 * All internal links on /zh/* pages should navigate to /zh/* URLs.
 * These tests will FAIL if links incorrectly point to English pages.
 */

test.describe('Chinese Page Navigation - Links Must Stay in Chinese', () => {
  test('clicking API card on Chinese API index stays in Chinese', async ({ page }) => {
    // Navigate to Chinese API page
    const response = await page.goto('/zh/api/');
    expect(response?.status()).toBe(200);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Click on dart_node_core card
    const coreCard = page.locator('a[href*="dart_node_core"]').first();
    await expect(coreCard).toBeVisible();
    await coreCard.click();

    // MUST stay on Chinese page - URL should contain /zh/
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('clicking dart_node_express card on Chinese API index stays in Chinese', async ({ page }) => {
    const response = await page.goto('/zh/api/');
    expect(response?.status()).toBe(200);

    const card = page.locator('a[href*="dart_node_express"]').first();
    await expect(card).toBeVisible();
    await card.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('clicking dart_node_react card on Chinese API index stays in Chinese', async ({ page }) => {
    const response = await page.goto('/zh/api/');
    expect(response?.status()).toBe(200);

    const card = page.locator('a[href*="dart_node_react"][href$="dart_node_react/"]').first();
    await expect(card).toBeVisible();
    await card.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('clicking dart_node_react_native card on Chinese API index stays in Chinese', async ({ page }) => {
    const response = await page.goto('/zh/api/');
    expect(response?.status()).toBe(200);

    const card = page.locator('a[href*="dart_node_react_native"]').first();
    await expect(card).toBeVisible();
    await card.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('clicking dart_node_ws card on Chinese API index stays in Chinese', async ({ page }) => {
    const response = await page.goto('/zh/api/');
    expect(response?.status()).toBe(200);

    const card = page.locator('a[href*="dart_node_ws"]').first();
    await expect(card).toBeVisible();
    await card.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('clicking dart_node_better_sqlite3 card on Chinese API index stays in Chinese', async ({ page }) => {
    const response = await page.goto('/zh/api/');
    expect(response?.status()).toBe(200);

    const card = page.locator('a[href*="dart_node_better_sqlite3"]').first();
    await expect(card).toBeVisible();
    await card.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('clicking dart_node_mcp card on Chinese API index stays in Chinese', async ({ page }) => {
    const response = await page.goto('/zh/api/');
    expect(response?.status()).toBe(200);

    const card = page.locator('a[href*="dart_node_mcp"]').first();
    await expect(card).toBeVisible();
    await card.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('clicking dart_logging card on Chinese API index stays in Chinese', async ({ page }) => {
    const response = await page.goto('/zh/api/');
    expect(response?.status()).toBe(200);

    const card = page.locator('a[href*="dart_logging"]').first();
    await expect(card).toBeVisible();
    await card.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('clicking reflux card on Chinese API index stays in Chinese', async ({ page }) => {
    const response = await page.goto('/zh/api/');
    expect(response?.status()).toBe(200);

    const card = page.locator('a[href*="reflux"]').first();
    await expect(card).toBeVisible();
    await card.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });
});

test.describe('Chinese Header Navigation - Must Link to Chinese Pages', () => {
  test('Docs link in Chinese header navigates to Chinese docs', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Click the Docs link in header nav
    const docsLink = page.locator('nav.nav a[href*="docs"]').first();
    await expect(docsLink).toBeVisible();
    await docsLink.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('API link in Chinese header navigates to Chinese API', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Click the API link in header nav
    const apiLink = page.locator('nav.nav a[href*="api"]').first();
    await expect(apiLink).toBeVisible();
    await apiLink.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });

  test('Blog link in Chinese header navigates to Chinese blog', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Click the Blog link in header nav
    const blogLink = page.locator('nav.nav a[href*="blog"]').first();
    await expect(blogLink).toBeVisible();
    await blogLink.click();

    // MUST stay on Chinese page
    await expect(page).toHaveURL(/\/zh\//);
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
  });
});

test.describe('Chinese Footer Navigation - Must Link to Chinese Pages', () => {
  test('footer docs links on Chinese page navigate to Chinese docs', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Find footer links to docs
    const footerDocsLinks = page.locator('footer a[href*="docs"]');
    const count = await footerDocsLinks.count();

    for (let i = 0; i < count; i++) {
      const link = footerDocsLinks.nth(i);
      const href = await link.getAttribute('href');

      // All docs links in footer should point to /zh/docs/
      if (href && !href.startsWith('http')) {
        expect(href).toMatch(/^\/zh\//);
      }
    }
  });

  test('footer API link on Chinese page navigates to Chinese API', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Find footer API link
    const footerApiLink = page.locator('footer a[href*="api"]').first();
    if (await footerApiLink.count() > 0) {
      const href = await footerApiLink.getAttribute('href');

      // API link in footer should point to /zh/api/
      if (href && !href.startsWith('http')) {
        expect(href).toMatch(/^\/zh\//);
      }
    }
  });

  test('footer blog link on Chinese page navigates to Chinese blog', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Find footer blog link
    const footerBlogLink = page.locator('footer a[href*="blog"]').first();
    if (await footerBlogLink.count() > 0) {
      const href = await footerBlogLink.getAttribute('href');

      // Blog link in footer should point to /zh/blog/
      if (href && !href.startsWith('http')) {
        expect(href).toMatch(/^\/zh\//);
      }
    }
  });
});

test.describe('Chinese Sidebar Navigation - Must Link to Chinese Pages', () => {
  test('sidebar links on Chinese docs page navigate to Chinese docs', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // Get all sidebar links
    const sidebarLinks = page.locator('#docs-sidebar a');
    const count = await sidebarLinks.count();

    for (let i = 0; i < count; i++) {
      const link = sidebarLinks.nth(i);
      const href = await link.getAttribute('href');

      // All sidebar links should point to /zh/docs/
      if (href && !href.startsWith('http') && !href.startsWith('#')) {
        expect(href).toMatch(/^\/zh\//);
      }
    }
  });

  test('clicking sidebar dart_node_core link stays in Chinese', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    const coreLink = page.locator('#docs-sidebar a[href*="core"]').first();
    if (await coreLink.count() > 0) {
      await coreLink.click();

      // MUST stay on Chinese page
      await expect(page).toHaveURL(/\/zh\//);
      await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
    }
  });

  test('clicking sidebar dart_node_express link stays in Chinese', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    const expressLink = page.locator('#docs-sidebar a[href*="express"]').first();
    if (await expressLink.count() > 0) {
      await expressLink.click();

      // MUST stay on Chinese page
      await expect(page).toHaveURL(/\/zh\//);
      await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
    }
  });

  test('clicking sidebar react link stays in Chinese', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Use exact match for react (not react-native)
    const reactLink = page.locator('#docs-sidebar a[href$="/react/"]').first();
    if (await reactLink.count() > 0) {
      await reactLink.click();

      // MUST stay on Chinese page
      await expect(page).toHaveURL(/\/zh\//);
      await expect(page.locator('html')).toHaveAttribute('lang', 'zh');
    }
  });
});

test.describe('All Links on Chinese Pages Must Use /zh/ Prefix', () => {
  test('all internal links on Chinese API page use /zh/ prefix', async ({ page }) => {
    await page.goto('/zh/api/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Get all internal links (not external, not anchors)
    const allLinks = page.locator('a[href^="/"]');
    const count = await allLinks.count();

    const brokenLinks = [];
    for (let i = 0; i < count; i++) {
      const link = allLinks.nth(i);
      const href = await link.getAttribute('href');

      // Skip language switcher links and external links
      const isLanguageSwitcher = await link.locator('..').evaluate(el =>
        el.closest('.language-dropdown') !== null
      );

      if (!isLanguageSwitcher && href && !href.startsWith('/zh/') && !href.startsWith('/#')) {
        brokenLinks.push(href);
      }
    }

    // This will FAIL if any links don't have /zh/ prefix
    expect(brokenLinks).toEqual([]);
  });

  test('all internal links on Chinese getting-started page use /zh/ prefix', async ({ page }) => {
    await page.goto('/zh/docs/getting-started/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Get all internal links (not external, not anchors)
    const allLinks = page.locator('a[href^="/"]');
    const count = await allLinks.count();

    const brokenLinks = [];
    for (let i = 0; i < count; i++) {
      const link = allLinks.nth(i);
      const href = await link.getAttribute('href');

      // Skip language switcher links
      const isLanguageSwitcher = await link.locator('..').evaluate(el =>
        el.closest('.language-dropdown') !== null
      );

      if (!isLanguageSwitcher && href && !href.startsWith('/zh/') && !href.startsWith('/#')) {
        brokenLinks.push(href);
      }
    }

    // This will FAIL if any links don't have /zh/ prefix
    expect(brokenLinks).toEqual([]);
  });

  test('all internal links on Chinese homepage use /zh/ prefix', async ({ page }) => {
    await page.goto('/zh/');
    await expect(page.locator('html')).toHaveAttribute('lang', 'zh');

    // Get all internal links (not external, not anchors)
    const allLinks = page.locator('a[href^="/"]');
    const count = await allLinks.count();

    const brokenLinks = [];
    for (let i = 0; i < count; i++) {
      const link = allLinks.nth(i);
      const href = await link.getAttribute('href');

      // Skip language switcher links
      const isLanguageSwitcher = await link.locator('..').evaluate(el =>
        el.closest('.language-dropdown') !== null
      );

      if (!isLanguageSwitcher && href && !href.startsWith('/zh/') && !href.startsWith('/#')) {
        brokenLinks.push(href);
      }
    }

    // This will FAIL if any links don't have /zh/ prefix
    expect(brokenLinks).toEqual([]);
  });
});
