#!/bin/bash
# Install VSCode extension
set -e
cd "$(dirname "$0")/../too_many_cooks_vscode_extension"

VSIX=$(ls -t *.vsix 2>/dev/null | head -1)

if [ -z "$VSIX" ]; then
  echo "Error: No .vsix file found. Run build_vsix.sh first."
  exit 1
fi

code --install-extension "$VSIX" --force
echo "VSCode extension installed: $VSIX"
echo "Restart VSCode to activate."
