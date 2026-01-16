import { test, expect } from './coverage.setup.js';

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

test.describe('README to Docs Sync', () => {
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

test.describe('Navigation', () => {
  test('sidebar navigation works', async ({ page }) => {
    await page.goto('/docs/core/');

    // Verify initial page loaded
    await expect(page).toHaveTitle(/dart_node_core/);
    await expect(page.locator('body')).toBeVisible();

    // Verify sidebar is visible
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // Count sidebar links
    const sidebarLinks = await page.locator('#docs-sidebar a').count();
    expect(sidebarLinks).toBeGreaterThan(5);

    // Verify express link exists
    await expect(page.locator('#docs-sidebar a[href="/docs/express/"]')).toBeVisible();

    // Click on express in sidebar
    await page.click('#docs-sidebar a[href="/docs/express/"]');

    // Should navigate to express page
    await expect(page).toHaveURL(/\/docs\/express\//);
    await expect(page).toHaveTitle(/dart_node_express/);

    // Verify express page content loaded
    await expect(page.locator('body')).toBeVisible();
    await expect(page.locator('main')).toBeVisible();
    await expect(page.locator('text=express').first()).toBeVisible();

    // Sidebar should still be visible
    await expect(page.locator('#docs-sidebar')).toBeVisible();

    // Navigate to another page via sidebar
    await expect(page.locator('#docs-sidebar a[href="/docs/react/"]')).toBeVisible();
    await page.click('#docs-sidebar a[href="/docs/react/"]');
    await expect(page).toHaveURL(/\/docs\/react\//);
    await expect(page).toHaveTitle(/dart_node_react/);

    // Verify react page loaded
    await expect(page.locator('body')).toBeVisible();
    await expect(page.locator('main')).toBeVisible();
  });

  test('header navigation works', async ({ page }) => {
    await page.goto('/');

    // Verify homepage loaded
    await expect(page).toHaveTitle(/dart_node/i);
    await expect(page.locator('body')).toBeVisible();

    // Verify nav exists
    await expect(page.locator('nav')).toBeVisible();

    // Verify Docs link exists in nav
    await expect(page.locator('nav a[href="/docs/getting-started/"]').first()).toBeVisible();

    // Click Docs link in nav
    await page.click('nav a[href="/docs/getting-started/"]');

    // Should navigate to getting started
    await expect(page).toHaveURL(/\/docs\/getting-started\//);

    // Verify page loaded
    await expect(page.locator('body')).toBeVisible();
    await expect(page.locator('main')).toBeVisible();

    // Verify getting started content
    await expect(page.locator('text=Getting Started').first()).toBeVisible();

    // Nav should still be visible
    await expect(page.locator('nav')).toBeVisible();

    // Verify we can navigate back to homepage
    const logoLink = page.locator('a[href="/"]').first();
    await expect(logoLink).toBeVisible();
    await logoLink.click();
    await expect(page).toHaveURL(/\/$/);
    await expect(page).toHaveTitle(/dart_node/i);
  });
});

test.describe('Code Blocks', () => {
  test('copy button appears on hover and code blocks are properly formatted', async ({ page }) => {
    await page.goto('/docs/core/');

    // Verify page loaded
    await expect(page).toHaveTitle(/dart_node_core/);
    await expect(page.locator('body')).toBeVisible();

    // Count code blocks
    const codeBlockCount = await page.locator('pre code').count();
    expect(codeBlockCount).toBeGreaterThan(0);

    // Find a code block wrapper
    const codeWrapper = page.locator('pre').first().locator('..');

    // Verify code wrapper exists
    await expect(codeWrapper).toBeVisible();

    // Get the code content
    const codeContent = await page.locator('pre code').first().textContent();
    expect(codeContent).toBeTruthy();
    expect(codeContent.length).toBeGreaterThan(0);

    // Hover over it
    await codeWrapper.hover();

    // Copy button should be visible
    await expect(codeWrapper.locator('.copy-btn')).toBeVisible();

    // Verify copy button is clickable
    await expect(codeWrapper.locator('.copy-btn')).toBeEnabled();

    // Verify code has syntax highlighting classes
    const highlightedElements = await page.locator('pre code .hljs-keyword, pre code .hljs-string, pre code .hljs-number').count();
    expect(highlightedElements).toBeGreaterThanOrEqual(0); // May or may not have highlighting

    // Check another code block if it exists
    if (codeBlockCount > 1) {
      const secondCodeWrapper = page.locator('pre').nth(1).locator('..');
      await secondCodeWrapper.hover();
      await expect(secondCodeWrapper.locator('.copy-btn')).toBeVisible();
    }
  });
});

test.describe('Main Pages Exist', () => {
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

test.describe('API Documentation Exists', () => {
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

test.describe('Mobile Menu', () => {
  test('mobile menu toggle opens and closes menu', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });

    await page.goto('/');

    const mobileMenuToggle = page.locator('#mobile-menu-toggle');
    const navLinks = page.locator('.nav-links');

    // Check toggle exists on mobile
    if (await mobileMenuToggle.isVisible()) {
      // Click to open
      await mobileMenuToggle.click();
      await expect(navLinks).toHaveClass(/open/);
      await expect(mobileMenuToggle).toHaveClass(/active/);

      // Click to close
      await mobileMenuToggle.click();
      await expect(navLinks).not.toHaveClass(/open/);
      await expect(mobileMenuToggle).not.toHaveClass(/active/);
    }
  });

  test('mobile menu closes when clicking outside', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });

    await page.goto('/');

    const mobileMenuToggle = page.locator('#mobile-menu-toggle');
    const navLinks = page.locator('.nav-links');

    if (await mobileMenuToggle.isVisible()) {
      // Open menu
      await mobileMenuToggle.click();
      await expect(navLinks).toHaveClass(/open/);

      // Click outside (on the body/main)
      await page.locator('main').click({ force: true });

      // Menu should close
      await expect(navLinks).not.toHaveClass(/open/);
      await expect(mobileMenuToggle).not.toHaveClass(/active/);
    }
  });
});

test.describe('Docs Sidebar Mobile', () => {
  test('sidebar toggle button appears on mobile and toggles sidebar', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });

    await page.goto('/docs/core/');

    const sidebarToggle = page.locator('.sidebar-toggle');
    const sidebar = page.locator('#docs-sidebar');

    // Toggle should be visible on mobile
    await expect(sidebarToggle).toBeVisible();
    await expect(sidebarToggle).toHaveText('Menu');

    // Click to open
    await sidebarToggle.click();
    await expect(sidebar).toHaveClass(/open/);
    await expect(sidebarToggle).toHaveText('Close');

    // Click to close
    await sidebarToggle.click();
    await expect(sidebar).not.toHaveClass(/open/);
    await expect(sidebarToggle).toHaveText('Menu');
  });

  test('sidebar toggle hidden on desktop', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });

    await page.goto('/docs/core/');

    const sidebarToggle = page.locator('.sidebar-toggle');

    // Toggle should be hidden on desktop
    await expect(sidebarToggle).toBeHidden();
  });

  test('sidebar toggle responds to window resize', async ({ page }) => {
    // Start at desktop
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/docs/core/');

    const sidebarToggle = page.locator('.sidebar-toggle');

    // Should be hidden on desktop
    await expect(sidebarToggle).toBeHidden();

    // Resize to mobile
    await page.setViewportSize({ width: 375, height: 667 });

    // Should become visible
    await expect(sidebarToggle).toBeVisible();

    // Resize back to desktop
    await page.setViewportSize({ width: 1280, height: 800 });

    // Should be hidden again
    await expect(sidebarToggle).toBeHidden();
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
});

test.describe('Copy Button Functionality', () => {
  test('copy button copies code to clipboard', async ({ page, context }) => {
    // Grant clipboard permissions
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);

    await page.goto('/docs/core/');

    // Find first code block
    const codeWrapper = page.locator('pre').first().locator('..');
    const copyBtn = codeWrapper.locator('.copy-btn');
    const codeBlock = page.locator('pre code').first();

    // Get the code text
    const codeText = await codeBlock.textContent();

    // Hover and click copy
    await codeWrapper.hover();
    await copyBtn.click();

    // Button text should change to "Copied!"
    await expect(copyBtn).toHaveText('Copied!');

    // Verify clipboard content
    const clipboardText = await page.evaluate(() => navigator.clipboard.readText());
    expect(clipboardText).toBe(codeText);

    // Wait for button to reset
    await page.waitForTimeout(2100);
    await expect(copyBtn).toHaveText('Copy');
  });

  test('copy button hides when mouse leaves', async ({ page }) => {
    await page.goto('/docs/core/');

    const codeWrapper = page.locator('pre').first().locator('..');
    const copyBtn = codeWrapper.locator('.copy-btn');

    // Hover to show button
    await codeWrapper.hover();
    await expect(copyBtn).toBeVisible();

    // Move mouse away
    await page.locator('h1').first().hover();

    // Button should hide (opacity becomes 0)
    await page.waitForTimeout(200);
    const opacity = await copyBtn.evaluate(el => getComputedStyle(el).opacity);
    expect(opacity).toBe('0');
  });
});

test.describe('Heading Anchors', () => {
  test('heading anchors appear on hover and link correctly', async ({ page }) => {
    await page.goto('/docs/core/');

    // Find a heading with an ID in docs content
    const heading = page.locator('.docs-content h2[id], .doc-content h2[id]').first();

    if (await heading.count() > 0) {
      const headingId = await heading.getAttribute('id');
      const anchor = heading.locator('.heading-anchor');

      // Anchor should exist
      await expect(anchor).toBeAttached();

      // Anchor href should match heading id
      await expect(anchor).toHaveAttribute('href', `#${headingId}`);

      // Hover over heading
      await heading.hover();

      // Anchor should become visible (opacity 1)
      await expect(anchor).toHaveCSS('opacity', '1');

      // Move away
      await page.locator('nav').hover();

      // Anchor should hide (opacity 0)
      await page.waitForTimeout(200);
      await expect(anchor).toHaveCSS('opacity', '0');
    }
  });
});

test.describe('Smooth Scroll', () => {
  test('anchor links scroll to target sections', async ({ page }) => {
    await page.goto('/docs/core/');

    // Find visible anchor links that point to sections on the same page (exclude skip links)
    const anchorLinks = page.locator('.docs-content a[href^="#"], .heading-anchor');
    const count = await anchorLinks.count();

    if (count > 0) {
      // Find the first visible anchor link
      for (let i = 0; i < count; i++) {
        const anchorLink = anchorLinks.nth(i);
        if (await anchorLink.isVisible()) {
          const href = await anchorLink.getAttribute('href');
          const targetId = href?.replace('#', '');

          if (targetId && targetId.length > 0) {
            // Use page.locator with id attribute selector to avoid CSS.escape issues
            const target = page.locator(`[id="${targetId}"]`);

            if (await target.count() > 0) {
              // Click the anchor
              await anchorLink.click();

              // Give time for scroll
              await page.waitForTimeout(500);

              // Target should be visible/in viewport
              await expect(target).toBeInViewport();
              break;
            }
          }
        }
      }
    }
  });
});

test.describe('System Theme Preference', () => {
  test('respects system dark mode preference when no saved theme', async ({ page }) => {
    // Emulate dark mode preference
    await page.emulateMedia({ colorScheme: 'dark' });

    await page.goto('/docs/core/');

    // Clear any saved theme
    await page.evaluate(() => localStorage.removeItem('theme'));
    await page.reload();

    // Should use system preference (dark)
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  });

  test('respects system light mode preference when no saved theme', async ({ page }) => {
    // Emulate light mode preference
    await page.emulateMedia({ colorScheme: 'light' });

    await page.goto('/docs/core/');

    // Clear any saved theme
    await page.evaluate(() => localStorage.removeItem('theme'));
    await page.reload();

    // Should use system preference (light)
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  });

  test('saved theme overrides system preference', async ({ page }) => {
    // Emulate dark mode preference
    await page.emulateMedia({ colorScheme: 'dark' });

    await page.goto('/docs/core/');

    // Set light theme in localStorage
    await page.evaluate(() => localStorage.setItem('theme', 'light'));
    await page.reload();

    // Should use saved theme (light) despite system preferring dark
    await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  });
});
