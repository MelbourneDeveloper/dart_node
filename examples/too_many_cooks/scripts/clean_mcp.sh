#!/bin/bash
# Clean MCP server build artifacts
set -e
cd "$(dirname "$0")/.."

rm -rf too_many_cooks/build
echo "MCP build cleaned."
