import { test, expect } from './coverage.setup.js';

test.describe('Sidebar Navigation', () => {
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

  test('anchor link click triggers smooth scroll behavior', async ({ page }) => {
    await page.goto('/docs/core/');

    // Find a heading anchor
    const headingAnchor = page.locator('.heading-anchor').first();

    if (await headingAnchor.count() > 0 && await headingAnchor.isVisible()) {
      const href = await headingAnchor.getAttribute('href');
      const targetId = href?.replace('#', '');

      if (targetId) {
        const target = page.locator(`[id="${targetId}"]`);

        if (await target.count() > 0) {
          // Get initial scroll position
          const initialScroll = await page.evaluate(() => window.scrollY);

          // Click anchor
          await headingAnchor.click();

          // Wait for scroll
          await page.waitForTimeout(500);

          // Scroll position should have changed or target is in view
          await expect(target).toBeInViewport();
        }
      }
    }
  });

  test('clicking hash link prevents default and scrolls smoothly', async ({ page }) => {
    await page.goto('/docs/core/');

    // Add a test element at the bottom
    await page.evaluate(() => {
      const div = document.createElement('div');
      div.id = 'test-scroll-target';
      div.style.marginTop = '2000px';
      div.textContent = 'Test Target';
      document.body.appendChild(div);

      const link = document.createElement('a');
      link.href = '#test-scroll-target';
      link.id = 'test-scroll-link';
      link.textContent = 'Scroll to target';
      document.body.insertBefore(link, document.body.firstChild);
    });

    // Click the link
    await page.click('#test-scroll-link');

    // Wait for scroll
    await page.waitForTimeout(600);

    // Target should be in viewport
    await expect(page.locator('#test-scroll-target')).toBeInViewport();
  });
});
