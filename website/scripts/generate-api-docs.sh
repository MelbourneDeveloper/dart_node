#!/bin/bash

# Generate API documentation for all dart_node packages
# This wrapper script calls the Node.js processor

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBSITE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$WEBSITE_DIR"

# Ensure jsdom is available
npm list jsdom > /dev/null 2>&1 || npm install jsdom

# Run the Node.js processor
node "$SCRIPT_DIR/generate-api-docs.js"
