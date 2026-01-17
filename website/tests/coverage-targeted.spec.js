/**
 * Targeted tests specifically designed to hit uncovered code paths.
 * These tests focus on ensuring event handlers execute within V8 coverage tracking.
 */
import { test, expect } from './coverage.setup.js';

test.describe('Event Handler Coverage', () => {
  test('theme toggle click handler executes', async ({ page }) => {
    await page.goto('/docs/core/', { waitUntil: 'load' });
    await page.waitForSelector('#theme-toggle', { state: 'visible', timeout: 10000 });

    // Get initial theme
    const initialTheme = await page.evaluate(() =>
      document.documentElement.getAttribute('data-theme')
    );

    // Click theme toggle - this should execute lines 33-34
    await page.click('#theme-toggle');
    await page.waitForTimeout(100);

    // Verify the click handler ran by checking theme changed
    const newTheme = await page.evaluate(() =>
      document.documentElement.getAttribute('data-theme')
    );

    expect(newTheme).not.toBe(initialTheme);
    expect(['light', 'dark']).toContain(newTheme);
  });

  test('language button click opens dropdown', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // Click language button - lines 52-54
    await page.click('.language-btn');

    // Verify dropdown opened
    await expect(page.locator('.language-switcher')).toHaveClass(/open/);
    const expanded = await page.locator('.language-btn').getAttribute('aria-expanded');
    expect(expanded).toBe('true');
  });

  test('language link click saves preference', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // Clear lang preference
    await page.evaluate(() => localStorage.removeItem('lang'));

    // Open dropdown
    await page.click('.language-btn');
    await expect(page.locator('.language-dropdown')).toBeVisible();

    // Click a language link - lines 61-62
    // This test targets the language link click handler
    const enLink = page.locator('.language-dropdown a[lang="en"]');
    if (await enLink.count() > 0) {
      // Clicking the en link won't navigate away (same page)
      await enLink.click();
      await page.waitForTimeout(100);

      const langSaved = await page.evaluate(() => localStorage.getItem('lang'));
      expect(langSaved).toBe('en');
    }
  });

  test('language link click zh saves preference', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // Clear lang preference
    await page.evaluate(() => localStorage.removeItem('lang'));

    // Open dropdown
    await page.click('.language-btn');
    await expect(page.locator('.language-dropdown')).toBeVisible();

    // Click zh link - this tests lines 61-62 with a different lang value
    const zhLink = page.locator('.language-dropdown a[lang="zh"]');
    if (await zhLink.count() > 0) {
      // We need to prevent navigation to keep coverage
      await page.evaluate(() => {
        const link = document.querySelector('.language-dropdown a[lang="zh"]');
        if (link) {
          // Temporarily prevent navigation by modifying the link
          link.addEventListener('click', (e) => e.preventDefault(), { once: true, capture: true });
        }
      });

      await zhLink.click();
      await page.waitForTimeout(100);

      const langSaved = await page.evaluate(() => localStorage.getItem('lang'));
      expect(langSaved).toBe('zh');
    }
  });

  test('click outside closes language dropdown', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // Open dropdown
    await page.click('.language-btn');
    await expect(page.locator('.language-switcher')).toHaveClass(/open/);

    // Click outside - lines 69-72
    await page.evaluate(() => {
      document.body.click();
    });

    // Wait a moment for handler to process
    await page.waitForTimeout(100);

    // Dropdown should close
    await expect(page.locator('.language-switcher')).not.toHaveClass(/open/);
  });

  test('escape key closes language dropdown', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // Open dropdown
    await page.click('.language-btn');
    await expect(page.locator('.language-switcher')).toHaveClass(/open/);

    // Press escape - lines 77-80
    await page.keyboard.press('Escape');
    await page.waitForTimeout(100);

    // Dropdown should close
    await expect(page.locator('.language-switcher')).not.toHaveClass(/open/);
  });

  test('mobile menu toggle click', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    const toggle = page.locator('#mobile-menu-toggle');
    const navLinks = page.locator('.nav-links');

    // Click toggle - lines 90-91
    await toggle.click();
    await page.waitForTimeout(100);

    // Verify it opened
    await expect(navLinks).toHaveClass(/open/);
    await expect(toggle).toHaveClass(/active/);

    // Click again to close
    await toggle.click();
    await page.waitForTimeout(100);

    await expect(navLinks).not.toHaveClass(/open/);
  });

  test('click outside closes mobile menu', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    const toggle = page.locator('#mobile-menu-toggle');
    const navLinks = page.locator('.nav-links');

    // Open menu
    await toggle.click();
    await expect(navLinks).toHaveClass(/open/);

    // Click outside - lines 96-99
    await page.evaluate(() => {
      const main = document.querySelector('main');
      if (main) main.click();
    });
    await page.waitForTimeout(100);

    // Should close
    await expect(navLinks).not.toHaveClass(/open/);
  });

  test('sidebar toggle click', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    const toggle = page.locator('.sidebar-toggle');
    const sidebar = page.locator('#docs-sidebar');

    // Click toggle - lines 137-138
    await toggle.click();
    await page.waitForTimeout(100);

    await expect(sidebar).toHaveClass(/open/);
    await expect(toggle).toHaveText('Close');

    // Close it
    await toggle.click();
    await page.waitForTimeout(100);

    await expect(sidebar).not.toHaveClass(/open/);
    await expect(toggle).toHaveText('Menu');
  });

  test('anchor link smooth scroll', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // The smooth scroll handler is on lines 143-151
    // It attaches to all `a[href^="#"]` anchors at page load
    // We need to find and click an existing anchor that points to a visible target

    // First, scroll to top
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.waitForTimeout(100);

    // Find an anchor that links to an existing element
    const scrollResult = await page.evaluate(() => {
      // Find all hash links
      const anchors = document.querySelectorAll('a[href^="#"]');
      for (const anchor of anchors) {
        const href = anchor.getAttribute('href');
        if (!href || href === '#') continue;

        const targetId = href.substring(1);
        const target = document.getElementById(targetId);

        if (target) {
          // Found a valid anchor-target pair
          // The click handler calls e.preventDefault() and target.scrollIntoView
          anchor.click();
          return { clicked: true, targetId };
        }
      }
      return { clicked: false };
    });

    if (scrollResult.clicked) {
      // Wait for smooth scroll
      await page.waitForTimeout(800);

      // Verify the target is now in viewport
      const inViewport = await page.evaluate((id) => {
        const target = document.getElementById(id);
        if (!target) return false;
        const rect = target.getBoundingClientRect();
        return rect.top >= -100 && rect.top < window.innerHeight;
      }, scrollResult.targetId);

      expect(inViewport).toBe(true);
    }
  });

  test('code block mouseenter shows copy button', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // Find the wrapper around the first pre element
    const wrapper = page.locator('pre').first().locator('..');

    // Hover over the wrapper - triggers lines 179-181
    await wrapper.hover();
    await page.waitForTimeout(300);

    // Copy button should be visible
    const opacity = await page.locator('.copy-btn').first().evaluate(el => {
      return parseFloat(getComputedStyle(el).opacity);
    });

    expect(opacity).toBeGreaterThan(0.8);
  });

  test('code block mouseleave hides copy button', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    const wrapper = page.locator('pre').first().locator('..');

    // First hover to show - lines 179-181
    await wrapper.hover();
    await page.waitForTimeout(300);

    // Now hover away (on nav) - triggers lines 183-185
    await page.locator('nav').hover();
    await page.waitForTimeout(300);

    const opacity = await page.locator('.copy-btn').first().evaluate(el => {
      return parseFloat(getComputedStyle(el).opacity);
    });

    expect(opacity).toBeLessThan(0.2);
  });

  test('copy button click copies code', async ({ page, context }) => {
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // Get code text
    const codeText = await page.evaluate(() => {
      const code = document.querySelector('pre code');
      return code ? code.textContent : '';
    });

    // Click copy button - lines 187-199
    await page.evaluate(() => {
      const wrapper = document.querySelector('pre')?.parentElement;
      if (wrapper) {
        wrapper.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
      }
    });

    await page.waitForTimeout(100);

    const copyBtn = page.locator('.copy-btn').first();
    await copyBtn.click();

    // Wait for async clipboard operation
    await page.waitForTimeout(100);

    // Button should say Copied!
    await expect(copyBtn).toHaveText('Copied!');

    // Clipboard should have code
    const clipboard = await page.evaluate(() => navigator.clipboard.readText());
    expect(clipboard).toBe(codeText);

    // Wait for reset (2000ms in code + buffer)
    await page.waitForTimeout(2500);
    await expect(copyBtn).toHaveText('Copy', { timeout: 1000 });
  });

  test('copy button shows Failed on error', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // Override clipboard to fail - lines 197-198
    await page.evaluate(() => {
      navigator.clipboard.writeText = async () => {
        throw new Error('Denied');
      };
    });

    await page.evaluate(() => {
      const wrapper = document.querySelector('pre')?.parentElement;
      if (wrapper) {
        wrapper.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
      }
    });

    await page.waitForTimeout(100);

    const copyBtn = page.locator('.copy-btn').first();
    await copyBtn.click();

    await page.waitForTimeout(100);

    await expect(copyBtn).toHaveText('Failed');
  });

  test('heading anchor mouseenter/leave', async ({ page }) => {
    await page.goto('/docs/core/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // Find a heading with an anchor
    const heading = page.locator('.docs-content h2[id], .doc-content h2[id]').first();
    const anchor = heading.locator('.heading-anchor');

    if (await heading.count() === 0 || await anchor.count() === 0) {
      // No headings with anchors - test passes
      return;
    }

    // Lines 221-223 - hover should show anchor
    await heading.hover();
    await page.waitForTimeout(300);

    let opacity = await anchor.evaluate(el => parseFloat(getComputedStyle(el).opacity));
    expect(opacity).toBeGreaterThan(0.8);

    // Lines 225-227 - leave should hide anchor
    await page.locator('nav').hover();
    await page.waitForTimeout(300);

    opacity = await anchor.evaluate(el => parseFloat(getComputedStyle(el).opacity));
    expect(opacity).toBeLessThan(0.2);
  });
});
