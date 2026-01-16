import { test, expect } from './coverage.setup.js';

test.describe('Mobile Menu', () => {
  test('mobile menu toggle opens and closes menu', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });

    await page.goto('/');

    const mobileMenuToggle = page.locator('#mobile-menu-toggle');
    const navLinks = page.locator('.nav-links');

    // Ensure toggle is visible on mobile
    await expect(mobileMenuToggle).toBeVisible();

    // Click to open - explicitly wait for the callback to execute
    await mobileMenuToggle.click();
    await page.waitForTimeout(50);

    // Verify the click handler executed (lines 90-91 of main.js)
    await expect(navLinks).toHaveClass(/open/);
    await expect(mobileMenuToggle).toHaveClass(/active/);

    // Click to close
    await mobileMenuToggle.click();
    await page.waitForTimeout(50);
    await expect(navLinks).not.toHaveClass(/open/);
    await expect(mobileMenuToggle).not.toHaveClass(/active/);
  });

  test('mobile menu toggle callback adds classes correctly', async ({ page }) => {
    // This test specifically targets lines 89-92 of main.js
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    // Verify elements exist
    const toggleExists = await page.evaluate(() => !!document.getElementById('mobile-menu-toggle'));
    const navLinksExists = await page.evaluate(() => !!document.querySelector('.nav-links'));

    expect(toggleExists).toBe(true);
    expect(navLinksExists).toBe(true);

    // Get initial state
    const initialState = await page.evaluate(() => ({
      navLinksOpen: document.querySelector('.nav-links')?.classList.contains('open') ?? false,
      toggleActive: document.getElementById('mobile-menu-toggle')?.classList.contains('active') ?? false,
    }));

    // Click toggle
    await page.click('#mobile-menu-toggle');
    await page.waitForTimeout(100);

    // Verify state changed
    const afterClick = await page.evaluate(() => ({
      navLinksOpen: document.querySelector('.nav-links')?.classList.contains('open') ?? false,
      toggleActive: document.getElementById('mobile-menu-toggle')?.classList.contains('active') ?? false,
    }));

    expect(afterClick.navLinksOpen).toBe(!initialState.navLinksOpen);
    expect(afterClick.toggleActive).toBe(!initialState.toggleActive);
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

  test('mobile menu toggle button exists on mobile homepage', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    const mobileMenuToggle = page.locator('#mobile-menu-toggle');

    // Toggle should be visible on mobile
    await expect(mobileMenuToggle).toBeVisible();

    // Click to open
    await mobileMenuToggle.click();

    // Nav links should be open
    const navLinks = page.locator('.nav-links');
    await expect(navLinks).toHaveClass(/open/);
    await expect(mobileMenuToggle).toHaveClass(/active/);

    // Click again to close
    await mobileMenuToggle.click();
    await expect(navLinks).not.toHaveClass(/open/);
    await expect(mobileMenuToggle).not.toHaveClass(/active/);
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

  test('sidebar toggle text changes based on state', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/docs/core/');

    const sidebarToggle = page.locator('.sidebar-toggle');
    const sidebar = page.locator('#docs-sidebar');

    // Initial state should show "Menu"
    await expect(sidebarToggle).toHaveText('Menu');

    // Open sidebar
    await sidebarToggle.click();
    await expect(sidebar).toHaveClass(/open/);
    await expect(sidebarToggle).toHaveText('Close');

    // Close sidebar
    await sidebarToggle.click();
    await expect(sidebar).not.toHaveClass(/open/);
    await expect(sidebarToggle).toHaveText('Menu');

    // Reopen to verify toggle works multiple times
    await sidebarToggle.click();
    await expect(sidebarToggle).toHaveText('Close');
  });

  test('sidebar toggle on multiple pages', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });

    // Test on core page
    await page.goto('/docs/core/');
    let sidebarToggle = page.locator('.sidebar-toggle');
    await expect(sidebarToggle).toBeVisible();
    await expect(sidebarToggle).toHaveText('Menu');

    // Test on express page
    await page.goto('/docs/express/');
    sidebarToggle = page.locator('.sidebar-toggle');
    await expect(sidebarToggle).toBeVisible();
    await expect(sidebarToggle).toHaveText('Menu');

    // Open and verify
    await sidebarToggle.click();
    await expect(sidebarToggle).toHaveText('Close');
  });
});
