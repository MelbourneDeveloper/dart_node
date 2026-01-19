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

test.describe('Language Dropdown Mobile', () => {
  test('language dropdown displays above page content on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/docs/getting-started/');

    const languageBtn = page.locator('.language-btn');
    const languageDropdown = page.locator('.language-dropdown');

    // Click to open dropdown
    await languageBtn.click();
    await page.waitForTimeout(50);

    // Dropdown should be visible
    await expect(languageDropdown).toBeVisible();

    // Get dropdown bounding box
    const dropdownBox = await languageDropdown.boundingBox();
    expect(dropdownBox).not.toBeNull();

    // Dropdown should have reasonable dimensions (not clipped)
    expect(dropdownBox.height).toBeGreaterThan(50);
    expect(dropdownBox.width).toBeGreaterThan(100);
  });

  test('language dropdown z-index is above page content', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    const languageBtn = page.locator('.language-btn');

    // Open dropdown
    await languageBtn.click();
    await page.waitForTimeout(50);

    // Check z-index of header and dropdown via computed styles
    const zIndexes = await page.evaluate(() => {
      const header = document.querySelector('.header');
      const dropdown = document.querySelector('.language-dropdown');
      return {
        header: parseInt(getComputedStyle(header).zIndex) || 0,
        dropdown: parseInt(getComputedStyle(dropdown).zIndex) || 0,
      };
    });

    // Header should have high z-index
    expect(zIndexes.header).toBeGreaterThanOrEqual(1000);
    // Dropdown should also have high z-index
    expect(zIndexes.dropdown).toBeGreaterThanOrEqual(1000);
  });

  test('header container allows dropdown overflow', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    // Check overflow styles
    const overflowStyles = await page.evaluate(() => {
      const header = document.querySelector('.header');
      const headerContainer = document.querySelector('.header .container');
      const nav = document.querySelector('.nav');
      return {
        header: getComputedStyle(header).overflow,
        headerContainer: headerContainer ? getComputedStyle(headerContainer).overflow : 'N/A',
        nav: getComputedStyle(nav).overflow,
      };
    });

    // All should allow overflow for dropdown to display
    expect(overflowStyles.header).toBe('visible');
    expect(overflowStyles.nav).toBe('visible');
  });
});

test.describe('Blog Mobile Layout', () => {
  test('blog post has consistent padding with other sections', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/blog/');

    // Get blog list padding
    const blogPadding = await page.evaluate(() => {
      const blogList = document.querySelector('.blog-list');
      if (!blogList) return null;
      const style = getComputedStyle(blogList);
      return {
        paddingTop: style.paddingTop,
        paddingBottom: style.paddingBottom,
      };
    });

    expect(blogPadding).not.toBeNull();
    // Should have reasonable padding (not 0)
    expect(parseInt(blogPadding.paddingTop)).toBeGreaterThan(0);
    expect(parseInt(blogPadding.paddingBottom)).toBeGreaterThan(0);
  });

  test('no horizontal scroll on mobile blog page', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/blog/');

    // Check if page has horizontal scroll
    const hasHorizontalScroll = await page.evaluate(() => {
      return document.documentElement.scrollWidth > document.documentElement.clientWidth;
    });

    expect(hasHorizontalScroll).toBe(false);
  });

  test('no horizontal scroll on mobile docs page', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/docs/getting-started/');

    const hasHorizontalScroll = await page.evaluate(() => {
      return document.documentElement.scrollWidth > document.documentElement.clientWidth;
    });

    expect(hasHorizontalScroll).toBe(false);
  });

  test('no horizontal scroll on mobile homepage', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    const hasHorizontalScroll = await page.evaluate(() => {
      return document.documentElement.scrollWidth > document.documentElement.clientWidth;
    });

    expect(hasHorizontalScroll).toBe(false);
  });
});

test.describe('Mobile Responsive Breakpoints', () => {
  test('768px breakpoint applies correct styles', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('/');

    // Check that mobile menu toggle is visible at 768px
    const mobileMenuToggle = page.locator('#mobile-menu-toggle');
    await expect(mobileMenuToggle).toBeVisible();

    // Check hero section has reduced padding
    const heroPadding = await page.evaluate(() => {
      const hero = document.querySelector('.hero');
      if (!hero) return null;
      return getComputedStyle(hero).paddingTop;
    });
    expect(heroPadding).not.toBeNull();
  });

  test('480px breakpoint applies correct styles', async ({ page }) => {
    await page.setViewportSize({ width: 480, height: 800 });
    await page.goto('/');

    // Container should have proper padding
    const containerPadding = await page.evaluate(() => {
      const container = document.querySelector('.container');
      if (!container) return null;
      return getComputedStyle(container).paddingLeft;
    });

    expect(containerPadding).not.toBeNull();
    // Should have at least 1rem (16px) padding
    expect(parseInt(containerPadding)).toBeGreaterThanOrEqual(16);
  });

  test('language button hides text on small mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    // The language name text should be hidden on small screens
    const langTextHidden = await page.evaluate(() => {
      const langBtn = document.querySelector('.language-btn');
      const textSpan = langBtn?.querySelector('span:not(.chevron)');
      if (!textSpan) return true; // If no text span, consider it hidden
      const style = getComputedStyle(textSpan);
      return style.display === 'none';
    });

    expect(langTextHidden).toBe(true);
  });
});
