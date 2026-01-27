---
name: setup-playwright
description: Install Chromium and Playwright for website E2E testing
disable-model-invocation: true
allowed-tools: Bash
---

# Install Chromium & Playwright

Sets up Playwright with Chromium for running the website's E2E test suite.

## Steps

1. **Install website npm dependencies** (includes `@playwright/test`):
   ```bash
   cd website && npm ci
   ```

2. **Install Chromium browser and OS dependencies**:
   ```bash
   cd website && npx playwright install --with-deps chromium
   ```
   This installs the Chromium binary plus required system libraries (libgbm, libasound, etc.).

3. **Verify installation**:
   ```bash
   cd website && npx playwright --version
   ```

## Notes

- Only Chromium is needed — this project does not test against Firefox or WebKit.
- On the Dev Container (Ubuntu 24.04), `--with-deps` installs the OS packages automatically.
- On macOS, Playwright downloads its own Chromium binary — no Homebrew needed.
- Browser cache lives at `~/.cache/ms-playwright/`. Delete this to force a clean reinstall.
- The website tests are at `website/tests/` and configured in `website/playwright.config.js`.
- Base URL: `http://localhost:8080` (Eleventy dev server).

## After installing

Run the website tests:
```bash
cd website && npm test
```

Or with UI mode:
```bash
cd website && npm run test:ui
```
