#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Install Playwright browsers if needed
npx playwright install --with-deps chromium

# Run tests
npm test
