#!/bin/bash
# Uninstall VSCode extension
set -e

code --uninstall-extension christianfindlay.too-many-cooks 2>/dev/null || true
echo "VSCode extension uninstalled."
