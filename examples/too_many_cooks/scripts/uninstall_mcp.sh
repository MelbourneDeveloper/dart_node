#!/bin/bash
# Uninstall MCP server from Claude Code
set -e

claude mcp remove too-many-cooks 2>/dev/null || true
echo "MCP uninstalled from Claude Code."
