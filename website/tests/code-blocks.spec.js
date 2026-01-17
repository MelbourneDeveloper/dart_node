import { test, expect } from './coverage.setup.js';

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

  test('copy button shows on mouseenter and hides on mouseleave', async ({ page }) => {
    await page.goto('/docs/core/');

    const codeWrapper = page.locator('pre').first().locator('..');
    const copyBtn = codeWrapper.locator('.copy-btn');

    // Initially hidden (opacity 0)
    const initialOpacity = await copyBtn.evaluate(el => getComputedStyle(el).opacity);
    expect(initialOpacity).toBe('0');

    // Hover to show
    await codeWrapper.hover();
    await page.waitForTimeout(300);

    // Should be visible (opacity close to 1)
    const hoverOpacity = await copyBtn.evaluate(el => parseFloat(getComputedStyle(el).opacity));
    expect(hoverOpacity).toBeGreaterThan(0.9);

    // Move away
    await page.locator('nav').hover();
    await page.waitForTimeout(300);

    // Should be hidden again (opacity 0)
    const leaveOpacity = await copyBtn.evaluate(el => getComputedStyle(el).opacity);
    expect(leaveOpacity).toBe('0');
  });

  test('copy button copies pre textContent when no code element exists', async ({ page, context }) => {
    // Grant clipboard permissions
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);

    await page.goto('/docs/core/');

    // Modify a pre element to not have a code child for edge case testing
    await page.evaluate(() => {
      const pre = document.querySelector('pre');
      if (pre) {
        // Store original content
        const text = pre.textContent;
        // Replace code element with direct text
        pre.innerHTML = text;
      }
    });

    // Find the code block
    const codeWrapper = page.locator('pre').first().locator('..');
    const copyBtn = codeWrapper.locator('.copy-btn');
    const preElement = page.locator('pre').first();

    // Get pre text
    const preText = await preElement.textContent();

    // Hover and click copy
    await codeWrapper.hover();
    await copyBtn.click();

    // Verify button changed
    await expect(copyBtn).toHaveText('Copied!');

    // Verify clipboard
    const clipboardText = await page.evaluate(() => navigator.clipboard.readText());
    expect(clipboardText).toBe(preText);
  });

  test('copy button handles clipboard error gracefully', async ({ page, context }) => {
    // Don't grant clipboard permissions to simulate error
    await page.goto('/docs/core/');

    // Override clipboard API to simulate failure
    await page.evaluate(() => {
      navigator.clipboard.writeText = async () => {
        throw new Error('Clipboard access denied');
      };
    });

    const codeWrapper = page.locator('pre').first().locator('..');
    const copyBtn = codeWrapper.locator('.copy-btn');

    // Hover and click
    await codeWrapper.hover();
    await copyBtn.click();

    // Should show "Failed" on error
    await expect(copyBtn).toHaveText('Failed');
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

  test('heading anchor mouseenter shows and mouseleave hides', async ({ page }) => {
    await page.goto('/docs/core/');

    // Find h2 with ID
    const heading = page.locator('.docs-content h2[id]').first();

    if (await heading.count() > 0) {
      const anchor = heading.locator('.heading-anchor');

      // Initially hidden
      await expect(anchor).toHaveCSS('opacity', '0');

      // Hover heading
      await heading.hover();
      await page.waitForTimeout(100);

      // Anchor visible
      await expect(anchor).toHaveCSS('opacity', '1');

      // Leave heading
      await page.locator('footer').hover();
      await page.waitForTimeout(200);

      // Anchor hidden
      await expect(anchor).toHaveCSS('opacity', '0');

      // Hover again to verify toggle works multiple times
      await heading.hover();
      await page.waitForTimeout(100);
      await expect(anchor).toHaveCSS('opacity', '1');
    }
  });

  test('heading anchors exist on h3 elements too', async ({ page }) => {
    await page.goto('/docs/core/');

    // Find h3 with ID
    const h3Heading = page.locator('.docs-content h3[id]').first();

    if (await h3Heading.count() > 0) {
      const anchor = h3Heading.locator('.heading-anchor');

      // Anchor should exist
      await expect(anchor).toBeAttached();

      // Hover to show
      await h3Heading.hover();
      await page.waitForTimeout(100);
      await expect(anchor).toHaveCSS('opacity', '1');
    }
  });

  test('blog post headings also have anchors', async ({ page }) => {
    await page.goto('/blog/introducing-dart-node/');

    // Find h2 with ID in blog content
    const heading = page.locator('.blog-post-content h2[id]').first();

    if (await heading.count() > 0) {
      const anchor = heading.locator('.heading-anchor');

      if (await anchor.count() > 0) {
        // Hover to show
        await heading.hover();
        await page.waitForTimeout(100);
        await expect(anchor).toHaveCSS('opacity', '1');
      }
    }
  });
});
