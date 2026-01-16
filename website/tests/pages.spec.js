import { test, expect } from './coverage.setup.js';

test.describe('Homepage', () => {
  test('homepage loads with all essential elements', async ({ page }) => {
    const response = await page.goto('/');

    // HTTP status check
    expect(response?.status()).toBe(200);

    // Title check
    await expect(page).toHaveTitle(/dart_node/i);

    // Body visible
    await expect(page.locator('body')).toBeVisible();

    // Navigation present
    await expect(page.locator('nav')).toBeVisible();

    // Hero section or main content
    await expect(page.locator('main')).toBeVisible();

    // Has links to documentation
    const docsLinks = await page.locator('a[href*="/docs/"]').count();
    expect(docsLinks).toBeGreaterThan(0);

    // Has GitHub link
    await expect(page.locator('a[href*="github.com"]').first()).toBeVisible();

    // Theme toggle exists
    await expect(page.locator('#theme-toggle')).toBeVisible();

    // Language button exists
    await expect(page.locator('.language-btn')).toBeVisible();

    // Footer exists
    await expect(page.locator('footer')).toBeVisible();
  });
});

test.describe('Docs Pages', () => {
  test('getting started page loads with content', async ({ page }) => {
    const response = await page.goto('/docs/getting-started/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has title
    await expect(page).toHaveTitle(/Getting Started/i);

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // Has sidebar
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // Has code examples
    const codeBlocks = await page.locator('pre code').count();
    expect(codeBlocks).toBeGreaterThan(0);

    // Has headings
    const headings = await page.locator('h1, h2, h3').count();
    expect(headings).toBeGreaterThan(0);
  });

  test('why dart page loads with content', async ({ page }) => {
    const response = await page.goto('/docs/why-dart/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // Has sidebar
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // Contains Dart-related content
    await expect(page.locator('text=Dart').first()).toBeVisible();
  });

  test('dart-to-js page loads with content', async ({ page }) => {
    const response = await page.goto('/docs/dart-to-js/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // Has sidebar
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // Contains JS-related content
    const jsText = await page.locator('text=JavaScript').count();
    const dart2jsText = await page.locator('text=dart2js').count();
    expect(jsText + dart2jsText).toBeGreaterThan(0);
  });

  test('js-interop page loads with content', async ({ page }) => {
    const response = await page.goto('/docs/js-interop/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // Has sidebar
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // Has code examples
    const codeBlocks = await page.locator('pre code').count();
    expect(codeBlocks).toBeGreaterThan(0);

    // Contains interop-related content
    await expect(page.locator('text=interop').first()).toBeVisible();
  });

  test('docs page shows README content', async ({ page }) => {
    await page.goto('/docs/core/');

    // Page should load successfully
    await expect(page).toHaveTitle(/dart_node_core/);
    await expect(page.locator('body')).toBeVisible();

    // Should have main content area
    await expect(page.locator('main')).toBeVisible();
    await expect(page.locator('.docs-content')).toBeVisible();

    // Should have Installation section (from README)
    await expect(page.locator('text=Installation').first()).toBeVisible();

    // Should have code blocks
    const codeBlockCount = await page.locator('pre code').count();
    expect(codeBlockCount).toBeGreaterThan(0);

    // Verify code blocks contain Dart syntax
    const firstCodeBlock = await page.locator('pre code').first().textContent();
    expect(firstCodeBlock).toBeTruthy();
    expect(firstCodeBlock.length).toBeGreaterThan(10);

    // Should have proper headings structure
    const h1Count = await page.locator('h1').count();
    expect(h1Count).toBeGreaterThanOrEqual(1);

    const h2Count = await page.locator('h2').count();
    expect(h2Count).toBeGreaterThan(0);

    // Should have navigation sidebar
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // Should have package-specific content
    await expect(page.locator('text=dart_node_core').first()).toBeVisible();

    // Should have links to source code
    const githubLinks = await page.locator('a[href*="github.com"]').count();
    expect(githubLinks).toBeGreaterThan(0);
  });

  test('all package docs pages load with proper content', async ({ page }) => {
    const packages = [
      { slug: 'core', title: 'dart_node_core' },
      { slug: 'express', title: 'dart_node_express' },
      { slug: 'react', title: 'dart_node_react' },
      { slug: 'react-native', title: 'dart_node_react_native' },
      { slug: 'websockets', title: 'dart_node_ws' },
      { slug: 'sqlite', title: 'dart_node_better_sqlite3' },
      { slug: 'mcp', title: 'dart_node_mcp' },
      { slug: 'logging', title: 'dart_logging' },
      { slug: 'reflux', title: 'reflux' },
      { slug: 'jsx', title: 'dart_jsx' },
    ];

    for (const pkg of packages) {
      const response = await page.goto(`/docs/${pkg.slug}/`);

      // Verify HTTP status
      expect(response?.status()).toBe(200);

      // Verify page loaded
      await expect(page.locator('body')).toBeVisible();

      // Verify title contains package name
      await expect(page).toHaveTitle(new RegExp(pkg.title, 'i'));

      // Verify main content area exists
      await expect(page.locator('main')).toBeVisible();

      // Verify has code blocks
      const codeBlockCount = await page.locator('pre code').count();
      expect(codeBlockCount).toBeGreaterThan(0);

      // Verify navigation is present
      await expect(page.locator('#docs-sidebar')).toBeVisible();
      await expect(page.locator('nav')).toBeVisible();
    }
  });
});

test.describe('Blog Pages', () => {
  test('blog page loads with posts', async ({ page }) => {
    const response = await page.goto('/blog/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // Has navigation
    await expect(page.locator('nav')).toBeVisible();

    // Has blog posts (links to posts)
    const postLinks = await page.locator('a[href*="/blog/"]').count();
    expect(postLinks).toBeGreaterThan(0);

    // Has title
    await expect(page).toHaveTitle(/Blog/i);
  });

  test('blog post loads with full content', async ({ page }) => {
    const response = await page.goto('/blog/introducing-dart-node/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has main content
    await expect(page.locator('main')).toBeVisible();

    // Has article content
    await expect(page.locator('article')).toBeVisible();

    // Has headings
    const headings = await page.locator('h1, h2, h3').count();
    expect(headings).toBeGreaterThan(0);

    // Has text content
    const textContent = await page.locator('main').textContent();
    expect(textContent.length).toBeGreaterThan(100);

    // Has navigation back to blog
    await expect(page.locator('a[href="/blog/"]').first()).toBeVisible();
  });
});

test.describe('XML Feeds', () => {
  test('sitemap exists with valid XML', async ({ page }) => {
    const response = await page.goto('/sitemap.xml');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Verify content type is XML
    const contentType = response?.headers()['content-type'];
    expect(contentType).toContain('xml');

    // Get the XML content
    const content = await page.content();

    // Should contain sitemap structure
    expect(content).toContain('urlset');
    expect(content).toContain('<url>');
    expect(content).toContain('<loc>');

    // Should contain site URLs
    expect(content).toContain('/docs/');
  });

  test('RSS feed exists with valid XML', async ({ page }) => {
    const response = await page.goto('/feed.xml');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Verify content type is XML
    const contentType = response?.headers()['content-type'];
    expect(contentType).toContain('xml');

    // Get the XML content
    const content = await page.content();

    // Should contain RSS/Atom structure
    const hasRss = content.includes('<rss') || content.includes('<feed');
    expect(hasRss).toBe(true);

    // Should contain items/entries
    const hasItems = content.includes('<item>') || content.includes('<entry>');
    expect(hasItems).toBe(true);
  });
});

test.describe('API Documentation', () => {
  test('dart_node_core API docs load with proper structure', async ({ page }) => {
    const response = await page.goto('/api/dart_node_core/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has navigation or sidebar
    const hasNav = await page.locator('nav, .sidebar, .nav').count();
    expect(hasNav).toBeGreaterThan(0);

    // Has main content area
    await expect(page.locator('main, .main, #main')).toBeVisible();

    // Contains API-related content
    const pageContent = await page.content();
    expect(pageContent.toLowerCase()).toContain('dart_node_core');
  });

  test('dart_node_express API docs load with proper structure', async ({ page }) => {
    const response = await page.goto('/api/dart_node_express/');

    // HTTP status
    expect(response?.status()).toBe(200);

    // Page loaded
    await expect(page.locator('body')).toBeVisible();

    // Has navigation or sidebar
    const hasNav = await page.locator('nav, .sidebar, .nav').count();
    expect(hasNav).toBeGreaterThan(0);

    // Has main content area
    await expect(page.locator('main, .main, #main')).toBeVisible();

    // Contains API-related content
    const pageContent = await page.content();
    expect(pageContent.toLowerCase()).toContain('dart_node_express');
  });
});
